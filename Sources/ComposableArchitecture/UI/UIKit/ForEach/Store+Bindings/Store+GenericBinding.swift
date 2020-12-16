import Foundation
import RxSwift

/// An extension that works for both collections and tables (and any transformation that needs an array of items or sections as input 😉)
extension Store {
  func bind<EachState, EachAction>(transformation: @escaping (Observable<[TCAItem<Store<EachState, EachAction>>]>) -> Disposable,
                                   reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable,
    Action == (EachState.ID, EachAction) {
      
      return scopeForEach(reloadCondition: reloadCondition)
        .map { $0.map { TCAItem(model: $0, modelReloadCondition: Store<EachState, EachAction>.reloadCondition(reloadCondition)) } }
        .drive(transformation)
  }
  
  func bind<EachState>(transformation: @escaping (Observable<[TCAItem<Store<EachState, Action>>]>) -> Disposable,
                       reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable {
      scope(state: { $0 }, action: { $1 })
        .bind(transformation: transformation,
              reloadCondition: reloadCondition)
  }
  
  func bind<SectionState, SectionAction, ItemState, ItemAction>
    (transformation: @escaping (Observable<[TCASection<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>]>) -> Disposable,
     bindingConfiguration: SectionBindingConfiguration<SectionState, SectionAction, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable,
    Action == (SectionState.ID, SectionAction)
  {
    /// When the content of the header itself changes
    /// or elements below have a change that calls for update of cells, we return true.
    /// Then the stores will be given to differenceKit so that it updates the cells / header that need to.
    let sectionReloadCondition: ReloadCondition<SectionState> = .reloadWhen {
      bindingConfiguration.headerReloadCondition($0, $1)
        || bindingConfiguration.items($0).count != bindingConfiguration.items($1).count
        || !zip(bindingConfiguration.items($0), bindingConfiguration.items($1))
          .allSatisfy {
            !bindingConfiguration.itemsReloadCondition($0, $1)
              && $0.id == $1.id
      }
    }
    
    return scopeForEach(reloadCondition: sectionReloadCondition) // --> Only reload when a difference that can't be handled by the stores themselves is detected.
      .map { $0.map { store in
        var elements = [Store<ItemState, ItemAction>]()
        let disposable = store.scope(state: { bindingConfiguration.items($0) }, action: bindingConfiguration.actionScoping)
          .scopeForEach()
          .drive(onNext: { elements = $0 })
        disposable.dispose()
        let items = elements
          .map { TCAItem(model: $0, modelReloadCondition: Store<ItemState, ItemAction>.reloadCondition(bindingConfiguration.itemsReloadCondition)) }
        return TCASection(model: store, items: items, modelReloadCondition: Store<SectionState, SectionAction>.reloadCondition(bindingConfiguration.headerReloadCondition))
        }
    }
    .drive(transformation)
  }
  
  func bind<SectionState, ItemState, ItemAction>
  (transformation: @escaping (Observable<[TCASection<Store<SectionState, Action>, Store<ItemState, ItemAction>>]>) -> Disposable,
   bindingConfiguration: SectionBindingConfiguration<SectionState, Action, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable {
      scope(state: { $0 }, action: { $1 })
        .bind(transformation: transformation,
              bindingConfiguration: bindingConfiguration)
  }  
}

extension Store {
  fileprivate static func reloadCondition(_ stateCondition: ReloadCondition<State>) -> ReloadCondition<Store<State, Action>> {
    .reloadWhen { stateCondition($0.state, $1.state) }
  }
}
