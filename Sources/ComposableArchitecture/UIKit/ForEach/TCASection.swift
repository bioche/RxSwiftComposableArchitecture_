//
//  TCASection.swift
//  UneatenIngredients
//
//  Created by Bioche on 26/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

public struct TCASection<Model, ItemModel> {
  public let model: Model
  public let items: [TCAItem<ItemModel>]
  public let modelReloadCondition: ReloadCondition<Model>
  
  public init(model: Model, items: [TCAItem<ItemModel>], modelReloadCondition: ReloadCondition<Model>) {
    self.model = model
    self.items = items
    self.modelReloadCondition = modelReloadCondition
  }
}
