//
//  Store+collectionBinding.swift
//  UneatenIngredients
//
//  Created by Bioche on 25/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift

public typealias RxFlatStoreCollectionDataSource<EachState, EachAction> = RxFlatCollectionDataSource<Store<EachState, EachAction>>
public typealias RxSectionedStoreCollectionDataSource<SectionState, SectionAction, ItemState, ItemAction> = RxSectionedCollectionDataSource<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>

extension Store {
  
  /// Binds datasource of stores to a collection view. No sections, only a flat list of items.
  ///
  /// - Parameters:
  ///   - collectionView: The collection to be populated
  ///   - datasource: The datasource that will fill the collection
  ///   - reloadCondition: The condition under which cells are gonna need a reload. By default c
  /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<EachState, EachAction>(collectionView: UICollectionView,
                                          to datasource: RxFlatStoreCollectionDataSource<EachState, EachAction>,
                                          reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable,
    Action == (EachState.ID, EachAction) {
      
      return bind(transformation: collectionView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  public func bind<EachState>(collectionView: UICollectionView,
                              to datasource: RxFlatStoreCollectionDataSource<EachState, Action>,
                              reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable {
      
      return bind(transformation: collectionView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  public func bind<SectionState, SectionAction, ItemState, ItemAction>
    (collectionView: UICollectionView,
     to datasource: RxSectionedStoreCollectionDataSource<SectionState, SectionAction, ItemState, ItemAction>,
     bindingConfiguration: SectionBindingConfiguration<SectionState, SectionAction, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable,
    Action == (SectionState.ID, SectionAction)
  {
    return bind(transformation: collectionView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
  }
  
  public func bind<SectionState, ItemState, ItemAction>
  (collectionView: UICollectionView,
   to datasource: RxSectionedStoreCollectionDataSource<SectionState, Action, ItemState, ItemAction>,
   bindingConfiguration: SectionBindingConfiguration<SectionState, Action, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable {
      
      return bind(transformation: collectionView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
      
  }
}
