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
