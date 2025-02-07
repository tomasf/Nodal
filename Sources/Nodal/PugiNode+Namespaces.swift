import Foundation
import pugixml

internal extension pugi.xml_node {
    var explicitNamespacesInScope: [String?: String] {
        var namespaces: [String?: String] = [:]

        for attribute in ancestorAttributes {
            let name = attribute.name()!
            guard strncmp(name, "xmlns", 5) == 0 else { continue }
            let (prefix, localName) = name.qualifiedNameParts

            let namespacePrefix = (prefix == nil) ? nil : localName
            if namespaces[namespacePrefix] == nil {
                namespaces[namespacePrefix] = String(cString: attribute.value())
            }
        }

        return namespaces
    }
}
