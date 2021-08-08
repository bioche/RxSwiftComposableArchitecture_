#if canImport(UIKit)
#if !os(watchOS)

import UIKit

extension UIAlertAction {
  public static func from<Action>(state: AlertState<Action>.Button,
                                  sendAction: @escaping (Action) -> Void) -> Self {
    switch state.type {
    case .cancel(let label?), .default(let label), .destructive(let label):
      return .init(title: label,
                   style: state.type.alertActionStyle,
                   handler: { _ in state.action.map { sendAction($0) } })
    case .cancel(nil):
      return .init(title: "Cancel", style: state.type.alertActionStyle, handler: { _ in  })
    }
  }
}

extension AlertState.Button.`Type` {
  public var alertActionStyle: UIAlertAction.Style {
    switch self {
    case .cancel:
      return .cancel
    case .default:
      return .default
    case .destructive:
      return .destructive
    }
  }
}

#endif
#endif
