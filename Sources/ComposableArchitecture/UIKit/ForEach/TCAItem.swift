//
//  TCAItem.swift
//  UneatenIngredients
//
//  Created by Bioche on 26/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

public struct TCAItem<Model> {
  public let model: Model
  public let modelReloadCondition: ReloadCondition<Model>
  
  public init(model: Model, modelReloadCondition: ReloadCondition<Model>) {
    self.model = model
    self.modelReloadCondition = modelReloadCondition
  }
}
