import Foundation
import pugixml

internal extension pugi.xml_node {
    var explicitNamespacesInScope: [String?: String] {
        var namespaces: [String?: String] = [:]

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
