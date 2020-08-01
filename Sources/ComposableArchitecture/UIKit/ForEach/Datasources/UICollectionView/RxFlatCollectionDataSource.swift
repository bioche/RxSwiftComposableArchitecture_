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

/// The datasource for collection views without sections : flat list of items.
public class RxFlatCollectionDataSource<ItemModel>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource {
  
  public let cellCreation: (UICollectionView, IndexPath, ItemModel) -> UICollectionViewCell
  public let applyingChanges: ApplyingChanges
  
  public var values = [Item]()
  
  public typealias Item = TCAItem<ItemModel>
  public typealias ApplyingChanges = (UICollectionView, RxFlatCollectionDataSource, Event<[Item]>) -> ()
  
  /// Inits the datasource
  ///
  /// - Parameters:
  ///   - cellCreation: The closure called each time a cell needs to be created
  ///   - applyingChanges: The closure that applies the changes in the item list. By default a full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
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
  
  /// The closure that applies the changes in the item list : A full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
  public static var fullReloading: ApplyingChanges {
    return { collectionView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      collectionView.reloadData()
    }
  }
}
