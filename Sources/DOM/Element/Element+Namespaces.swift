import Foundation
import pugixml

public extension Element {
    // Namespaces declared as attributes on this element
    var declaredNamespaces: [String?: String] {
        get {
            Dictionary(qualifiedAttributes.compactMap {
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
            var attributes = qualifiedAttributes
            attributes.removeAll(where: { $0.name == "xmlns" || $0.name.hasPrefix("xmlns:") })
            attributes.append(contentsOf: newValue.map { prefix, uri in
                let attributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }
                return (attributeName, uri)
            })
            self.qualifiedAttributes = attributes
        }
    }

    // Declare a namespace URI for a given prefix. Pass nil for prefix to declare a default namespace.
    func declareNamespace(_ uri: String, for prefix: String?) {
        let attributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }
        self[attribute: attributeName] = uri
    }

    private static let fixedNamespaces: [String?: String] = [
        "xml": "http://www.w3.org/XML/1998/namespace",
        "xmlns": "http://www.w3.org/2000/xmlns/"
    ]

    internal var explicitNamespacesInScope: [String?: String] {
        var namespaces = parentElement?.explicitNamespacesInScope ?? [:]

        for pugiAttribute in nodeAttributes {
            let name = String(cString: pugiAttribute.name())
            if name == "xmlns" {
                namespaces[nil] = String(cString: pugiAttribute.value())
            } else if name.hasPrefix("xmlns:") {
                let prefix = String(name.dropFirst(6))
                namespaces[prefix] = String(cString: pugiAttribute.value())
            }
        }

        return namespaces
    }

    var namespacesInScope: [String?: String] {
        if let cachedNamespacesInScope {
            return cachedNamespacesInScope
        }

        var namespaces = explicitNamespacesInScope
        for (key, value) in Self.fixedNamespaces {
            namespaces[key] = value
        }

        cachedNamespacesInScope = namespaces
        return namespaces
    }

    /*
    internal func namespacesInScope(parentNamespaces: [String?: String]) -> [String?: String] {
        var namespaces: [String?: String] = [:]
        addDeclaredNamespaces(to: &namespaces)
        for (key, value) in parentNamespaces {
            if namespaces[key] == nil {
                namespaces[key] = value
            }
        }
        return namespaces
    }
     */

    var defaultNamespaceURI: String? {
        namespacesInScope[nil]
    }

    var localName: String {
        name.qNameLocalName
    }

    var prefix: String? {
        name.qNamePrefix
    }

    var namespaceURI: String? {
        namespacesInScope[prefix]
    }

    var expandedName: ExpandedName {
        get { ExpandedName(uri: namespaceURI, localName: localName) }
        set { name = newValue.qualifiedElementName(using: namespacesInScope) }
    }
}
