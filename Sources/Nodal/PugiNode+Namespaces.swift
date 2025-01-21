import Foundation
import pugixml

internal extension pugi.xml_node {
    static let xmlNamespaceName = "http://www.w3.org/XML/1998/namespace"
    static let xmlNamespacePrefix = "xml"
    static let nsNamespaceName = "http://www.w3.org/2000/xmlns/"
    static let nsNamespacePrefix = "xmlns"

    func namespaceName(for prefix: String?) -> String? {
        if prefix == Self.xmlNamespacePrefix { return Self.xmlNamespaceName }
        if prefix == Self.nsNamespacePrefix { return Self.nsNamespaceName }

        let targetAttributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }

        for attribute in ancestorAttributes {
            if String(cString: attribute.name()) == targetAttributeName {
                return String(cString: attribute.value())
            }
        }
        return nil
    }

    func nonDefaultPrefix(for namespaceName: String) -> String? {
        if namespaceName == Self.xmlNamespaceName { return Self.xmlNamespacePrefix }
        if namespaceName == Self.nsNamespaceName { return Self.nsNamespacePrefix }

        for attribute in ancestorAttributes {
            let name = String(cString: attribute.name())
            if name.hasPrefix("xmlns:"), String(cString: attribute.value()) == namespaceName {
                return name.qNameLocalName
            }
        }
        return nil
    }

    func prefix(for namespaceName: String) -> String? {
        if namespaceName == Self.xmlNamespaceName { return Self.xmlNamespacePrefix }
        if namespaceName == Self.nsNamespaceName { return Self.nsNamespacePrefix }

        for attribute in ancestorAttributes {
            let name = String(cString: attribute.name())
            if name.hasPrefix("xmlns"), String(cString: attribute.value()) == namespaceName {
                return name.count == 5 ? "" : name.qNameLocalName
            }
        }
        return nil
    }

    var explicitNamespacesInScope: NamespaceBindings {
        var namespaces: NamespaceBindings = [:]

        for attribute in ancestorAttributes {
            let name = String(cString: attribute.name())
            if name.hasPrefix("xmlns") {
                let prefix = name == "xmlns" ? nil : name.qNameLocalName
                if namespaces[prefix] == nil {
                    namespaces[prefix] = String(cString: attribute.value())
                }
            }
        }

        return namespaces
    }
}
