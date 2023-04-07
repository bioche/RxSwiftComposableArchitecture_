//
//  Disposable+asCancellable.swift
//  ComposableArchitecture
//
//  Created by Bioche on 16/05/2021.
//  Copyright © 2021 Bioche. All rights reserved.
//

import RxSwift

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Disposable {
  
  /// Wraps this disposable inside a cancellable.
  /// Useful to easily convert Rx written utilities into Combine utilities.
  public func asCancellable() -> Cancellable {
    AnyCancellable { dispose() }
  }
}
#endif
