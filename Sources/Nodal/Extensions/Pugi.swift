import pugixml
import Bridge
import Foundation

extension pugi.xml_node_type: Hashable {}

extension pugi.xml_attribute {
    var nonNull: pugi.xml_attribute? {
        empty() ? nil : self
    }
}

internal extension pugi.xml_document {
    var asNode: pugi.xml_node { xml_document_as_node(self) }
    var documentElement: pugi.xml_node {
        __document_elementUnsafe()
    }
}

internal extension pugi.xpath_node_set {
    var nodes: [pugi.xpath_node] {
        (0..<size()).map { self[$0] }
    }
}
