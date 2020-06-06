import Foundation
import RxSwift
import Combine

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Effect: Publisher {
    
    /// Initializes an effect that wraps a publisher. Each emission of the wrapped publisher will be
    /// emitted by the effect.
    ///
    /// This initializer is useful for turning any publisher into an effect. For example:
    ///
    ///     Effect(
    ///       NotificationCenter.default
    ///         .publisher(for: UIApplication.userDidTakeScreenshotNotification)
    ///     )
    ///
    /// Alternatively, you can use the `.eraseToEffect()` method that is defined on the `Publisher`
    /// protocol:
    ///
    ///     NotificationCenter.default
    ///       .publisher(for: UIApplication.userDidTakeScreenshotNotification)
    ///       .eraseToEffect()
    ///
    /// - Parameter publisher: A publisher.
    public init<P: Publisher>(_ publisher: P) where P.Output == Output, P.Failure == Failure {
      self.upstream = publisher.asObservable()
    }
    
    public func receive<S>(
      subscriber: S
    ) where S: Combine.Subscriber, Failure == S.Failure, Output == S.Input {
        self.upstream.asPublisher()
            .catch { received -> AnyPublisher<Output, Failure> in
                // Because Rx doesn't give any guaranty on the error type,
                // We have to make sure the error of the Publisher is of type Failure
                // If we find this isn't the case, we raise assertion failure & complete the stream
                guard let expected = received as? Failure else {
                    assertionFailure("Expected error of type \(Failure.self), received this : \(received)")
                    return Empty().eraseToAnyPublisher()
                }
                return Fail(error: expected).eraseToAnyPublisher()
            }
            .receive(subscriber: subscriber)
    }
    
    /// Initializes an effect from a callback that can send as many values as it wants, and can send
    /// a completion.
    ///
    /// This initializer is useful for bridging callback APIs, delegate APIs, and manager APIs to the
    /// `Effect` type. One can wrap those APIs in an Effect so that its events are sent through the
    /// effect, which allows the reducer to handle them.
    ///
    /// For example, one can create an effect to ask for access to `MPMediaLibrary`. It can start by
    /// sending the current status immediately, and then if the current status is `notDetermined` it
    /// can request authorization, and once a status is received it can send that back to the effect:
    ///
    ///     Effect.async { subscriber in
    ///       subscriber.send(MPMediaLibrary.authorizationStatus())
    ///
    ///       guard MPMediaLibrary.authorizationStatus() == .notDetermined else {
    ///         subscriber.send(completion: .finished)
    ///         return AnyCancellable {}
    ///       }
    ///
    ///       MPMediaLibrary.requestAuthorization { status in
    ///         subscriber.send(status)
    ///         subscriber.send(completion: .finished)
    ///       }
    ///       return AnyCancellable {
    ///         // Typically clean up resources that were created here, but this effect doesn't
    ///         // have any.
    ///       }
    ///     }
    ///
    /// - Parameter run: A closure that accepts a `Subscriber` value and returns a cancellable. When
    ///   the `Effect` is completed, the cancellable will be used to clean up any
    ///   resources created when the effect was started.
    public static func run(
      _ run: @escaping (Effect.Subscriber<Output, Failure>) -> Cancellable
    ) -> Self {
      AnyPublisher.create(run).eraseToEffect()
    }
    
}

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
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
  public func eraseToEffect() -> Effect<Output, Failure> {
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
  /// - Returns: An effect that wraps `self`.
  public func catchToEffect() -> Effect<Result<Output, Failure>, Never> {
    self.map(Result.success)
      .catch { Just(.failure($0)) }
      .eraseToEffect()
  }
}
