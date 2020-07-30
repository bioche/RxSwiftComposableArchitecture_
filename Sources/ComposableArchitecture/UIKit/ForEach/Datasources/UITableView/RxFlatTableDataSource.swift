//
//  RxFlatTableDataSource.swift
//  UneatenIngredients
//
//  Created by Bioche on 25/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public class RxFlatTableDataSource<ItemModel>: NSObject, RxTableViewDataSourceType, UITableViewDataSource {
  
  let cellCreation: (UITableView, IndexPath, ItemModel) -> UITableViewCell
  let changesApplication: ChangesApplication
  public var values = [Item]()
  
  public typealias Item = TCAItem<ItemModel>
  public typealias ChangesApplication = (UITableView, RxFlatTableDataSource, Event<[Item]>) -> ()
  
  init(cellCreation: @escaping (UITableView, IndexPath, ItemModel) -> UITableViewCell,
       changesApplication: @escaping ChangesApplication = fullReloading) {
    self.cellCreation = cellCreation
    self.changesApplication = changesApplication
  }
  
  public func tableView(_ tableView: UITableView, observedEvent: Event<[Item]>) {
    changesApplication(tableView, self, observedEvent)
  }
  
  public func numberOfSections(in tableView: UITableView) -> Int {
    1
  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    values.count
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    cellCreation(tableView, indexPath, values[indexPath.row].model)
  }
  
  static var fullReloading: ChangesApplication {
    return { collectionView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      collectionView.reloadData()
    }
  }
}
