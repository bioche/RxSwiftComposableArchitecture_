//
//  Store+ReloadCondition.swift
//  UneatenIngredients
//
//  Created by Bioche on 27/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

extension Store {
  static func reloadCondition(_ stateCondition: ReloadCondition<State>) -> ReloadCondition<Store<State, Action>> {
    .reloadWhen { stateCondition($0.state, $1.state) }
  }
}
