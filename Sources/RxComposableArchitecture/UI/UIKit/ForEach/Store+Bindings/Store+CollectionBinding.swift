#if canImport(UIKit)
#if !os(watchOS)
import UIKit
import RxSwift

public typealias RxFlatStoreCollectionDataSource<EachState, EachAction> = RxFlatCollectionDataSource<Store<EachState, EachAction>>
public typealias RxSectionedStoreCollectionDataSource<SectionState, SectionAction, ItemState, ItemAction> = RxSectionedCollectionDataSource<Store<SectionState, SectionAction>, Store<ItemState, ItemAction>>

extension Store {
  
  /// Splits the original store into multiple stores : one for each sub-state (`EachState`) and binds it to the collection view using the provided `datasource`.
  ///
  /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
  /// - Parameters:
  ///   - collectionView: The collection view to be populated
  ///   - datasource: The datasource applying the changes to the collection view using the closure it was initialized with
  ///   - reloadCondition: By default all changes in state are to be handled by the stores. However, some changes mean a change of size of the cell. In such cases, use this closure to trigger a reload. Doesn't need to take id change into consideration as it's not a reload but a move
  /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<EachState, EachAction>(to collectionView: UICollectionView,
                                          using datasource: RxFlatStoreCollectionDataSource<EachState, EachAction>,
                                          reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable,
    Action == (EachState.ID, EachAction) {
      
      return bind(transformation: collectionView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  /// Splits the original store into multiple stores : one for each sub-state (`EachState`) and binds it to the collection view using the provided `datasource`.
  ///
  /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
  /// - Parameters:
  ///   - collectionView: The collection view to be populated
  ///   - datasource: The datasource applying the changes to the collection view using the closure it was initialized with
  ///   - reloadCondition: By default all changes in state are to be handled by the stores. However, some changes mean a change of size of the cell. In such cases, use this closure to trigger a reload. Doesn't need to take id change into consideration as it's not a reload but a move
  /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<EachState>(to collectionView: UICollectionView,
                              using datasource: RxFlatStoreCollectionDataSource<EachState, Action>,
                              reloadCondition: ReloadCondition<EachState> = .neverReload) -> Disposable
    where State == [EachState],
    EachState: TCAIdentifiable {
      
      return bind(transformation: collectionView.rx.items(dataSource: datasource), reloadCondition: reloadCondition)
  }
  
  /// Splits the original store into multiple stores for sectioned collections : one for each sub-state (`SectionState` and `ItemState`) and binds it to the collection view using the provided `datasource`.
   ///
   /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
   /// - Parameters:
   ///   - collectionView: The collection view to be populated
   ///   - datasource: The datasource applying the changes to the collection view using the closure it was initialized with
   ///   - bindingConfiguration: The configuration of bindings
   /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<SectionState, SectionAction, ItemState, ItemAction>
    (to collectionView: UICollectionView,
     using datasource: RxSectionedStoreCollectionDataSource<SectionState, SectionAction, ItemState, ItemAction>,
     bindingConfiguration: SectionBindingConfiguration<SectionState, SectionAction, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable,
    Action == (SectionState.ID, SectionAction)
  {
    return bind(transformation: collectionView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
  }
  
  /// Splits the original store into multiple stores for sectioned collections : one for each sub-state (`SectionState` and `ItemState`) and binds it to the collection view using the provided `datasource`.
   ///
   /// The datasource can be customized to apply of changes using the method of your choosing : Import the `ComposableDifferenceKitDatasources` framework to use `DifferenceKit`.
   /// - Parameters:
   ///   - collectionView: The collection view to be populated
   ///   - datasource: The datasource applying the changes to the collection view using the closure it was initialized with
   ///   - bindingConfiguration: The configuration of bindings
   /// - Returns: Disposable to be disposed whenever the collection view doesn't need filling anymore
  public func bind<SectionState, ItemState, ItemAction>
  (to collectionView: UICollectionView,
   using datasource: RxSectionedStoreCollectionDataSource<SectionState, Action, ItemState, ItemAction>,
   bindingConfiguration: SectionBindingConfiguration<SectionState, Action, ItemState, ItemAction>) -> Disposable
    where State == [SectionState],
    ItemState: TCAIdentifiable, SectionState: TCAIdentifiable {
      
      return bind(transformation: collectionView.rx.items(dataSource: datasource), bindingConfiguration: bindingConfiguration)
      
  }
}
#endif
#endif
