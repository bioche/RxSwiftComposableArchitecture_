#if canImport(UIKit)
#if !os(watchOS)
import UIKit
import RxSwift
import RxCocoa

/// The datasource for table views without sections : flat list of items.
public class RxFlatTableDataSource<ItemModel>: NSObject, RxTableViewDataSourceType, UITableViewDataSource {
  
  public let cellCreation: (UITableView, IndexPath, ItemModel) -> UITableViewCell
  public let applyingChanges: ApplyingChanges
  
  public var values = [Item]()
  
  public typealias Item = TCAItem<ItemModel>
  public typealias ApplyingChanges = (UITableView, RxFlatTableDataSource, Event<[Item]>) -> ()
  
  /// Inits the datasource
  ///
  /// - Parameters:
  ///   - cellCreation: The closure called each time a cell needs to be created
  ///   - applyingChanges: The closure that applies the changes in the item list. By default a full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
  public init(cellCreation: @escaping (UITableView, IndexPath, ItemModel) -> UITableViewCell,
       applyingChanges: @escaping ApplyingChanges = fullReloading) {
    self.cellCreation = cellCreation
    self.applyingChanges = applyingChanges
  }
  
  public func tableView(_ tableView: UITableView, observedEvent: Event<[Item]>) {
    applyingChanges(tableView, self, observedEvent)
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
  
  /// The closure that applies the changes in the item list : A full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
  public static var fullReloading: ApplyingChanges {
    return { collectionView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      collectionView.reloadData()
    }
  }
}
#endif
#endif
