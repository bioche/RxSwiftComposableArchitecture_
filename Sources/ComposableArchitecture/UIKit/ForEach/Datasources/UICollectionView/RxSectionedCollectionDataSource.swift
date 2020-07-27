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

public class RxSectionedCollectionDataSource<SectionModel, CellModel>: NSObject, RxCollectionViewDataSourceType, UICollectionViewDataSource, SectionedViewDataSourceType {
  
  public typealias Section = TCASection<SectionModel, CellModel>
  public typealias ReloadingClosure = (UICollectionView, RxSectionedCollectionDataSource, Event<[Section]>) -> ()
  
  let cellCreation: (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell
  let headerCreation: ((UICollectionView, Int, SectionModel) -> UICollectionReusableView?)?
  let reloading: ReloadingClosure
  
  public var values: [Section] = []
  
  /// Init method
  /// - Parameters:
  ///   - cellCreation: Creation of the cell at the specified index
  ///   - headerCreation: Creation of the header for a specific section. For the headers to show, the headerReferenceSize must be set and/or implement the referenceSizeForHeaderInSection method of the collection delegate (apparently it doesn't support autolayout https://stackoverflow.com/questions/39825290/uicollectionview-header-dynamic-height-using-auto-layout ...).
  ///    For the sections where no header is returned, referenceSizeForHeaderInSection should return CGSize.zero
  public init(cellCreation: @escaping (UICollectionView, IndexPath, CellModel) -> UICollectionViewCell,
              headerCreation: ((UICollectionView, Int, SectionModel) -> UICollectionReusableView?)? = nil,
              reloading: @escaping ReloadingClosure = fullReloading) {
    self.cellCreation = cellCreation
    self.headerCreation = headerCreation
    self.reloading = reloading
  }
  
  public func collectionView(_ collectionView: UICollectionView, observedEvent: Event<[Section]>) {
    reloading(collectionView, self, observedEvent)
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
  
  func section(at index: Int) -> Section {
    values[index]
  }
  
  func cellModel(at indexPath: IndexPath) -> CellModel {
    section(at: indexPath.section).items[indexPath.row].model
  }
  
  public func model(at indexPath: IndexPath) throws -> Any {
    cellModel(at: indexPath)
  }
  
  public static var fullReloading: ReloadingClosure {
    return { collectionView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      collectionView.reloadData()
    }
  }
}
