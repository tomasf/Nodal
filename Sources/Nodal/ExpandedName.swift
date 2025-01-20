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

    init(qualifiedAttributeName qName: String, using namespaces: NamespaceBindings) {
        self.init(namespaceName: namespaces[qName.qNamePrefix], localName: qName.qNameLocalName)
    }

    func qualifiedElementName(using namespaces: NamespaceBindings) -> String {
        let prefix: String?
        if let namespaceName {
            guard let optionalPrefix = namespaces.elementPrefix(for: namespaceName) else {
                fatalError("No namespace declaration found for URI \(namespaceName)")
            }
            prefix = optionalPrefix
        } else {
            guard namespaces[nil] == nil else {
                fatalError("Can't use a nil namespace when there's a default namespace in scope")
            }
            prefix = nil
        }

        return String(prefix: prefix, localPart: localName)
    }
}

// For using pending records
internal extension ExpandedName {
    init(effectiveQualifiedAttributeName qName: String, in element: Element) {
        if PendingNameRecord.qualifiedNameIndicatesPending(qName),
           let record = element.pendingNameRecord,
           let pendingExpandedName = record.pendingExpandedAttributeName(for: qName) {
            self = pendingExpandedName
            return
        }

        let namespaceName = element.namespaceName(for: qName.qNamePrefix)
        self.init(namespaceName: namespaceName, localName: qName.qNameLocalName)
    }

    func effectiveQualifiedElementName(for element: Element) -> String {
        let prefix: String?
        if let namespaceName {
            if let match = element.prefix(for: namespaceName) {
                prefix = match == "" ? nil : match
            } else {
                prefix = element.requirePendingNameRecord().addUnresolvedElementName(self, for: element)
            }
        } else {
            guard element.namespaceName(for: nil) == nil else {
                fatalError("Can't use a nil namespace when there's a default namespace in scope")
            }
            prefix = nil
        }

        return String(prefix: prefix, localPart: localName)
    }

    func effectiveQualifiedAttributeName(for element: Element) -> String {
        guard let namespaceName else {
            return localName
        }

        // Reminder: Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default
        guard let prefix = element.prefix(for: namespaceName), prefix != "" else {
            return element.requirePendingNameRecord().addUnresolvedAttribute(self, in: element)
        }
        return String(prefix: prefix, localPart: localName)
    }
}
