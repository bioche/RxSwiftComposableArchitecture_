import Foundation
#if canImport(Combine)
import Combine
import SwiftUI

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ViewStore: ObservableObject {
  /// A publisher of state.
  public var publisher: StorePublisher<State> {
    .init(observable.unfailablePublisher)
  }
  
  /// Derives a binding from the store that prevents direct writes to state and instead sends
  /// actions to the store.
  ///
  /// The method is useful for dealing with SwiftUI components that work with two-way `Binding`s
  /// since the `Store` does not allow directly writing its state; it only allows reading state and
  /// sending actions.
  ///
  /// For example, a text field binding can be created like this:
  ///
  ///     struct State { var name = "" }
  ///     enum Action { case nameChanged(String) }
  ///
  ///     TextField(
  ///       "Enter name",
  ///       text: viewStore.binding(
  ///         get: { $0.name },
  ///         send: { Action.nameChanged($0) }
  ///       )
  ///     )
  ///
  /// - Parameters:
  ///   - get: A function to get the state for the binding from the view
  ///     store's full state.
  ///   - localStateToViewAction: A function that transforms the binding's value
  ///     into an action that can be sent to the store.
  /// - Returns: A binding.
  public func binding<LocalState>(
    get: @escaping (State) -> LocalState,
    send localStateToViewAction: @escaping (LocalState) -> Action
  ) -> Binding<LocalState> {
    Binding(
      get: { get(self.state) },
      set: { newLocalState, transaction in
        withAnimation(transaction.disablesAnimations ? nil : transaction.animation) {
          self.send(localStateToViewAction(newLocalState))
        }
      })
  }

  /// Derives a binding from the store that prevents direct writes to state and instead sends
  /// actions to the store.
  ///
  /// The method is useful for dealing with SwiftUI components that work with two-way `Binding`s
  /// since the `Store` does not allow directly writing its state; it only allows reading state and
  /// sending actions.
  ///
  /// For example, an alert binding can be dealt with like this:
  ///
  ///     struct State { var alert: String? }
  ///     enum Action { case alertDismissed }
  ///
  ///     .alert(
  ///       item: self.store.binding(
  ///         get: { $0.alert },
  ///         send: .alertDismissed
  ///       )
  ///     ) { alert in Alert(title: Text(alert.message)) }
  ///
  /// - Parameters:
  ///   - get: A function to get the state for the binding from the view store's full state.
  ///   - action: The action to send when the binding is written to.
  /// - Returns: A binding.
  public func binding<LocalState>(
    get: @escaping (State) -> LocalState,
    send action: Action
  ) -> Binding<LocalState> {
    self.binding(get: get, send: { _ in action })
  }

  /// Derives a binding from the store that prevents direct writes to state and instead sends
  /// actions to the store.
  ///
  /// The method is useful for dealing with SwiftUI components that work with two-way `Binding`s
  /// since the `Store` does not allow directly writing its state; it only allows reading state and
  /// sending actions.
  ///
  /// For example, a text field binding can be created like this:
  ///
  ///     struct State { var name = "" }
  ///     enum Action { case nameChanged(String) }
  ///
  ///     TextField(
  ///       "Enter name",
  ///       text: viewStore.binding(
  ///         send: { Action.nameChanged($0) }
  ///       )
  ///     )
  ///
  /// - Parameters:
  ///   - localStateToViewAction: A function that transforms the binding's value
  ///     into an action that can be sent to the store.
  /// - Returns: A binding.
  public func binding(
    send localStateToViewAction: @escaping (State) -> Action
  ) -> Binding<State> {
    self.binding(get: { $0 }, send: localStateToViewAction)
  }

  /// Derives a binding from the store that prevents direct writes to state and instead sends
  /// actions to the store.
  ///
  /// The method is useful for dealing with SwiftUI components that work with two-way `Binding`s
  /// since the `Store` does not allow directly writing its state; it only allows reading state and
  /// sending actions.
  ///
  /// For example, an alert binding can be dealt with like this:
  ///
  ///     struct State { var alert: String? }
  ///     enum Action { case alertDismissed }
  ///
  ///     .alert(
  ///       item: self.store.binding(
  ///         send: .alertDismissed
  ///       )
  ///     ) { alert in Alert(title: Text(alert.message)) }
  ///
  /// - Parameters:
  ///   - action: The action to send when the binding is written to.
  /// - Returns: A binding.
  public func binding(send action: Action) -> Binding<State> {
    self.binding(send: { _ in action })
  }
  
  /// The call to objectWillChange can only be done in combine
  func objectWillChange() {
    objectWillChange.send()
  }
}
#else

extension ViewStore {
  /// The call to objectWillChange can only be done in combine
  func objectWillChange() {}
}

#endif
