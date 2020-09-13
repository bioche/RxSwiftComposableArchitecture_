import Foundation
import RxSwift
import RxRelay
import RxCocoa

/// A store represents the runtime that powers the application. It is the object that you will pass
/// around to views that need to interact with the application.
///
/// You will typically construct a single one of these at the root of your application, and then use
/// the `scope` method to derive more focused stores that can be passed to subviews.
public final class Store<State, Action> {
  let stateRelay: BehaviorRelay<State>
  public internal(set) var state: State {
    get {
      stateRelay.value
    }
    set {
      stateRelay.accept(newValue)
    }
  }

  var effectDisposeBags: [UUID: DisposeBag] = [:]

  private var isSending = false
  private let disposeBag = DisposeBag()
  private let reducer: (inout State, Action) -> Effect<Action, Never>
  private var synchronousActionsToSend: [Action] = []

  /// Initializes a store from an initial state, a reducer, and an environment.
  ///
  /// - Parameters:
  ///   - initialState: The state to start the application in.
  ///   - reducer: The reducer that powers the business logic of the application.
  ///   - environment: The environment of dependencies for the application.
  public convenience init<Environment>(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment
  ) {
    self.init(
      initialState: initialState,
      reducer: { reducer.run(&$0, $1, environment) }
    )
  }

  /// Scopes the store to one that exposes local state and actions.
  ///
  /// This can be useful for deriving new stores to hand to child views in an application. For
  /// example:
  ///
  ///     // Application state made from local states.
  ///     struct AppState { var login: LoginState, ... }
  ///     struct AppAction { case login(LoginAction), ... }
  ///
  ///     // A store that runs the entire application.
  ///     let store = Store(initialState: AppState(), reducer: appReducer, environment: ())
  ///
  ///     // Construct a login view by scoping the store to one that works with only login domain.
  ///     let loginView = LoginView(
  ///       store: store.scope(
  ///         state: { $0.login },
  ///         action: { AppAction.login($0) }
  ///       )
  ///     )
  ///
  /// - Parameters:
  ///   - toLocalState: A function that transforms `State` into `LocalState`.
  ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
  /// - Returns: A new store with its domain (state and action) transformed.
  public func scope<LocalState, LocalAction>(
    state toLocalState: @escaping (State) -> LocalState,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Store<LocalState, LocalAction> {
    scope(initialLocalState: toLocalState(state),
          state: toLocalState,
          action: fromLocalAction)
  }

  /// Scopes the store to one that exposes local state.
  ///
  /// - Parameter toLocalState: A function that transforms `State` into `LocalState`.
  /// - Returns: A new store with its domain (state and action) transformed.
  public func scope<LocalState>(
    state toLocalState: @escaping (State) -> LocalState
  ) -> Store<LocalState, Action> {
    scope(state: toLocalState, action: { $0 })
  }

  /// Scopes the store to a publisher of stores of more local state and local actions.
  ///
  /// - Parameters:
  ///   - toLocalState: A function that transforms a publisher of `State` into a publisher of
  ///     `LocalState`.
  ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
  /// - Returns: A publisher of stores with its domain (state and action) transformed.
  public func scope<O: ObservableType, LocalState, LocalAction>(
    state toLocalState: @escaping (Observable<State>) -> O,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Observable<Store<LocalState, LocalAction>>
  where O.Element == LocalState {

    func extractLocalState(_ state: State) -> LocalState? {
      var localState: LocalState?
      _ = toLocalState(Observable.just(state))
          .subscribe(onNext: { localState = $0 })
      return localState
    }

      return toLocalState(stateRelay.asObservable())
      .map { localState in
        let localStore = Store<LocalState, LocalAction>(
          initialState: localState,
          reducer: { (localState, localAction) -> Effect<LocalAction, Never> in
            self.send(fromLocalAction(localAction))
            localState = extractLocalState(self.state) ?? localState
            return .none
          })

        self.stateRelay
          .subscribe(onNext: { [weak localStore] state in
            guard let localStore = localStore else { return }
            localStore.state = extractLocalState(state) ?? localStore.state
          })
          .disposed(by: localStore.disposeBag)
        return localStore
      }.asObservable()
  }

  /// Scopes the store to a publisher of stores of more local state and local actions.
  ///
  /// - Parameter toLocalState: A function that transforms a publisher of `State` into a publisher
  ///   of `LocalState`.
  /// - Returns: A publisher of stores with its domain (state and action)
  ///   transformed.
  public func scope<O: ObservableType, LocalState>(
    state toLocalState: @escaping (Observable<State>) -> O
  ) -> Observable<Store<LocalState, Action>>
    where O.Element == LocalState {
      self.scope(state: toLocalState, action: { $0 })
  }

  public func send(_ action: Action) {
    self.synchronousActionsToSend.append(action)

    while !self.synchronousActionsToSend.isEmpty {
      let action = self.synchronousActionsToSend.removeFirst()

      if self.isSending {
        assertionFailure(
          """
          The store was sent the action \(debugCaseOutput(action)) while it was already
          processing another action.

          This can happen for a few reasons:

          * The store was sent an action recursively. This can occur when you run an effect \
          directly in the reducer, rather than returning it from the reducer. Check the stack (⌘7) \
          to find frames corresponding to one of your reducers. That code should be refactored to \
          not invoke the effect directly.

          * The store has been sent actions from multiple threads. The `send` method is not \
          thread-safe, and should only ever be used from a single thread (typically the main \
          thread). Instead of calling `send` from multiple threads you should use effects to \
          process expensive computations on background threads so that it can be fed back into the \
          store.
          """
        )
      }
      self.isSending = true
      let effect = self.reducer(&self.state, action)
      self.isSending = false

      var didComplete = false
      let uuid = UUID()

      var isProcessingEffects = true
      let effectDisposeBag = DisposeBag()
      effect.subscribe(
        onNext: { [weak self] action in
          if isProcessingEffects {
            self?.synchronousActionsToSend.append(action)
          } else {
            self?.send(action)
          }
        },
        onCompletion: { [weak self] _ in
          didComplete = true
          self?.effectDisposeBags[uuid] = nil
        }
      ).disposed(by: effectDisposeBag)
      isProcessingEffects = false

      if !didComplete {
        self.effectDisposeBags[uuid] = effectDisposeBag
      }
    }
  }

  /// Returns a "stateless" store by erasing state to `Void`.
  public var stateless: Store<Void, Action> {
    self.scope(state: { _ in () })
  }

  /// Returns an "actionless" store by erasing action to `Never`.
  public var actionless: Store<State, Never> {
    func absurd<A>(_ never: Never) -> A {}
    return self.scope(state: { $0 }, action: absurd)
  }

  private init(
    initialState: State,
    reducer: @escaping (inout State, Action) -> Effect<Action, Never>
  ) {
    self.reducer = reducer
    self.stateRelay = BehaviorRelay(value: initialState)
  }
}

extension Store {
  /// A version of scoping where the state may not be transformable into local state.
  /// Meant to be private for now. Could be set public if need be.
  /// (ifLet should be enough in most cases)
  func scope<LocalState, LocalAction>(
    initialLocalState: LocalState,
    state toLocalState: @escaping (State) -> LocalState?,
    action fromLocalAction: @escaping (LocalAction) -> Action
  ) -> Store<LocalState, LocalAction> {

    let localStore = Store<LocalState, LocalAction>(
      initialState: initialLocalState,
      reducer: { localState, localAction in
        self.send(fromLocalAction(localAction))
        if let newState = toLocalState(self.state) {
          localState = newState
        }
        return .none
      }
    )

    self.stateRelay
      .subscribe(onNext: { [weak localStore] newValue in
        if let newState = toLocalState(newValue) {
          localStore?.state = newState
        }
      }).disposed(by: localStore.disposeBag)
    return localStore

  }
}

extension Store: TCAIdentifiable where State: TCAIdentifiable {
  public var id: State.ID {
    ViewStore(self, removeDuplicates: {_, _ in false }).id
  }
}

/// To avoid creating ViewStores
extension Store {
  public func driver(removeDuplicates isDuplicate: @escaping (State, State) -> Bool) -> StoreDriver<State> {
    .init(stateRelay.distinctUntilChanged(isDuplicate))
  }
}

extension Store where State: Equatable {
  public func driver() -> StoreDriver<State> {
    .init(stateRelay.distinctUntilChanged())
  }
}


/// The goal of this structure is to be able to perform a subscript as a quick way of mapping & avoid duplicates. As it comes from the ViewStore, the Driver trait is the more appropriate
@dynamicMemberLookup
public struct StoreDriver<State>: SharedSequenceConvertibleType {

  public typealias Element = State

  private let upstream: Observable<State>

  public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Element == State {
    upstream.subscribe(observer)
  }

  public init<O: ObservableType>(_ observable: O) where O.Element == State {
    self.upstream = observable.asObservable()
  }

  public func asSharedSequence() -> Driver<State> {
    upstream
      .do(onError: { error in assertionFailure("An error occurred in the stream handled by a store driver : \(error)") })
      .asDriver(onErrorDriveWith: .empty())
  }

  /// Returns the resulting driver of a given key path.
  public subscript<LocalState>(
    dynamicMember keyPath: KeyPath<State, LocalState>
  ) -> StoreDriver<LocalState>
  where LocalState: Equatable {
    .init(upstream.map { $0[keyPath: keyPath] }
      .distinctUntilChanged())
  }
}
