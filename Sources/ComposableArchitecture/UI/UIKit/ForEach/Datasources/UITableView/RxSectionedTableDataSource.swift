#if canImport(UIKit)
#if !os(watchOS)
import UIKit
import RxSwift
import RxCocoa

/// The datasource for sectioned table views.
public class RxSectionedTableDataSource<SectionModel, CellModel>: NSObject, RxTableViewDataSourceType, UITableViewDataSource, SectionedViewDataSourceType {
  
  public typealias Section = TCASection<SectionModel, CellModel>
  public typealias ApplyingChanges = (UITableView, RxSectionedTableDataSource, Event<[Section]>) -> ()
  
  public let cellCreation: (UITableView, IndexPath, CellModel) -> UITableViewCell
  public let headerCreation: ((UITableView, Int, Section) -> UIView?)?
  public let headerTitlesSource: ((UITableView, Int, Section) -> String?)?
  public let applyingChanges: ApplyingChanges
  
  public var values: Element = []
  
  /// Inits the datasource with custom header views. For the header to appear, make sure to implement delegate method `tableView:viewForHeaderInSection:` and just call this datasource's `tableView:viewForHeaderInSection:` method.
  /// - Parameters:
  ///   - cellCreation: The closure called each time a cell needs to be created
  ///   - headerCreation: The closure called each time a header needs to be created
  ///   - applyingChanges: The closure that applies the changes in the section list. By default a full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
  public init(cellCreation: @escaping (UITableView, IndexPath, CellModel) -> UITableViewCell,
              headerCreation: ((UITableView, Int, Section) -> UIView?)? = nil,
              applyingChanges: @escaping ApplyingChanges = fullReloading) {
    self.cellCreation = cellCreation
    self.headerCreation = headerCreation
    self.headerTitlesSource = nil
    self.applyingChanges = applyingChanges
  }
  
  /// Inits the datasource with standard header views.
  /// - Parameters:
  ///   - cellCreation: The closure called each time a cell needs to be created
  ///   - headerTitlesSource: The closure called each time a header needs to be created
  ///   - applyingChanges: The closure that applies the changes in the item list. By default a full reload of the table is performed (reloadData). Import the `ComposableDifferenceKitDatasources` framework & use `differenceKitReloading` for a clever diff reload using DifferenceKit.
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
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection sectionIndex: Int) -> UIView? {
    guard let section = values[safe: sectionIndex] else {
      return nil
    }
    return headerCreation?(tableView, sectionIndex, section)
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    cellCreation(tableView, indexPath, values[indexPath.section].items[indexPath.row].model)
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
    return { tableView, datasource, observedEvent in
      datasource.values = observedEvent.element ?? []
      tableView.reloadData()
    }
  }
}
#endif
#endif
