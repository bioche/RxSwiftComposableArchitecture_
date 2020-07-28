//
//  RxSectionedCollectionDataSource+DifferenceKit.swift
//  ComposableArchitecture
//
//  Created by Bioche on 29/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation
import DifferenceKit
import ComposableArchitecture

extension RxSectionedCollectionDataSource where SectionModel: TCAIdentifiable, CellModel: TCAIdentifiable {
  public static var differenceKitReloading: ReloadingClosure {
    return { collectionView, datasource, observedEvent in
      let source = datasource.values
      let target = observedEvent.element ?? []
      let changeset = StagedChangeset(source: source, target: target)
      
      print("changeset : \(changeset)")
      
      collectionView.reload(using: changeset) { data in
        datasource.values = data
      }                            
    }
  }
}
