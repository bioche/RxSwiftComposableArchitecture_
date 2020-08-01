//
//  RxCollectionDataSource.swift
//  UneatenIngredients
//
//  Created by Bioche on 12/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// The datasource for sectioned collection views.
public class RxSectionedCollectionDataSource<SectionModel, CellModel>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource, SectionedViewDataSourceType {
  
  public typealias Section = TCASection<SectionModel, CellModel>
  public typealias ApplyingChanges = (UICollectionView, RxSectionedCollectionDataSource, Event<[Section]>) -> ()
  
  public let cellCreation: (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell
  public let headerCreation: ((UICollectionView, Int, SectionModel) -> UICollectionReusableView?)?
  public let applyingChanges: ApplyingChanges
  
  public var values: [Section] = []
  
  /// Init method
  /// - Parameters:
  ///   - cellCreation: Creation of the cell at the specified index
  ///   - headerCreation: Creation of the header for a specific section. For the headers to show, the headerReferenceSize must be set and/or implement the referenceSizeForHeaderInSection method of the collection delegate (apparently it doesn't support autolayout https://stackoverflow.com/questions/39825290/uicollectionview-header-dynamic-height-using-auto-layout ...).
  ///    For the sections where no header is returned, referenceSizeForHeaderInSection should return CGSize.zero
  ///   - applyingChanges: The closure that applies the changes in the section list. By default a full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit
  public init(cellCreation: @escaping (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell,
              headerCreation: ((UICollectionView, Int, SectionModel) -> UICollectionReusableView?)? = nil,
              applyingChanges: @escaping ApplyingChanges = fullReloading) {
    self.cellCreation = cellCreation
    self.headerCreation = headerCreation
    self.applyingChanges = applyingChanges
  }
  
  public func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Section]>) {
    applyingChanges(collectionView, self, observedEvent)
  }
  
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    values.count
  }
  
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    values[section].items.count
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    cellCreation(collectionView, indexPath, values[indexPath.section].items[indexPath.row].model)
  }
  
  public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    guard let section = values[safe: indexPath.section] else {
      return UICollectionReusableView()
    }
    return headerCreation?(collectionView, indexPath.section, section.model) ?? UICollectionReusableView()
  }
  
  public func section(at index: Int) -> Section {
    values[index]
  }
  
  public func cellModel(at indexPath: IndexPath) -> CellModel {
    section(at: indexPath.section).items[indexPath.row].model
  }
  
  public func model(at indexPath: IndexPath) throws -> Any {
    cellModel(at: indexPath)
  }
  
  /// The closure that applies the changes in the item list : A full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
  public static var fullReloading: ApplyingChanges {
    return { collectionView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      collectionView.reloadData()
    }
  }
}
