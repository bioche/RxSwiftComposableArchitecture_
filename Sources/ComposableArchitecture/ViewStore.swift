import Combine
import SwiftUI

import RxSwift

/// A `ViewStore` is an object that can observe state changes and send actions from a SwiftUI view.
///
/// In SwiftUI applications, a `ViewStore` is accessed most commonly using the `WithViewStore` view.
/// It can be initialized with a store and a closure that is handed a view store and must return a
/// view to be rendered:
///
///     var body: some View {
///       WithViewStore(self.store) { viewStore in
///         VStack {
///           Text("Current count: \(viewStore.count)")
///           Button("Increment") { viewStore.send(.incrementButtonTapped) }
///         }
///       }
///     }
///
/// In UIKit applications a `ViewStore` can be created from a `Store` and then subscribed to for
/// state updates:
///
///     let store: Store<State, Action>
///     let viewStore: ViewStore<State, Action>
///
///     init(store: Store<State, Action>) {
///       self.store = store
///       self.viewStore = ViewStore(store)
///     }
///
///     func viewDidLoad() {
///       super.viewDidLoad()
///
///       self.viewStore.publisher.count
///         .sink { [weak self] in self?.countLabel.text = $0 }
///         .store(in: &self.cancellables)
///     }
///
///     @objc func incrementButtonTapped() {
///       self.viewStore.send(.incrementButtonTapped)
///     }
///
@dynamicMemberLookup
public final class ViewStore<State, Action> {
  /// An observable on state.
  public let observable: StoreObservable<State>

  private var viewCancellable: Disposable?

  /// Initializes a view store from a store.
  ///
  /// - Parameters:
  ///   - store: A store.
  ///   - isDuplicate: A function to determine when two `State` values are equal. When values are
  ///     equal, repeat view computations are removed.
  public init(
    _ store: Store<State, Action>,
    removeDuplicates isDuplicate: @escaping (State, State) -> Bool
  ) {
    let observable = store.stateRelay.distinctUntilChanged(isDuplicate)
    self.observable = StoreObservable(observable)
    self.state = store.state
    self._send = store.send
    self.viewCancellable = observable.subscribe(onNext: { [weak self] in self?.state = $0 })
  }

  /// The current state.
  public internal(set) var state: State {
    didSet {
      if #available(iOS 13.0, *) {
        objectWillChange.send()
      }
    }
  }

  let _send: (Action) -> Void

  /// Returns the resulting value of a given key path.
  public subscript<LocalState>(dynamicMember keyPath: KeyPath<State, LocalState>) -> LocalState {
    self.state[keyPath: keyPath]
  }

  /// Sends an action to the store.
  ///
  /// `ViewStore` is not thread safe and you should only send actions to it from the main thread.
  ///
  /// - Parameter action: An action.
  public func send(_ action: Action) {
    self._send(action)
  }
}

extension ViewStore where State: Equatable {
  public convenience init(_ store: Store<State, Action>) {
    self.init(store, removeDuplicates: ==)
  }
}
