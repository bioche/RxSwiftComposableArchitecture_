import RxSwift

public extension ObservableType {
  
  /// Subscription variant to be closer to Combine sink
  func subscribe(onNext: ((Element) -> Void)? = nil, onCompletion: ((Swift.Error?) -> Void)? = nil, onDisposed: (() -> Void)? = nil) -> Disposable {
    subscribe(onNext: onNext, onError: { onCompletion?($0) }, onCompleted: { onCompletion?(nil) }, onDisposed: onDisposed)
  }
  
  /// Do variant to be closer to Combine handleEvents
  func `do`(onNext: ((Element) throws -> Void)? = nil, onCompletion: ((Swift.Error?) throws -> Void)? = nil, onSubscribe: (() -> Void)? = nil, onSubscribed: (() -> Void)? = nil, onDispose: (() -> Void)? = nil) -> Observable<Element> {
    self.do(onNext: onNext, onError: { try onCompletion?($0) }, onCompleted: { try onCompletion?(nil) }, onSubscribe: onSubscribe, onSubscribed: onSubscribed, onDispose: onDispose)
  }
}
