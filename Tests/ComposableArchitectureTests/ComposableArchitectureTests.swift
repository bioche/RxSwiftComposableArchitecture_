import RxSwift
import RxTest
import ComposableArchitecture
import XCTest

final class ComposableArchitectureTests: XCTestCase {
  var disposebag = DisposeBag()

  func testScheduling() {
    enum CounterAction: Equatable {
      case incrAndSquareLater
      case incrNow
      case squareNow
    }

    let counterReducer = Reducer<Int, CounterAction, SchedulerType> {
      state, action, scheduler in
      switch action {
      case .incrAndSquareLater:
        return .merge(
          Effect<CounterAction, Never>(value: .incrNow).delay(.seconds(2), scheduler: scheduler).eraseToEffect(),
          Effect<CounterAction, Never>(value: .squareNow).delay(.seconds(1), scheduler: scheduler).eraseToEffect(),
          Effect<CounterAction, Never>(value: .squareNow).delay(.seconds(2), scheduler: scheduler).eraseToEffect()
        )
      case .incrNow:
        state += 1
        return .none
      case .squareNow:
        state *= state
        return .none
      }
    }

    let scheduler = RxTest.TestScheduler.defaultTestScheduler()

    let store = TestStore(
      initialState: 2,
      reducer: counterReducer,
      environment: scheduler
    )
    
    store.assert(
      .send(.incrAndSquareLater),
      .do { scheduler.advance(by: 1) },
      .receive(.squareNow) { $0 = 4 },
      .do { scheduler.advance(by: 1) },
      .receive(.incrNow) { $0 = 5 },
      .receive(.squareNow) { $0 = 25 }
    )

    store.assert(
      .send(.incrAndSquareLater),
      .do { scheduler.advance(by: 2) },
      .receive(.squareNow) { $0 = 625 },
      .receive(.incrNow) { $0 = 626 },
      .receive(.squareNow) { $0 = 391876 }
    )
  }

  // something is wrong with this one, I don't understand what 
//  func testSimultaneousWorkOrdering() {
////    let testScheduler = TestScheduler<
////      DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions
////    >(
////      now: .init(.init(uptimeNanoseconds: 1))
////    )
//    let testScheduler = RxTest.TestScheduler.defaultTestScheduler()
//
//    var values: [Int] = []
//    testScheduler.schedulePeriodic(0, startAfter: .milliseconds(0), period: .seconds(1)) { (_) in
//      values.append(1)
//      return 0
//    }.disposed(by: disposebag)
//    testScheduler.schedulePeriodic(0, startAfter: .milliseconds(0), period: .seconds(2)) { (_) in
//      values.append(42)
//      return 0
//    }.disposed(by: disposebag)
//
////    testScheduler.scheduleAt(1) { values.append(1) }
////    testScheduler.scheduleAt(2) { values.append(42) }
////    testScheduler.schedule(after: testScheduler.now, interval: 1) { values.append(1) }
////      .store(in: &self.cancellables)
////    testScheduler.schedule(after: testScheduler.now, interval: 2) { values.append(42) }
////      .store(in: &self.cancellables)
//
//    XCTAssertEqual(values, [])
//    testScheduler.advance()
//    XCTAssertEqual(values, [1, 42])
//    testScheduler.advance(by: 2)
//    XCTAssertEqual(values, [1, 42, 1, 1, 42])
//  }

  func testLongLivingEffects() {
    typealias Environment = (
      startEffect: Effect<Void, Never>,
      stopEffect: Effect<Never, Never>
    )

    enum Action { case end, incr, start }

    let reducer = Reducer<Int, Action, Environment> { state, action, environment in
      switch action {
      case .end:
        return environment.stopEffect.fireAndForget()
      case .incr:
        state += 1
        return .none
      case .start:
        return environment.startEffect.map { Action.incr }
      }
    }

    let subject = PublishSubject<Void>()

    let store = TestStore(
      initialState: 0,
      reducer: reducer,
      environment: (
        startEffect: subject.eraseToEffect(),
        stopEffect: .fireAndForget { subject.onCompleted() }
      )
    )

    store.assert(
      .send(.start),
      .send(.incr) { $0 = 1 },
      .do { subject.onNext(()) },
      .receive(.incr) { $0 = 2 },
      .send(.end)
    )
  }

  func testCancellation() {
    enum Action: Equatable {
      case cancel
      case incr
      case response(Int)
    }

    struct Environment {
      let fetch: (Int) -> Effect<Int, Never>
      let mainQueue: SchedulerType
    }

    let reducer = Reducer<Int, Action, Environment> { state, action, environment in
      struct CancelId: Hashable {}

      switch action {
      case .cancel:
        return .cancel(id: CancelId())

      case .incr:
        state += 1
        return environment.fetch(state)
          .observeOn(environment.mainQueue)
          .map(Action.response)
          .eraseToEffect()
          .cancellable(id: CancelId())

      case let .response(value):
        state = value
        return .none
      }
    }

    let scheduler = RxTest.TestScheduler.defaultTestScheduler()

    let store = TestStore(
      initialState: 0,
      reducer: reducer,
      environment: Environment(
        fetch: { value in Effect(value: value * value) },
        mainQueue: scheduler
      )
    )

    store.assert(
      .send(.incr) { $0 = 1 },
      .do { scheduler.advance() },
      .receive(.response(1)) { $0 = 1 }
    )

    store.assert(
      .send(.incr) { $0 = 2 },
      .send(.cancel),
      .do { scheduler.run() }
    )
  }
}
