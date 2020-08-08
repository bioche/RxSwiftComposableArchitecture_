import Foundation
import RxSwift

extension Observable {
  
  /// Creates an effect from an observable. The Failure type is guessed at compilation. It should match errors encountered by this observable.
  /// - Returns: The effect of output type `Element` and failure type `Failure`
  public func eraseToEffect<Failure: Error>() -> Effect<Element, Failure> {
    Effect(self)
  }
  
  /// Creates an effect from an observable
  /// - Parameter failureType: The Failure type that can be encountered by this observable.
  /// - Returns: The effect of output type `Element` and failure type `failureType`
  public func eraseToEffect<Failure: Error>(failureType: Failure.Type) -> Effect<Element, Failure> {
    Effect(self)
  }

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
  /// - Parameter failureType: The type of failure that this observable can encounter.
  /// The caller is responsible for the exactness of `failureType`. If this observable fails with an error that isn't of type Failure, then an assertion will be raised or the effect will be completed in production.
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
