//
//  File.swift
//  
//
//  Created by Bioche on 09/05/2020.
//  
//

import Foundation
import RxSwift

//extension Effect {
//    public func mapError<E: Error>(_ transform: (Failure) -> E) -> Effect<Output, E> {
//      Effect<Output, E>(
//        upstream.catchError { received -> Observable<Output> in
//          guard let expected = received as? Failure else {
//            throw EffectUnexpectedError<Failure>(received)
//          }
//          throw transform(expected)
//        }
//      )
//    }
//}
//
//public struct EffectUnexpectedError<Failure: Error>: Error {
//  public let reason: Error
//
//  init(_ reason: Error) {
//    assertionFailure("Received error : \(reason), expected error of type \(Failure.self)")
//    self.reason = reason
//  }
//}

extension Observable {
  
  public func eraseToEffect<Failure: Error>() -> Effect<Element, Failure> {
    Effect(self)
  }
  
  public func eraseToEffect<Failure: Error>(failureType: Failure.Type) -> Effect<Element, Failure> {
    Effect(self)
  }
  
  /// Turns any publisher into an `Effect`.
  ///
  /// This can be useful for when you perform a chain of publisher transformations in a reducer, and
  /// you need to convert that publisher to an effect so that you can return it from the reducer:
  ///
  ///     case .buttonTapped:
  ///       return fetchUser(id: 1)
  ///         .filter(\.isAdmin)
  ///         .eraseToEffect()
  ///
  /// - Returns: An effect that wraps `self`.
//  public func eraseToEffect() -> Effect<Element, Error> {
//    eraseToEffect(failureType: Error.self)
//  }
  
//  public func eraseToEffect<Failure: Error>(mapError: (Error) -> Failure) -> Effect<Element, Failure> {
//    Effect(self.catchError { throw mapError($0) })
//  }

  /// Turns any publisher into an `Effect` that cannot fail by wrapping its output and failure in a
  /// result.
  ///
  /// This can be useful when you are working with a failing API but want to deliver its data to an
  /// action that handles both success and failure.
  ///
  ///     case .buttonTapped:
  ///       return fetchUser(id: 1)
  ///         .catchToEffect()
  ///         .map(ProfileAction.userResponse)
  ///
  /// - Returns: An effect that wraps `self`.
  public func catchToEffect<Failure: Error>(failureType: Failure.Type) -> Effect<Result<Element, Failure>, Never> {
    Effect(
      self.map(Result.success)
        // Because Rx doesn't give any guaranty on the error type,
        // We have to make sure the error is of type Failure
        // If we find this isn't the case, we raise assertion failure & complete the stream
        .catchError { received -> Observable<Result<Element, Failure>> in
          guard let expected = received as? Failure else {
            assertionFailure("Expected error of type \(Failure.self), received this \(received)")
            return .empty()
          }
          return .just(.failure(expected))
      }
    )
  }
}
