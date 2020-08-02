//
//  Reducer+utils.swift
//  ComposableArchitecture
//
//  Created by Bioche on 02/08/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

extension Reducer {
  /// Creates a reducer that will transform the specified action (`case`) into another action (`embed`).
  ///
  /// Typically, this will allow for redirection of actions from parent into a child
  /// ```
  /// parentReducer
  ///   .resending(ParentAction.fooClient, to: { ParentAction.child1(.fooClient($0)) })
  ///   .resending(ParentAction.fooClient, to: { ParentAction.child2(.fooClient($0)) })
  /// ```
  ///
  /// - Parameters:
  ///   - case: The original action
  ///   - to: The destination action
  /// - Returns: The modified reducer
  public func resending<Value>(
    _ case: @escaping (Value) -> Action,
    to embed: @escaping (Value) -> Action
  ) -> Self {
    .combine(
      self,
      .init { state, action, _ in
        if let value = CasePath.case(`case`).extract(from: action) {
          return Effect(value: embed(value))
        } else {
          return .none
        }
      }
    )
  }
}


