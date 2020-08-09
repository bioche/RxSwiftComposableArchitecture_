import RxSwift
import RxTest
import XCTest

@testable import ComposableArchitecture

final class EffectTests: XCTestCase {
  var disposeBag = DisposeBag()
  let scheduler = RxTest.TestScheduler.defaultTestScheduler()

  func testEraseToEffectWithError() {
    struct Error: Swift.Error, Equatable {}
    Observable<Int>.just(42)
      .catchToEffect(failureType: Error.self)
      .subscribe(onNext: { XCTAssertEqual($0, .success(42)) })
      .disposed(by: disposeBag)
    
    Observable<Int>.create({ (observer) in
      observer.on(.error(Error()))
      return Disposables.create()
    }).catchToEffect(failureType: Error.self)
      .subscribe(onNext: { XCTAssertEqual($0, .failure(Error())) })
      .disposed(by: disposeBag)
    
    Observable<Int>.just(42)
      .eraseToEffect(failureType: Error.self)
      .subscribe(onNext: { XCTAssertEqual($0, 42) })
      .disposed(by: disposeBag)
  }

  func testConcatenate() {
    var values: [Int] = []

    let effect = Effect<Int, Never>.concatenate(
      Effect<Int, Never>(value: 1).delay(.seconds(1), scheduler: scheduler).eraseToEffect(),
      Effect<Int, Never>(value: 2).delay(.seconds(2), scheduler: scheduler).eraseToEffect(),
      Effect<Int, Never>(value: 3).delay(.seconds(3), scheduler: scheduler).eraseToEffect()
    )

    effect
      .subscribe(onNext: { values.append($0) })
      .disposed(by: disposeBag)

    XCTAssertEqual(values, [])

    self.scheduler.advance(by: 1)
    XCTAssertEqual(values, [1])

    self.scheduler.advance(by: 2)
    XCTAssertEqual(values, [1, 2])

    self.scheduler.advance(by: 3)
    XCTAssertEqual(values, [1, 2, 3])

    self.scheduler.run()
    XCTAssertEqual(values, [1, 2, 3])
  }

  func testConcatenateOneEffect() {
    var values: [Int] = []

    let effect = Effect<Int, Never>.concatenate(
      Effect<Int, Never>(value: 1).delay(.seconds(1), scheduler: scheduler).eraseToEffect()
    )

    effect
      .subscribe(onNext: { values.append($0) })
      .disposed(by: disposeBag)

    XCTAssertEqual(values, [])

    self.scheduler.advance(by: 1)
    XCTAssertEqual(values, [1])

    self.scheduler.run()
    XCTAssertEqual(values, [1])
  }

  func testMerge() {
    let effect = Effect<Int, Never>.merge(
      Effect<Int, Never>(value: 1).delay(.seconds(1), scheduler: scheduler).eraseToEffect(),
      Effect<Int, Never>(value: 2).delay(.seconds(2), scheduler: scheduler).eraseToEffect(),
      Effect<Int, Never>(value: 3).delay(.seconds(3), scheduler: scheduler).eraseToEffect()
    )

    var values: [Int] = []
    effect
      .subscribe(onNext: { values.append($0) })
      .disposed(by: disposeBag)

    XCTAssertEqual(values, [])

    self.scheduler.advance(by: 1)
    XCTAssertEqual(values, [1])

    self.scheduler.advance(by: 1)
    XCTAssertEqual(values, [1, 2])

    self.scheduler.advance(by: 1)
    XCTAssertEqual(values, [1, 2, 3])
  }

  func testEffectSubscriberInitializer() {
    let effect = Effect<Int, Never>.run { (observer) -> Disposable in
      observer.onNext(1)
      observer.onNext(2)
      self.scheduler.scheduleRelative((), dueTime: .seconds(1)) { (_) in
        observer.onNext(3)
        return Disposables.create()
      }.disposed(by: self.disposeBag)
      self.scheduler.scheduleRelative((), dueTime: .seconds(2)) { (_) in
        observer.onNext(4)
        observer.onCompleted()
        return Disposables.create()
      }.disposed(by: self.disposeBag)
      
      return Disposables.create()
    }

    var values: [Int] = []
    var isComplete = false
    effect
      .subscribe(onNext: { values.append($0) }, onCompleted: { isComplete = true })
      .disposed(by: disposeBag)

    XCTAssertEqual(values, [1, 2])
    XCTAssertEqual(isComplete, false)

    self.scheduler.advance(by: 1)

    XCTAssertEqual(values, [1, 2, 3])
    XCTAssertEqual(isComplete, false)

    self.scheduler.advance(by: 1)

    XCTAssertEqual(values, [1, 2, 3, 4])
    XCTAssertEqual(isComplete, true)
  }

  func testEffectSubscriberInitializer_WithCancellation() {
    struct CancelId: Hashable {}

    let effect = Effect<Int, Never>.run { observer -> Disposable in
      observer.onNext(1)
      self.scheduler.scheduleRelative((), dueTime: .seconds(1)) {
        observer.onNext(2)
        return Disposables.create()
      }
      .disposed(by: self.disposeBag)

      return Disposables.create()
    }
    .cancellable(id: CancelId())

    var values: [Int] = []
    var isComplete = false
    effect
      .subscribe(onNext: { values.append($0) }, onCompleted: { isComplete = true })
      .disposed(by: disposeBag)

    XCTAssertEqual(values, [1])
    XCTAssertEqual(isComplete, false)

    Effect<Void, Never>.cancel(id: CancelId())
      .subscribe(onNext: {})
      .disposed(by: disposeBag)

    self.scheduler.advance(by: 1)

    XCTAssertEqual(values, [1])
    XCTAssertEqual(isComplete, true)
  }
}
