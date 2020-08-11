#if canImport(Combine)
import SwiftUI

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
  /// Displays an alert when then store's state becomes non-`nil`, and dismisses it when it becomes
  /// `nil`.
  ///
  /// - Parameters:
  ///   - store: A store that describes if the alert is shown or dismissed.
  ///   - dismissal: An action to send when the alert is dismissed through non-user actions, such
  ///     as when an alert is automatically dismissed by the system.
  public func alert<Action>(
    _ store: Store<AlertState<Action>?, Action>,
    dismiss: Action
  ) -> some View {

    let viewStore = ViewStore(store, removeDuplicates: { ($0 == nil) != ($1 == nil) })
    return self.alert(
      isPresented: Binding(
        get: { viewStore.state != nil },
        set: {
          guard !$0 else { return }
          viewStore.send(dismiss)
        }),
      content: { viewStore.state?.toSwiftUI(send: viewStore.send) ?? Alert(title: Text("")) }
    )
  }
}

extension AlertState: TCAIdentifiable, Identifiable where Action: Hashable {
  public var id: Self { self }
}

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension AlertState.Button {
  func toSwiftUI(send: @escaping (Action) -> Void) -> SwiftUI.Alert.Button {
    let action = { if let action = self.action { send(action) } }
    switch self.type {
    case let .cancel(.some(label)):
      return .cancel(Text(label), action: action)
    case .cancel(.none):
      return .cancel(action)
    case let .default(label):
      return .default(Text(label), action: action)
    case let .destructive(label):
      return .destructive(Text(label), action: action)
    }
  }
}

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension AlertState {
  fileprivate func toSwiftUI(send: @escaping (Action) -> Void) -> SwiftUI.Alert {
    let title = Text(self.title)
    let message = self.message.map { Text($0) }

    if let primaryButton = self.primaryButton, let secondaryButton = self.secondaryButton {
      return SwiftUI.Alert(
        title: title,
        message: message,
        primaryButton: primaryButton.toSwiftUI(send: send),
        secondaryButton: secondaryButton.toSwiftUI(send: send)
      )
    } else {
      return SwiftUI.Alert(
        title: title,
        message: message,
        dismissButton: self.primaryButton?.toSwiftUI(send: send)
      )
    }
  }
}

#else

extension AlertState: TCAIdentifiable where Action: Hashable {
  public var id: Self { self }
}

#endif
