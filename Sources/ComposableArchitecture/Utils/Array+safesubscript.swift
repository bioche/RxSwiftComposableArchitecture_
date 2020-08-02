//
//  Array+safesubscript.swift
//  ComposableArchitecture
//
//  Created by Bioche on 16/07/2020.
//  Copyright © 2020 Bioche. All rights reserved.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        get {
            guard index >= 0, index < endIndex else {
                return nil
            }

            return self[index]
        }
        set {
            guard index >= 0, index < endIndex, let newValue = newValue else {
                return
            }
            self[index] = newValue
        }
    }
}
