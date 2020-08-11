//
//  UIAlertController.swift
//  ComposableArchitecture
//
//  Created by Eric Blachère on 11/08/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//
#if canImport(UIKit)
#if !os(watchOS)

import UIKit
import RxSwift

extension Store where State == AlertState<Action>? {
  public func bindTo(alertPresenter: UIViewController) -> Disposable {
    var alertController: UIAlertController?
    return ifLet(then: { [weak alertPresenter] store in
      let viewStore = ViewStore(store, removeDuplicates: { _, _ in false })
      alertController = .from(viewStore: viewStore)
      alertPresenter?.present(alertController!, animated: true, completion: nil)
      }, else: { [weak alertController] in
        alertController?.dismiss(animated: true, completion: nil)
    })
  }
}

//extension UIViewController {
//  public func bindToAlertPresentation<Action>(viewStore: ViewStore<AlertState<Action>?, Action>) -> Disposable {
//    viewStore.driver
//      .drive(onNext: { [weak self] in
//        if let state = $0 {
//          self?.present(UIAlertController.from(state: state, viewStore: viewStore), animated: true, completion: nil)
//        } else {
//          self?.dismiss(animated: true, completion: nil)
//        }
//      })
//  }
//}

extension UIAlertController {
  public static func from<Action>(viewStore: ViewStore<AlertState<Action>, Action>) -> UIAlertController {
    let alertController = UIAlertController(title: viewStore.state.title, message: viewStore.state.message, preferredStyle: .alert)
    [viewStore.state.primaryButton, viewStore.state.secondaryButton]
      .compactMap { $0 }
      .map { UIAlertAction.from(state: $0, viewStore: viewStore) }
      .forEach { alertController.addAction($0) }
    return alertController
  }
}

extension UIAlertAction {
  public static func from<Action>(state: AlertState<Action>.Button, viewStore: ViewStore<AlertState<Action>, Action>) -> Self {
    switch state.type {
    case .cancel(let label?), .default(let label), .destructive(let label):
      return .init(title: label,
                   style: state.type.alertActionStyle,
                   handler: { _ in state.action.map { viewStore.send($0) } })
    case .cancel(nil):
      return .init(title: "", style: state.type.alertActionStyle, handler: { _ in  })
    }
  }
}

extension AlertState.Button.`Type` {
  var alertActionStyle: UIAlertAction.Style {
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

