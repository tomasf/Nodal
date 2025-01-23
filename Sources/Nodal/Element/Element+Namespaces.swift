import Foundation
import pugixml

internal extension Element {
    var pendingNameRecord: PendingNameRecord? {
        document.pendingNameRecord(for: self)
    }

    func requirePendingNameRecord() -> PendingNameRecord {
        if let record = pendingNameRecord {
            return record
        }
        return document.addPendingNameRecord(for: self)
    }

    var explicitNamespacesInScope: NamespaceBindings {
        node.explicitNamespacesInScope
    }

    func prefix(for namespaceName: String) -> String? {
        node.prefix(for: namespaceName)
    }

    func nonDefaultPrefix(for namespaceName: String) -> String? {
        node.nonDefaultPrefix(for: namespaceName)
    }

    func namespaceName(for prefix: String?) -> String? {
        node.namespaceName(for: prefix)
    }
}

public extension Element {
    /// Declares a namespace URI for a given prefix on this element.
    ///
    /// - Parameters:
    ///   - uri: The namespace name (URI) to declare.
    ///   - prefix: The prefix to associate with the namespace. Pass `nil` to declare a default namespace.
    ///
    /// - Note: This adds or updates a `xmlns` attribute for the specified prefix.
    func declareNamespace(_ uri: String, forPrefix prefix: String?) {
        let attributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }
        self[attribute: attributeName] = uri
    }

    /// The namespaces explicitly declared as attributes on this element.
    ///
    /// - Returns: A dictionary where the keys are namespace prefixes (or `nil` for the default namespace),
    ///            and the values are the corresponding namespace names (URIs).
    ///
    /// - Note: Setting this property updates the `xmlns` attributes on the element.
    var declaredNamespaces: NamespaceBindings {
        get {
            Dictionary(attributes.compactMap {
                if $0.name == "xmlns" {
                    return (nil, $0.value)
                } else if $0.name.hasPrefix("xmlns:") {
                    return (String($0.name.dropFirst(6)), $0.value)
                } else {
                    return nil
                }
            }, uniquingKeysWith: { $1 })
        }
        set {
            var attributes = attributes
            attributes.removeAll(where: { $0.name == "xmlns" || $0.name.hasPrefix("xmlns:") })
            attributes.append(contentsOf: newValue.map { prefix, uri in
                let attributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }
                return (attributeName, uri)
            })
            self.attributes = attributes
        }
    }

    /// The namespaces in scope for this element, including explicitly declared and inherited namespaces.
    ///
    /// - Returns: A dictionary where the keys are namespace prefixes (or `nil` for the default namespace),
    ///            and the values are the corresponding namespace names (URIs).
    var namespacesInScope: NamespaceBindings {
        var namespaces = explicitNamespacesInScope
        namespaces[pugi.xml_node.xmlNamespace.prefix] = pugi.xml_node.xmlNamespace.name
        namespaces[pugi.xml_node.xmlnsNamespace.prefix] = pugi.xml_node.xmlnsNamespace.name
        return namespaces
    }

    /// The default namespace name (URI) for this element.
    ///
    /// - Returns: The URI associated with the default namespace (`xmlns`) in this scope, or `nil` if no default namespace is declared.
    var defaultNamespaceName: String? {
        namespaceName(for: nil)
    }

    /// The local name of this element's qualified name, excluding any prefix.
    var localName: String {
        name.qNameLocalName
    }

    /// The prefix of this element's qualified name, or `nil` if no prefix is present.
    var prefix: String? {
        name.qNamePrefix
    }

    /// The expanded name of this element, including its namespace name (URI) and local name.
    ///
    /// - Returns: An `ExpandedName` containing the local name and namespace name.
    var expandedName: ExpandedName {
        get { document.expandedName(for: node) }
        set { name = newValue.requestQualifiedElementName(for: self) }
    }

    /// The names of namespaces that are referenced in this element or its descendants but have not been declared.
    ///
    /// - Returns: A set of undeclared namespace names used within the subtree rooted at this element.
    var undeclaredNamespaceNames: Set<String> {
        Set(document.pendingNameRecords(forDescendantsOf: self).flatMap(\.1.namespaceNames))
    }
}
