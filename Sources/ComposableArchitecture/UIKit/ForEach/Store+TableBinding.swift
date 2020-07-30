//
//  Store+TableBinding.swift
//  ComposableArchitecture
//
//  Created by Bioche on 30/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift

extension Store {
  // flat. By default no reload of the cell : all goes through the store
  public func bind<EachState, EachAction>(tableView: UITableView,
                                          to datasource: RxFlatTableDataSource<Store<EachState, EachAction>>,
                                          reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable,
    Action == (EachState.ID, EachAction) {
      
      return bind(transformation: tableView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  public func bind<EachState>(tableView: UITableView,
                              to datasource: RxFlatTableDataSource<Store<EachState, Action>>,
                              reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable {
      
      return bind(transformation: tableView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  public func bind<SectionState, SectionAction, ItemState, ItemAction>
    (tableView: UITableView,
     to datasource: RxSectionedTableDataSource<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>,
     bindingConfiguration: SectionBindingConfiguration<SectionState, SectionAction, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable,
    Action == (SectionState.ID, SectionAction)
  {
    return bind(transformation: tableView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
  }
  
  public func bind<SectionState, ItemState, ItemAction>
  (tableView: UITableView,
   to datasource: RxSectionedTableDataSource<Store<SectionState, Action>, Store<ItemState, ItemAction>>,
   bindingConfiguration: SectionBindingConfiguration<SectionState, Action, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable {
      
      return bind(transformation: tableView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
      
  }
}
