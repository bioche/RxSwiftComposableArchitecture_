import Foundation

/// Redefinition of Apple (iOS 13 only) Identifiable protocol.
/// Makes it available on iOS 12 which allows full power of `IdentifiedArray` & `Identified`
public protocol TCAIdentifiable {

    /// A type representing the stable identity of the entity associated with `self`.
    associatedtype ID : Hashable

    /// The stable identity of the entity associated with `self`.
    var id: Self.ID { get }
}
