#if canImport(UIKit)
#if !os(watchOS)

import UIKit
import RxSwift

extension Store where State == AlertState<Action>? {
  /// Presents or dismisses alert controller depending on state.
  /// The store will receive the actions emitted when pressing alert buttons
  /// - Parameter alertPresenter: The controller doing the presenting
  /// - Parameter onPresent: Can be used to customize alert controller UI
  /// - Returns: Disposable to cancel the subscription to store's state
  public func bindTo(alertPresenter: UIViewController,
                     onPresent: @escaping (UIAlertController) -> Void = { _ in }) -> Disposable {
    var alertController: UIAlertController?
    return ifLet(then: { [weak alertPresenter] store in
      let viewStore = ViewStore(store, removeDuplicates: { _, _ in false })
      alertController = .from(viewStore: viewStore)
      onPresent(alertController!)
      alertPresenter?.present(alertController!, animated: true, completion: nil)
      }, else: { [weak alertController] in
        alertController?.dismiss(animated: true, completion: nil)
    })
  }
}

extension UIAlertController {
  /// Builds alert controller from ViewStore.
  /// ViewStore will receive the actions emitted when pressing alert buttons
  /// - Parameter viewStore: ViewStore on the action sheet
  /// - Returns: The alert controller to be presented
  public static func from<Action>(viewStore: ViewStore<AlertState<Action>, Action>) -> UIAlertController {
    let alertController = UIAlertController(title: viewStore.state.title, message: viewStore.state.message, preferredStyle: .alert)
    [viewStore.state.primaryButton, viewStore.state.secondaryButton]
      .compactMap { $0 }
      .map { UIAlertAction.from(state: $0, sendAction: { viewStore.send($0) }) }
      .forEach { alertController.addAction($0) }
    return alertController
  }
}

#endif
#endif
