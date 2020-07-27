//
//  Observable+onCompletion.swift
//  ComposableArchitecture
//
//  Created by Bioche on 28/06/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import RxSwift

public extension ObservableType {
  func subscribe(onNext: ((Element) -> Void)? = nil, onCompletion: ((Swift.Error?) -> Void)? = nil, onDisposed: (() -> Void)? = nil) -> Disposable {
    subscribe(onNext: onNext, onError: { onCompletion?($0) }, onCompleted: { onCompletion?(nil) }, onDisposed: onDisposed)
  }
}
