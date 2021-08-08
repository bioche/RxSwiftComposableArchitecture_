#if canImport(UIKit)
#if !os(watchOS)
import UIKit
import DifferenceKit
import ComposableArchitecture

extension RxFlatTableDataSource where ItemModel: TCAIdentifiable {
  public static func differenceKitReloading(animation: UITableView.RowAnimation) -> ApplyingChanges {
    return { tableView, datasource, observedEvent in
      let source = datasource.values
      let target = observedEvent.element ?? []
      let changeset = StagedChangeset(source: source, target: target)
      
      tableView.reload(using: changeset, with: animation) { data in
        datasource.values = data
      }
    }
  }
}
#endif
#endif
