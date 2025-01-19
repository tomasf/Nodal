import Foundation

public struct ExpandedName: Hashable, Sendable {
    public let namespaceName: String?
    public let localName: String

    public init(namespaceName uri: String?, localName: String) {
        self.namespaceName = uri
        self.localName = localName
    }
}

internal extension ExpandedName {
    // Returns nil if the namespace could not be resolved
    func qualifiedAttributeName(using namespaces: NamespaceBindings) -> String? {
        guard let namespaceName else {
            return localName
        }

        // Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default
        guard let prefix = namespaces.first(where: { $0.value == namespaceName && $0.key != nil })?.key else {
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
    init(effectiveQualifiedAttributeName qName: String, in element: Element, using namespaces: NamespaceBindings) {
        if PendingNameRecord.qualifiedNameIndicatesPending(qName),
        let record = element.pendingNameRecord,
        let pendingExpandedName = record.pendingExpandedAttributeName(for: qName) {
            self = pendingExpandedName
            return
        }

        self.init(namespaceName: namespaces[qName.qNamePrefix], localName: qName.qNameLocalName)
    }

    func effectiveQualifiedElementName(for element: Element, using namespaces: NamespaceBindings) -> String {
        let prefix: String?
        if let namespaceName {
            if let match = namespaces.elementPrefix(for: namespaceName) {
                prefix = match
            } else {
                prefix = element.requirePendingNameRecord().addUnresolvedElementName(self, for: element)
            }
        } else {
            guard namespaces[nil] == nil else {
                fatalError("Can't use a nil namespace when there's a default namespace in scope")
            }
            prefix = nil
        }

        return String(prefix: prefix, localPart: localName)
    }

    func effectiveQualifiedAttributeName(for element: Element, using namespaces: NamespaceBindings) -> String {
        guard let namespaceName else {
            return localName
        }

        // Reminder: Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default
        guard let prefix = namespaces.attributePrefix(for: namespaceName) else {
            return element.requirePendingNameRecord().addUnresolvedAttribute(self, in: element)
        }
        return String(prefix: prefix, localPart: localName)
    }

}

public typealias NamespaceBindings = [String?: String]

internal extension NamespaceBindings {
    func elementPrefix(for namespaceName: String) -> String?? {
        if self[nil] == namespaceName {
            return nil as String?
        }
        return first(where: { $0.value == namespaceName })?.key
    }

    func attributePrefix(for namespaceName: String) -> String? {
        first(where: { $0.key != nil && $0.value == namespaceName })?.key
    }

    var nameToPrefixMapping: [String: String?] {
        [String: String?](map { ($1, $0) })  { $0 == nil || $1 == nil ? nil as String? : $0 }
    }
}
