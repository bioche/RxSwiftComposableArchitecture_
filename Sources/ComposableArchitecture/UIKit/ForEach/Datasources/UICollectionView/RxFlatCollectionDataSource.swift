//
//  RxFlatCollectionDataSource.swift
//  UneatenIngredients
//
//  Created by Bioche on 22/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

public class RxFlatCollectionDataSource<ItemModel>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource {
  
  let cellCreation: (UICollectionView, IndexPath, ItemModel) -> UICollectionViewCell
  let applyingChanges: ApplyingChanges
  
  public var values = [Item]()
  
  public typealias Item = TCAItem<ItemModel>
  public typealias ApplyingChanges = (UICollectionView, RxFlatCollectionDataSource, Event<[Item]>) -> ()
  
  public init(cellCreation: @escaping (UICollectionView, IndexPath, ItemModel) -> UICollectionViewCell,
              applyingChanges: @escaping ApplyingChanges = fullReloading) {
    self.cellCreation = cellCreation
    self.applyingChanges = applyingChanges
  }
  
  public func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Item]>) {
    applyingChanges(collectionView, self, observedEvent)
  }
  
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }
  
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    values.count
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    cellCreation(collectionView, indexPath, values[indexPath.row].model)
  }
  
  public static var fullReloading: ApplyingChanges {
    return { collectionView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      collectionView.reloadData()
    }
  }
}
