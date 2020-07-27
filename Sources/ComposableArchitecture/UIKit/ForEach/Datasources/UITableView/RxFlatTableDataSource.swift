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

class RxFlatTableDataSource<ItemModel>: NSObject, RxTableViewDataSourceType, UITableViewDataSource {
    
    let cellCreation: (UITableView, IndexPath, ItemModel) -> UITableViewCell
    let reloading: ReloadingClosure
    var values = [Item]()
    
    typealias Item = TCAItem<ItemModel>
    typealias ReloadingClosure = (UITableView, RxFlatTableDataSource, Event<[Item]>) -> ()
    
    init(cellCreation: @escaping (UITableView, IndexPath, ItemModel) -> UITableViewCell,
         reloadingClosure: @escaping ReloadingClosure = fullReloading) {
        self.cellCreation = cellCreation
        self.reloading = reloadingClosure
    }
    
    func tableView(_ tableView: UITableView, observedEvent: Event<[Item]>) {
        reloading(tableView, self, observedEvent)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellCreation(tableView, indexPath, values[indexPath.row].model)
    }
    
    static var fullReloading: ReloadingClosure {
        return { collectionView, datasource, observedEvent in
            datasource.values = observedEvent.element ?? []
            collectionView.reloadData()
        }
    }
}
