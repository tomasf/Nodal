import Foundation

/// Represents an expanded name consisting of a namespace URI and a local name.
///
/// An `ExpandedName` is used to uniquely identify XML names, including attributes and elements, by combining:
/// - `namespaceName`: The namespace URI to which the name belongs (optional).
/// - `localName`: The local part of the name.
///
/// This provides a clear separation between names in different namespaces, even when their local parts are identical.
public struct ExpandedName: Hashable, Sendable {
    /// The namespace URI to which the name belongs, or `nil` if there is no namespace.
    public let namespaceName: String?

    /// The local part of the name.
    public let localName: String

    /// Creates a new expanded name with the specified namespace and local name.
    ///
    /// - Parameters:
    ///   - uri: The namespace URI of the name. Pass `nil` if the name does not belong to a namespace.
    ///   - localName: The local part of the name.
    public init(namespaceName uri: String?, localName: String) {
        self.namespaceName = uri
        self.localName = localName
    }
}

internal extension ExpandedName {
    // Returns nil if the namespace could not be resolved
    func qualifiedAttributeName(in element: Element) -> String? {
        guard let namespaceName else {
            return localName
        }

        // Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default
        guard let prefix = element.nonDefaultPrefix(for: namespaceName) else {
            return nil
        }
        return String(prefix: prefix, localPart: localName)
    }
}
