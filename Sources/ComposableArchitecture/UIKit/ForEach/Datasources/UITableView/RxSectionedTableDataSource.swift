//
//  RxSectionedDataSource.swift
//  pureairconnect
//
//  Created by Eric Blachère on 06/12/2019.
//  Copyright © 2019 Eric Blachère. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Allows for simple table view animations on changes based on DifferenceKit. (Avoids the heaviness of RxDatasource)
public class RxSectionedTableDataSource<SectionModel, CellModel>: NSObject, RxTableViewDataSourceType, UITableViewDataSource, SectionedViewDataSourceType {
  
  public typealias Section = TCASection<SectionModel, CellModel>
  public typealias ApplyingChanges = (UITableView, RxSectionedTableDataSource, Event<[Section]>) -> ()
  
  let cellCreation: (UITableView, IndexPath, CellModel) -> UITableViewCell
  let headerCreation: ((UITableView, Int, Section) -> UIView?)?
  let headerTitlesSource: ((UITableView, Int, Section) -> String?)?
  let applyingChanges: ApplyingChanges
  
  public var values: Element = []
  
  public init(cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
              headerCreation: ((UITableView, Int, Section) -> UIView?)? = nil,
              applyingChanges: @escaping ApplyingChanges = fullReloading) {
    self.cellCreation = cellCreation
    self.headerCreation = headerCreation
    self.headerTitlesSource = nil
    self.applyingChanges = applyingChanges
  }
  
  public init(cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
              headerTitlesSource: ((UITableView, Int, Section) -> String?)? = nil,
              applyingChanges: @escaping ApplyingChanges = fullReloading) {
    self.cellCreation = cellCreation
    self.headerTitlesSource = headerTitlesSource
    self.headerCreation = nil
    self.applyingChanges = applyingChanges
  }
  
  public func tableView(_ tableView: UITableView, observedEvent: RxSwift.Event<[Section]>) {
    applyingChanges(tableView, self, observedEvent)
  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    values[section].items.count
  }
  
  public func numberOfSections(in tableView: UITableView) -> Int {
    values.count
  }
  
  public func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
    guard let section = values[safe: sectionIndex] else {
      return nil
    }
    return headerTitlesSource?(tableView, sectionIndex, section)
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection sectionIndex: Int) -> UIView? {
    guard let section = values[safe: sectionIndex] else {
      return nil
    }
    return headerCreation?(tableView, sectionIndex, section)
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    cellCreation(tableView, indexPath, values[indexPath.section].items[indexPath.row].model)
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
  
  public static var fullReloading: ApplyingChanges {
    return { tableView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      tableView.reloadData()
    }
  }
}
