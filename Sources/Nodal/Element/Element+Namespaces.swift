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

    static let fixedNamespaces: NamespaceBindings = [
        "xml": "http://www.w3.org/XML/1998/namespace",
        "xmlns": "http://www.w3.org/2000/xmlns/"
    ]

    var explicitNamespacesInScope: NamespaceBindings {
        var namespaces: NamespaceBindings = [:]
        var node: pugi.xml_node = self.node
        while !node.empty() {
            var attribute = node.first_attribute()
            while !attribute.empty() {
                let name = String(cString: attribute.name())
                if name.hasPrefix("xmlns") {
                    let prefix = name == "xmlns" ? nil : name.qNameLocalName
                    if namespaces[prefix] == nil {
                        namespaces[prefix] = String(cString: attribute.value())
                    }
                }
                attribute = attribute.next_attribute()
            }
            node = node.parent()
        }
        return namespaces
    }

    func prefix(for namespaceName: String) -> String? {
        if namespaceName == "http://www.w3.org/XML/1998/namespace" { return "xml" }
        if namespaceName == "http://www.w3.org/2000/xmlns/" { return "xmlns" }

        var node: pugi.xml_node = self.node
        while !node.empty() {
            var attribute = node.first_attribute()
            while !attribute.empty() {
                let name = String(cString: attribute.name())
                if name.hasPrefix("xmlns"), String(cString: attribute.value()) == namespaceName {
                    return name.count == 5 ? "" : name.qNameLocalName
                }
                attribute = attribute.next_attribute()
            }
            node = node.parent()
        }
        return nil
    }

    func nonDefaultPrefix(for namespaceName: String) -> String? {
        if namespaceName == "http://www.w3.org/XML/1998/namespace" { return "xml" }
        if namespaceName == "http://www.w3.org/2000/xmlns/" { return "xmlns" }

        var node: pugi.xml_node = self.node
        while !node.empty() {
            var attribute = node.first_attribute()
            while !attribute.empty() {
                let name = String(cString: attribute.name())
                if name.hasPrefix("xmlns:"), String(cString: attribute.value()) == namespaceName {
                    return name.qNameLocalName
                }
                attribute = attribute.next_attribute()
            }
            node = node.parent()
        }
        return nil
    }

    func namespaceName(for prefix: String?) -> String? {
        if prefix == "xml" { return "http://www.w3.org/XML/1998/namespace" }
        if prefix == "xmlns" { return "http://www.w3.org/2000/xmlns/" }

        let targetAttributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }
        var node: pugi.xml_node = self.node
        while !node.empty() {
            var attribute = node.first_attribute()
            while !attribute.empty() {
                if String(cString: attribute.name()) == targetAttributeName {
                    return String(cString: attribute.value())
                }
                attribute = attribute.next_attribute()
            }
            node = node.parent()
        }
        return nil
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
        for (key, value) in Self.fixedNamespaces {
            namespaces[key] = value
        }
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

    /// The namespace name (URI) associated with this element's prefix.
    ///
    /// - Returns: The namespace URI for the prefix, or `nil` if the prefix is not bound to a namespace.
    var namespaceName: String? {
        namespaceName(for: prefix)
    }

    /// The expanded name of this element, including its namespace name (URI) and local name.
    ///
    /// - Returns: An `ExpandedName` containing the local name and namespace name.
    var expandedName: ExpandedName {
        get {
            if PendingNameRecord.qualifiedNameIndicatesPending(name), let record = pendingNameRecord, let name = record.elementName {
                return name
            } else {
                return ExpandedName(namespaceName: namespaceName, localName: localName)
            }
        }
        set {
            name = newValue.effectiveQualifiedElementName(for: self)
        }
    }

    /// The names of namespaces that are referenced in this element or its descendants but have not been declared.
    ///
    /// - Returns: A set of undeclared namespace names used within the subtree rooted at this element.
    var undeclaredNamespaceNames: Set<String> {
        Set(document.pendingNameRecords(forDescendantsOf: self).flatMap(\.1.namespaceNames))
    }
}
