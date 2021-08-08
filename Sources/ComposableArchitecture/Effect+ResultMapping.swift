//
//  Effect+ResultMapping.swift
//  ComposableArchitecture
//
//  Created by Bioche on 23/12/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import RxSwift

/// Regroups utility methods that allow mapping of result observable (or single)
/// into action effects ready to be returned in reducers
extension ObservableConvertibleType {
  
  /// Maps result success into `action` & failure into `failureAction`
  /// producing 2 distinct actions depending on the outcome of the original call
  /// Current Observable should not fail.
  ///
  ///     return environment.dislikedFoodService
  ///       .fetch()
  ///       .splitResultToActionEffect(
  ///           action: { .fetched($0) },
  ///           failureAction: { _ in .receivedFailure(.fetchingDislikedFoods) }
  ///       )
  ///
  /// - Parameters:
  ///   - action: mapping the success value into an action
  ///   - failureAction: mapping the failure error into an action
  /// - Returns: An unfailable effect ready to be returned from the reducer
  public func splitResultToActionEffect<Value, ResultFailure, Action>(
    action: @escaping (Value) -> Action,
    failureAction: @escaping (ResultFailure) -> Action
  ) -> Effect<Action, Never> where Element == Result<Value, ResultFailure> {
    asObservable()
      .map { result in
        switch result {
        case .failure(let error):
          return failureAction(error)
        case .success(let element):
          return action(element)
        }
      }
      .eraseToEffect()
  }
  
  /// Shortcut for `mapResultToActionEffect(action:errorMapping)`
  /// where the end result error type is the same as initial error type.
  /// Current Observable should not fail.
  ///
  ///     return validate(sections: sectionsToValidate, env)
  ///       .mapResultToActionEffect(
  ///           action: { .validationCompleted(on: sectionId, $0) }
  ///       )
  ///
  /// - Parameter action: Wraps the result inside an action
  /// - Returns: An unfailable effect ready to be returned from the reducer
  public func mapResultToActionEffect<Value, Failure: Error, Action>(
    action: @escaping (Result<Value, Failure>) -> Action
  ) -> Effect<Action, Never> where Element == Result<Value, Failure> {
    mapResultToActionEffect(errorMapping: { $0 }, action: action)
  }
  
  /// Maps the result observable into an effect which actions wrap the result with a different
  /// kind of error. Current Observable should not fail.
  ///
  /// - Parameters:
  ///   - errorMapping: Maps the error of result (`InitialFailure`) into `ResultFailure`
  ///   - action: Wraps the result inside an action
  /// - Returns: An unfailable effect ready to be returned from the reducer
  public func mapResultToActionEffect<Value, InitialFailure: Error, ResultFailure: Error, Action>(
    errorMapping: @escaping (InitialFailure) -> ResultFailure,
    action: @escaping (Result<Value, ResultFailure>) -> Action
  ) -> Effect<Action, Never> where Element == Result<Value, InitialFailure> {
    asObservable()
      .map { action($0.mapError(errorMapping)) }
      .eraseToEffect()
  }
}

#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    /// Maps output into `action` & failure into `failureAction`
    /// producing 2 distinct actions depending on the outcome of the original call
    ///
    ///     return environment.dislikedFoodService
    ///       .fetch()
    ///       .splitToActionEffect(
    ///           action: { .fetched($0) },
    ///           failureAction: { _ in .receivedFailure(.fetchingDislikedFoods) }
    ///       )
    ///
    /// - Parameters:
    ///   - action: mapping the success value into an action
    ///   - failureAction: mapping the failure error into an action
    /// - Returns: An unfailable effect ready to be returned from the reducer
    public func splitToActionEffect<Action>(
      action: @escaping (Output) -> Action,
      failureAction: @escaping (Failure) -> Action
    ) -> Effect<Action, Never> {
        catchToEffect()
            .map { result in
                switch result {
                case .failure(let error):
                    return failureAction(error)
                case .success(let element):
                    return action(element)
                }
            }
    }
    
    /// Shortcut for `mapToActionEffect(errorMapping:action:)`
    /// where the end result error type is the same as initial error type.
    ///
    ///     return validate(sections: sectionsToValidate, env)
    ///       .mapToActionEffect(
    ///           action: { .validationCompleted(on: sectionId, $0) }
    ///       )
    ///
    /// - Parameter action: Wraps the result inside an action
    /// - Returns: An unfailable effect ready to be returned from the reducer
    public func mapToActionEffect<Action>(
      action: @escaping (Result<Output, Failure>) -> Action
    ) -> Effect<Action, Never> {
      mapToActionEffect(errorMapping: { $0 }, action: action)
    }
    
    /// Wraps the failure or output inside a result action.
    ///
    /// - Parameters:
    ///   - errorMapping: Maps the publisher failures into `ResultFailure`
    ///   - action: Wraps the result inside an action
    /// - Returns: An unfailable effect ready to be returned from the reducer
    public func mapToActionEffect<ResultFailure: Error, Action>(
      errorMapping: @escaping (Failure) -> ResultFailure,
      action: @escaping (Result<Output, ResultFailure>) -> Action
    ) -> Effect<Action, Never> {
        catchToEffect()
            .map { action($0.mapError(errorMapping)) }
    }
}
#endif
