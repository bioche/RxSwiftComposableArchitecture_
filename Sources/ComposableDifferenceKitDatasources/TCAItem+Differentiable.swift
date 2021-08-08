import Foundation
import ComposableArchitecture
import DifferenceKit

extension TCAItem: TCAIdentifiable, ContentEquatable, ContentIdentifiable where Model: TCAIdentifiable {
  
  public var id: Model.ID { model.id }
  public var differenceIdentifier: Model.ID { model.id }
  
  public func isContentEqual(to source: Self) -> Bool {
    !modelReloadCondition(self.model, source.model)
  }
}
