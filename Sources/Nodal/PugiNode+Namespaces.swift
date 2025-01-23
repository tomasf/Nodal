import Foundation
import pugixml

internal extension pugi.xml_node {
    static let xmlNamespace = (prefix: "xml", name: "http://www.w3.org/XML/1998/namespace")
    static let xmlnsNamespace = (prefix: "xmlns", name: "http://www.w3.org/2000/xmlns/")


    func namespaceName(for prefix: String?) -> String? {
        if prefix == Self.xmlNamespace.prefix { return Self.xmlNamespace.name }
        if prefix == Self.xmlnsNamespace.prefix { return Self.xmlnsNamespace.name }

        let targetAttributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }

        for attribute in ancestorAttributes {
            if String(cString: attribute.name()) == targetAttributeName {
                return String(cString: attribute.value())
            }
        }
        return nil
    }

    func nonDefaultPrefix(for namespaceName: String) -> String? {
        if namespaceName == Self.xmlNamespace.name { return Self.xmlNamespace.prefix }
        if namespaceName == Self.xmlnsNamespace.name { return Self.xmlnsNamespace.prefix }

        for attribute in ancestorAttributes {
            let name = String(cString: attribute.name())
            if name.hasPrefix("xmlns:"), String(cString: attribute.value()) == namespaceName {
                return name.qNameLocalName
            }
        }
        return nil
    }

    func prefix(for namespaceName: String) -> String? {
        if namespaceName == Self.xmlNamespace.name { return Self.xmlNamespace.prefix }
        if namespaceName == Self.xmlnsNamespace.name { return Self.xmlnsNamespace.prefix }

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
