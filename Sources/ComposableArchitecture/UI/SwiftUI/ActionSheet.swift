#if canImport(Combine)
import SwiftUI

@available(iOS 13, *)
@available(macCatalyst 13, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
@available(OSX 10.15, *)
@available(macOS, unavailable)
extension View {
  /// Displays an action sheet when the store's state becomes non-`nil`, and dismisses it when it
  /// becomes `nil`.
  ///
  /// - Parameters:
  ///   - store: A store that describes if the action sheet is shown or dismissed.
  ///   - dismissal: An action to send when the action sheet is dismissed through non-user actions,
  ///     such as when an action sheet is automatically dismissed by the system.
  public func actionSheet<Action>(
    _ store: Store<ActionSheetState<Action>?, Action>,
    dismiss: Action
  ) -> some View {

    let viewStore = ViewStore(store, removeDuplicates: { ($0 == nil) != ($1 == nil) })
    return self.actionSheet(
      isPresented: Binding(
        get: { viewStore.state != nil },
        set: {
          guard !$0 else { return }
          viewStore.send(dismiss)
        }),
      content: { viewStore.state?.toSwiftUI(send: viewStore.send) ?? ActionSheet(title: Text("")) }
    )
  }
}

@available(iOS 13, *)
@available(macCatalyst 13, *)
@available(OSX 10.15, *)
@available(macOS, unavailable)
@available(tvOS 13, *)
@available(watchOS 6, *)
extension ActionSheetState {
  fileprivate func toSwiftUI(send: @escaping (Action) -> Void) -> SwiftUI.ActionSheet {
    SwiftUI.ActionSheet(
      title: Text(self.title),
      message: self.message.map { Text($0) },
      buttons: self.buttons.map {
        $0.toSwiftUI(send: send)
      }
    )
  }
}
#endif
