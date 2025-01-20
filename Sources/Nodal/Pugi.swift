import pugixml
import Bridge

extension pugi.xml_node_type: Hashable {}
extension pugi.xml_node: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(internal_object())
    }

    var nonNull: pugi.xml_node? {
        empty() ? nil : self
    }
}

internal extension pugi.xml_document {
    var asNode: pugi.xml_node { xml_document_as_node(self) }
}

internal extension pugi.xpath_node_set {
    var nodes: [pugi.xpath_node] {
        (0..<size()).map { self[$0] }
    }
}

internal extension pugi.xml_node {
    func namespaceName(for prefix: String?) -> String? {
        if prefix == "xml" { return "http://www.w3.org/XML/1998/namespace" }
        if prefix == "xmlns" { return "http://www.w3.org/2000/xmlns/" }

        let targetAttributeName = if let prefix { "xmlns:" + prefix } else { "xmlns" }

        for attribute in ancestorAttributes {
            if String(cString: attribute.name()) == targetAttributeName {
                return String(cString: attribute.value())
            }
        }
        return nil
    }

    func nonDefaultPrefix(for namespaceName: String) -> String? {
        if namespaceName == "http://www.w3.org/XML/1998/namespace" { return "xml" }
        if namespaceName == "http://www.w3.org/2000/xmlns/" { return "xmlns" }

        for attribute in ancestorAttributes {
            let name = String(cString: attribute.name())
            if name.hasPrefix("xmlns:"), String(cString: attribute.value()) == namespaceName {
                return name.qNameLocalName
            }
        }
        return nil
    }

    func prefix(for namespaceName: String) -> String? {
        if namespaceName == "http://www.w3.org/XML/1998/namespace" { return "xml" }
        if namespaceName == "http://www.w3.org/2000/xmlns/" { return "xmlns" }

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
