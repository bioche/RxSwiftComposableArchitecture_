import Foundation

/// The configuration of bindings
public struct SectionBindingConfiguration<SectionState: TCAIdentifiable, SectionAction, ItemState: TCAIdentifiable, ItemAction> {
  /// Gives the items for each section
  let items: (SectionState) -> [ItemState]
  /// Return true when the difference can't be handled by stores
  /// thus requiring a reload of the cell (typically a change of cell size)
  /// Doesn't need to take id change into consideration as it's not a reload but a move
  let itemsReloadCondition: ReloadCondition<ItemState>
  /// Condition to reload the header. This will reload the full section as well.
  /// Doesn't need to take id change into consideration as it's not a reload but a move
  let headerReloadCondition: ReloadCondition<SectionState>
  /// The transformation between item action and section action.
  let actionScoping: (ItemState.ID, ItemAction) -> SectionAction
  
  public init(items: @escaping (SectionState) -> [ItemState],
              itemsReloadCondition: ReloadCondition<ItemState>,
              headerReloadCondition: ReloadCondition<SectionState>,
              actionScoping: @escaping (ItemState.ID, ItemAction) -> SectionAction) {
    self.items = items
    self.itemsReloadCondition = itemsReloadCondition
    self.headerReloadCondition = headerReloadCondition
    self.actionScoping = actionScoping
  }
}

extension SectionBindingConfiguration where ItemAction == SectionAction {
  /// Inits the configuration when the items have the same action as the sections
  public init(items: @escaping (SectionState) -> [ItemState],
              itemsReloadCondition: ReloadCondition<ItemState>,
              headerReloadCondition: ReloadCondition<SectionState>) {
    self.init(items: items,
              itemsReloadCondition: itemsReloadCondition,
              headerReloadCondition: headerReloadCondition,
              actionScoping: { $1 })
  }
}
