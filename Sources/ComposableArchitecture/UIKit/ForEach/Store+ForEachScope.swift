//
//  Store+ForEachScope.swift
//  ComposableArchitecture
//
//  Created by Bioche on 27/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public typealias ReloadCondition<State> = (State, State) -> Bool
//
//public func noReload<State>(_ ls: State, _ rs: State) -> Bool { false }

//struct ReloadTest {
//  func callAsFunction(_ lState: )
//}

extension Store {
  /// Gives the evolution of a  list of stores scoped down to each element of this store.
  /// This avoids reloading entire collections / tables when only a property of an element is updated.
  /// The elements must be Identifiable so that we can publish a new array when an identity has changed at a specific index.
  /// For SwiftUI, prefer the ForEachStore
  public func scopeForEach<EachState>(reloadCondition: @escaping ReloadCondition<EachState> = { _, _ in false }) -> Driver<[Store<EachState, Action>]>
    where State == [EachState], EachState: TCAIdentifiable {

      return scope(state: { $0 }, action: { $1 })
        .scopeForEach(reloadCondition: reloadCondition)
  }

  public func scopeForEach<EachState, EachAction>(reloadCondition: @escaping (EachState, EachState) -> Bool = { _, _ in false }) -> Driver<[Store<EachState, EachAction>]>
    where State == [EachState], EachState: TCAIdentifiable, Action == (EachState.ID, EachAction) {

      stateRelay
        // with this we avoid sending a new array each time a modification occurs on an element.
        // Instead we publish a new array when the count changes or an object has changed identity (ID has changed)
        .distinctUntilChanged {
          guard $0.count == $1.count else { return false }
          return zip($0, $1).allSatisfy { $0.id == $1.id && !reloadCondition($0, $1) }
        }
        // Scope an new substore for each element
        .map { state in
          state.enumerated().map { index, subState in
            self.scope(initialLocalState: subState,
                       state: { $0[safe: index] },
                       action: { (subState.id, $0) })
          }
        }
        // no error possible as we come from a relay
        .asDriver(onErrorDriveWith: .never())
  }

}
