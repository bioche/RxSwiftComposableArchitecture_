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
  var state: State {
    get {
      stateRelay.value
    }
    set {
      stateRelay.accept(newValue)
    }
  }
    
  var effectDisposables: [UUID: Disposable] = [:]
    
  private var isSending = false
  private var parentCancellable: Disposable?
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
    let localStore = Store<LocalState, LocalAction>(
      initialState: toLocalState(self.state),
      reducer: { localState, localAction in
        self.send(fromLocalAction(localAction))
        localState = toLocalState(self.state)
        return .none
      }
    )
    localStore.parentCancellable = self.stateRelay
      .subscribe(onNext: { [weak localStore] newValue in localStore?.state = toLocalState(newValue) })
    return localStore
  }

  /// Scopes the store to one that exposes local state.
  ///
  /// - Parameter toLocalState: A function that transforms `State` into `LocalState`.
  /// - Returns: A new store with its domain (state and action) transformed.
  public func scope<LocalState>(
    state toLocalState: @escaping (State) -> LocalState
  ) -> Store<LocalState, Action> {
    self.scope(state: toLocalState, action: { $0 })
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

        localStore.parentCancellable = self.stateRelay
          .subscribe(onNext: { [weak localStore] state in
            guard let localStore = localStore else { return }
            localStore.state = extractLocalState(state) ?? localStore.state
          })
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

  func send(_ action: Action) {
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
      let effectDisposable = effect.subscribe(
        onNext: { [weak self] action in
          if isProcessingEffects {
            self?.synchronousActionsToSend.append(action)
          } else {
            self?.send(action)
          }
        },
        onCompletion: { [weak self] _ in
          didComplete = true
          self?.effectDisposables[uuid] = nil
        }
      )
      isProcessingEffects = false

      if !didComplete {
        self.effectDisposables[uuid] = effectDisposable
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
  /// Gives the evolution of a  list of stores scoped down to each element of this store.
  /// This avoids reloading entire collections / tables when only a property of an element is updated.
  /// The elements must be Identifiable so that we can publish a new array when an identity has changed at a specific index.
  /// For SwiftUI, prefer the ForEachStore
  public func scopeForEach<EachState>(shouldAvoidReload: @escaping (EachState, EachState) -> Bool = { $0.id == $1.id }) -> Driver<[Store<EachState, Never>]>
    where State == [EachState], EachState: TCAIdentifiable, Action == Never {
      stateRelay
        // with this we avoid sending a new array each time a modification occurs on an element.
        // Instead we publish a new array when the count changes or an object has changed identity (ID has changed)
        .distinctUntilChanged {
          guard $0.count == $1.count else { return false }
          return zip($0, $1).allSatisfy { shouldAvoidReload($0, $1) }
        }
        // Scope an new substore for each element
        .compactMap { [weak self] state in
          guard let strongSelf = self else { return nil }
          return state.enumerated().map { index, subState in
            strongSelf.scope(state: { $0[index] })
          }
        }
        // no error possible as we come from a relay
        .asDriver(onErrorDriveWith: .never())
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
