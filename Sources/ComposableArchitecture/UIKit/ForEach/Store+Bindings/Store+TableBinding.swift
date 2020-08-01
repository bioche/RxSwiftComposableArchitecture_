//
//  Store+TableBinding.swift
//  ComposableArchitecture
//
//  Created by Bioche on 30/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift

public typealias RxFlatStoreTableDataSource<EachState, EachAction> = RxFlatTableDataSource<Store<EachState, EachAction>>
public typealias RxSectionedStoreTableDataSource<SectionState, SectionAction, ItemState, ItemAction> = RxSectionedTableDataSource<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>
 
extension Store {
  /// Splits the original store into multiple stores : one for each sub-state (`EachState`) and binds it to the provided `datasource`.
  ///
  /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
  /// - Parameters:
  ///   - tableView: The table view to be populated
  ///   - datasource: The datasource applying the changes to the table view using the closure it was initialized with
  ///   - reloadCondition: By default all changes in state are to be handled by the stores. However, some changes mean a change of size of the cell. In such cases, use this closure to trigger a reload.
  /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<EachState, EachAction>(to tableView: UITableView,
                                          using datasource: RxFlatStoreTableDataSource<EachState, EachAction>,
                                          reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable,
    Action == (EachState.ID, EachAction) {
      
      return bind(transformation: tableView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  /// Splits the original store into multiple stores : one for each sub-state (`EachState`) and binds it to the provided `datasource`.
  ///
  /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
  /// - Parameters:
  ///   - tableView: The table view to be populated
  ///   - datasource: The datasource applying the changes to the table view using the closure it was initialized with
  ///   - reloadCondition: By default all changes in state are to be handled by the stores. However, some changes mean a change of size of the cell. In such cases, use this closure to trigger a reload.
  /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<EachState>(to tableView: UITableView,
                              using datasource: RxFlatStoreTableDataSource<EachState, Action>,
                              reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable {
      
      return bind(transformation: tableView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  /// Splits the original store into multiple stores for sectioned tables : one for each sub-state (`SectionState` and `ItemState`) and binds it to the table view using the provided `datasource`.
   ///
   /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
   /// - Parameters:
   ///   - tableView: The table view to be populated
   ///   - datasource: The datasource applying the changes to the collection view using the closure it was initialized with
   ///   - bindingConfiguration: The configuration of bindings
   /// - Returns: Disposable to be disposed whenever the table view doesn't need filling anymore
  public func bind<SectionState, SectionAction, ItemState, ItemAction>
    (to tableView: UITableView,
     using datasource: RxSectionedStoreTableDataSource<SectionState, SectionAction, ItemState, ItemAction>,
     bindingConfiguration: SectionBindingConfiguration<SectionState, SectionAction, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable,
    Action == (SectionState.ID, SectionAction)
  {
    return bind(transformation: tableView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
  }
  
  /// Splits the original store into multiple stores for sectioned tables : one for each sub-state (`SectionState` and `ItemState`) and binds it to the table view using the provided `datasource`.
   ///
   /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
   /// - Parameters:
   ///   - tableView: The table view to be populated
   ///   - datasource: The datasource applying the changes to the collection view using the closure it was initialized with
   ///   - bindingConfiguration: The configuration of bindings
   /// - Returns: Disposable to be disposed whenever the table view doesn't need filling anymore
  public func bind<SectionState, ItemState, ItemAction>
  (to tableView: UITableView,
   using datasource: RxSectionedStoreTableDataSource<SectionState, Action, ItemState, ItemAction>,
   bindingConfiguration: SectionBindingConfiguration<SectionState, Action, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable {
      
      return bind(transformation: tableView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
      
  }
}
