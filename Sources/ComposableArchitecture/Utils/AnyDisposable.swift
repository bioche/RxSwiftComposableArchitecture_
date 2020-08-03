//
//  AnyDisposable.swift
//  ComposableArchitecture
//
//  Created by Bioche on 03/08/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import RxSwift

/// Type-erased disposable that adds Hashable conformance
class AnyDisposable: Disposable, Hashable {
  let _dispose: () -> Void

  init(_ disposable: Disposable) {
    _dispose = disposable.dispose
  }

  func dispose() {
    _dispose()
  }

  static func == (lhs: AnyDisposable, rhs: AnyDisposable) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
