import Foundation

public struct TCAItem<Model> {
  public let model: Model
  public let modelReloadCondition: ReloadCondition<Model>
  
  public init(model: Model, modelReloadCondition: ReloadCondition<Model>) {
    self.model = model
    self.modelReloadCondition = modelReloadCondition
  }
}
