import Foundation
import Combine
import RxSwift

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ObservableConvertibleType {
    /// Gives a publisher that will never fail.
    /// In case the observable sends an error it will complete
    var unfailablePublisher: AnyPublisher<Element, Never> {
        publisher
        .catch { _ in Empty() }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnyCancellable: Disposable {
    public func dispose() {
        cancel()
    }
}

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Store {

    /// Scopes the store to a publisher of stores of more local state and local actions.
    ///
    /// - Parameters:
    ///   - toLocalState: A function that transforms a publisher of `State` into a publisher of
    ///     `LocalState`.
    ///   - fromLocalAction: A function that transforms `LocalAction` into `Action`.
    /// - Returns: A publisher of stores with its domain (state and action) transformed.
    public func scope<P: Publisher, LocalState, LocalAction>(
      state toLocalState: @escaping (AnyPublisher<State, Never>) -> P,
      action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> AnyPublisher<Store<LocalState, LocalAction>, Never>
    where P.Output == LocalState, P.Failure == Never {
        scope(state: { (observable: Observable<State>) -> Observable<LocalState> in
            toLocalState(observable.unfailablePublisher).asObservable()
            }, action: fromLocalAction).unfailablePublisher
    }

    /// Scopes the store to a publisher of stores of more local state and local actions.
    ///
    /// - Parameter toLocalState: A function that transforms a publisher of `State` into a publisher
    ///   of `LocalState`.
    /// - Returns: A publisher of stores with its domain (state and action)
    ///   transformed.
    public func scope<P: Publisher, LocalState>(
      state toLocalState: @escaping (AnyPublisher<State, Never>) -> P
    ) -> AnyPublisher<Store<LocalState, Action>, Never>
    where P.Output == LocalState, P.Failure == Never {
      self.scope(state: toLocalState, action: { $0 })
    }
    
}

/// A publisher of store state.
@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@dynamicMemberLookup
public struct StorePublisher<State>: Publisher {
  public typealias Output = State
  public typealias Failure = Never

  public let upstream: AnyPublisher<State, Never>

  public func receive<S>(subscriber: S)
  where S: Subscriber, Failure == S.Failure, Output == S.Input {
    self.upstream.receive(subscriber: subscriber)
  }

  init<P>(_ upstream: P) where P: Publisher, Failure == P.Failure, Output == P.Output {
    self.upstream = upstream.eraseToAnyPublisher()
  }

  /// Returns the resulting publisher of a given key path.
  public subscript<LocalState>(
    dynamicMember keyPath: KeyPath<State, LocalState>
  ) -> StorePublisher<LocalState>
  where LocalState: Equatable {
    .init(self.upstream.map(keyPath).removeDuplicates())
  }
}
