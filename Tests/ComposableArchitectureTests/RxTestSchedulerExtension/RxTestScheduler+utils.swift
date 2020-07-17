//
//  RxTestScheduler+utils.swift
//  ComposableArchitecture
//
//  Created by sebastien on 17/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import RxTest
import RxSwift


extension RxTest.TestScheduler {

  public static func defaultTestScheduler(withInitialClock initialClock: Int = 0) -> RxTest.TestScheduler {
    // simulateProcessingDelay must be set to false for everything to work
    RxTest.TestScheduler(initialClock: initialClock, resolution: 1.0, simulateProcessingDelay: false)
  }

  public func advance(by: TimeInterval = 0) {
    self.advanceTo(self.clock + Int(by))
  }

  public func run() {
    self.advanceTo(Int(Date.distantFuture.timeIntervalSince1970))
  }

}
