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
