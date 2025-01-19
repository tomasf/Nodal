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
