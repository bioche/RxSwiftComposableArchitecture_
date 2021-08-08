import Foundation
import RxSwift
#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ObservableConvertibleType {
  public func asPublisher() -> AnyPublisher<Element, Error> {
    AnyPublisher.create { subscriber -> Cancellable in
      let disposable = self.asObservable().subscribe(onNext: { element in
        subscriber.send(element)
      }, onError: { error in
        subscriber.send(completion: .failure(error))
      }, onCompleted: {
        subscriber.send(completion: .finished)
      })
      return AnyCancellable { disposable.dispose() }
    }
  }
  
  public var publisher: AnyPublisher<Element, Error> {
    asPublisher()
  }
  
}
#endif
