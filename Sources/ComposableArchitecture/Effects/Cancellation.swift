import RxSwift
import Foundation

extension Effect {
  /// Turns an effect into one that is capable of being canceled.
  ///
  /// To turn an effect into a cancellable one you must provide an identifier, which is used in
  /// `Effect.cancel(id:)` to identify which in-flight effect should be canceled. Any hashable
  /// value can be used for the identifier, such as a string, but you can add a bit of protection
  /// against typos by defining a new type that conforms to `Hashable`, such as an empty struct:
  ///
  ///     struct LoadUserId: Hashable {}
  ///
  ///     case .reloadButtonTapped:
  ///       // Start a new effect to load the user
  ///       return environment.loadUser
  ///         .map(Action.userResponse)
  ///         .cancellable(id: LoadUserId(), cancelInFlight: true)
  ///
  ///     case .cancelButtonTapped:
  ///       // Cancel any in-flight requests to load the user
  ///       return .cancel(id: LoadUserId())
  ///
  /// - Parameters:
  ///   - id: The effect's identifier.
  ///   - cancelInFlight: Determines if any in-flight effect with the same identifier should be
  ///     canceled before starting this new one.
  /// - Returns: A new effect that is capable of being canceled by an identifier.
  public func cancellable(id: AnyHashable, cancelInFlight: Bool = false) -> Effect {
    let effect: Effect<Output, Failure> = Observable<Output>.create { observer in
      cancellationDisposablesLock.lock()
      defer { cancellationDisposablesLock.unlock() }
      
      var disposable: Disposable?
      
      // create the disposable that is just a closure to be stored in the global dictionary
      // and exectuted when the original sequence finishes or is cancelled
      var cancellationDisposable: AnyDisposable!
      cancellationDisposable = AnyDisposable(
        Disposables.create {
          cancellationDisposablesLock.sync {
            observer.onCompleted()
            disposable?.dispose()
            cancellationDisposables[id]?.remove(cancellationDisposable)
            if cancellationDisposables[id]?.isEmpty == .some(true) {
              cancellationDisposables[id] = nil
            }
          }
      })
      
      // register the closure in the global dictionary
      cancellationDisposables[id, default: []].insert(
        cancellationDisposable
      )
      
      // bind the original sequence to the observer. We call the cancellation closure on completion or dispose to clear it from the global dictionary
      disposable = self.do(
        onCompletion: { _ in cancellationDisposable.dispose() },
        onDispose: cancellationDisposable.dispose
      )
        .bind(to: observer)
      
      return disposable!
    }
    .eraseToEffect()
    
    return cancelInFlight
      ? .concatenate(.cancel(id: id), effect)
      : effect
  }

  /// An effect that will cancel any currently in-flight effect with the given identifier.
  ///
  /// - Parameter id: An effect identifier.
  /// - Returns: A new effect that will cancel any currently in-flight effect with the given
  ///   identifier.
  public static func cancel(id: AnyHashable) -> Effect {
    return .fireAndForget {
      cancellationDisposablesLock.sync {
        cancellationDisposables[id]?.forEach { $0.dispose() }
      }
    }
  }
}

/// The references to disposables of all cancellable effects
var cancellationDisposables: [AnyHashable: Set<AnyDisposable>] = [:]

/// Avoids concurrent access to `cancellationDisposables`
let cancellationDisposablesLock = NSRecursiveLock()
