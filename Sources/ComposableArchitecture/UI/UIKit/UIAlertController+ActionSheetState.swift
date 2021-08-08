#if canImport(UIKit)
#if !os(watchOS)

import UIKit
import RxSwift

public enum ActionSheetUISource {
  case view(UIView)
  case barButtonItem(UIBarButtonItem)
}

extension Store where State == ActionSheetState<Action>? {
  /// Presents or dismisses alert controller depending on state.
  /// The store will receive the actions emitted when pressing alert buttons
  /// - Parameter sheetPresenter: The controller doing the presenting
  /// - Parameter sourceView: The source needed for iPad popover display
  /// - Parameter onPresent: Can be used to customize alert controller UI or its popoverViewController
  /// - Returns: Disposable to cancel the subscription to store's state
  public func bindTo(sheetPresenter: UIViewController,
                     sourceView: ActionSheetUISource,
                     onPresent: @escaping (UIAlertController) -> Void = { _ in }) -> Disposable {
    var alertController: UIAlertController?
    return ifLet(then: { [weak sheetPresenter] store in
      let viewStore = ViewStore(store, removeDuplicates: { _, _ in false })
      alertController = .from(viewStore: viewStore)
      if let presenter = alertController?.popoverPresentationController {
        switch sourceView {
        case .barButtonItem(let barButtonItem):
          presenter.barButtonItem = barButtonItem
        case .view(let sourceView):
          presenter.sourceView = sourceView
          presenter.sourceRect = sourceView.bounds
        }
      }
      onPresent(alertController!)
      sheetPresenter?.present(alertController!, animated: true, completion: nil)
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
  public static func from<Action>(viewStore: ViewStore<ActionSheetState<Action>, Action>) -> UIAlertController {
    let alertController = UIAlertController(title: viewStore.state.title, message: viewStore.state.message, preferredStyle: .actionSheet)
    viewStore.state.buttons
      .map { UIAlertAction.from(state: $0, sendAction: { viewStore.send($0) }) }
      .forEach { alertController.addAction($0) }
    return alertController
  }
}

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Store where State == ActionSheetState<Action>? {
  
  /// Presents or dismisses alert controller depending on state.
  /// The store will receive the actions emitted when pressing alert buttons
  /// - Parameter sheetPresenter: The controller doing the presenting
  /// - Parameter sourceView: The source needed for iPad popover display
  /// - Parameter onPresent: Can be used to customize alert controller UI or its popoverViewController
  /// - Returns: Cancellable to cancel the subscription to store's state
  public func bindTo(sheetPresenter: UIViewController,
                     sourceView: ActionSheetUISource,
                     onPresent: @escaping (UIAlertController) -> Void = { _ in }) -> Cancellable {
    bindTo(sheetPresenter: sheetPresenter,
           sourceView: sourceView,
           onPresent: onPresent)
      .asCancellable()
  }
}
#endif

#endif
#endif

