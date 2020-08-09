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

// we use 0.01 as a resolution, because in the tests we are sometime advancing time by 0.25
let resolution = 0.01

extension RxTest.TestScheduler {
  
  public static func defaultTestScheduler(withInitialClock initialClock: Int = 0) -> RxTest.TestScheduler {
    // simulateProcessingDelay must be set to false for everything to work
    RxTest.TestScheduler(initialClock: initialClock, resolution: resolution, simulateProcessingDelay: false)
  }

   public func advance(by: TimeInterval = 0) {
    self.advanceTo(self.clock + Int( by / resolution ))
   }

  public func run() {
    self.advanceTo(Int(Date.distantFuture.timeIntervalSince1970))
  }

}
