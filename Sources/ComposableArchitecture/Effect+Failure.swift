import Foundation
import RxSwift

fileprivate extension Observable {
    func observeOnMainThreadIfNeeded() -> Observable<Element> {
        if NSClassFromString("XCTest") != nil { // in test stay on current thread
            return self
        } else {
            return self.observe(on: MainScheduler())
        }
    }
}

extension ObservableConvertibleType {
  
  /// Creates an effect from an observable with expected failure type.
  /// `Failure` is just here as an indication to the developer. It doesn't enforce anything.
  /// Shortcut for `eraseToEffect(failureType:)` when `failureType` can be guessed at compile time
  /// - Returns: The effect of output type `Element` and failure type `Failure`
  public func eraseToEffect<Failure: Error>() -> Effect<Element, Failure> {
      Effect(asObservable().observeOnMainThreadIfNeeded())
  }
  
  /// Creates an effect from an observable with expected failure type
  /// `Failure` is just here as an indication to the developer. It doesn't enforce anything.
  /// - Parameter failureType: The Failure type that can be encountered by this observable.
  /// - Returns: The effect of output type `Element` and failure type `failureType`
  public func eraseToEffect<Failure: Error>(failureType: Failure.Type) -> Effect<Element, Failure> {
      Effect(asObservable().observeOnMainThreadIfNeeded())
  }

  /// Turns any observable into an `Effect` that cannot fail by wrapping its output and failure in a
  /// result. To be used when `failureType` is known ; otherwise use `catchToEffect(errorMapping:)`
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
  /// The caller is responsible for the exactness of `failureType`.
  /// If this observable fails with an error that isn't of type Failure,
  /// then an assertion will be raised or the effect will be completed in production.
  /// - Returns: An effect that will never fail.
  public func catchToResultEffect<Failure: Error>(
    assertedFailureType: Failure.Type
  ) -> Effect<Result<Element, Failure>, Never> {
    Effect(
      asObservable()
        .observeOnMainThreadIfNeeded()
        .map(Result.success)
        // Because Rx doesn't give any guaranty on the error type,
        // We have to make sure the error is of type Failure
        // If we find this isn't the case, we raise assertion failure & complete the stream
        .catch { received -> Observable<Result<Element, Failure>> in
          guard let expected = received as? Failure else {
            assertionFailure("Expected error of type \(Failure.self), received this \(received)")
            return .empty()
          }
          return .just(.failure(expected))
      }
    )
  }
  
  /// Catches any errors from an observable.
  /// This will map error to the wanted `Failure` using `errorMapping`
  /// - Parameter errorMapping: Maps a generic error to focused `Failure`
  /// - Returns: The effect of output type `Element` and failure type `Failure`
  public func catchToEffect<Failure: Error>(
    _ errorMapping: @escaping (Error) -> Failure
  ) -> Effect<Element, Failure> {
    asObservable()
      .catch { .error(errorMapping($0)) }
      .eraseToEffect(failureType: Failure.self)
  }
  
  /// Turns any observable into an `Effect` that cannot fail by wrapping its output and failure in a
  /// result.
  /// If the failure type of the source is known for sure, `catchToResultEffect(failureType:)`
  /// can be used
  /// - Parameter errorMapping: Maps between generic error & target `Failure`
  /// - Returns: An effect that will never fail.
  public func catchToResultEffect<Failure: Error>(
    _ errorMapping: @escaping (Error) -> Failure
  ) -> Effect<Result<Element, Failure>, Never> {
    asObservable()
      .catch { .error(errorMapping($0)) }
      .catchToResultEffect(assertedFailureType: Failure.self)
  }
  
  /// Turns any publisher into an `Effect` that cannot fail by returning predefined `action`
  /// when an error is catched
  /// - Parameter elementForError: The element to be sent when catching error
  /// - Returns: An effect that will never fail.
  public func catchToUnfailableEffect(
    _ elementForError: @escaping (Error) -> Element
  ) -> Effect<Element, Never> {
    asObservable()
      .catch { .just(elementForError($0)) }
      .eraseToEffect(failureType: Never.self)
  }
}
