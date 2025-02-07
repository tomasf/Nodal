import Foundation
import pugixml

internal extension Document {
    // Get an Element for an element node
    func element(for node: pugi.xml_node) -> Element {
        Element(owningDocument: self, node: node)
    }

    // This gets a Nodal Node for any pugi node
    func object(for node: pugi.xml_node) -> any Node {
        assert(node.empty() == false)
        if node.type() == pugi.node_element {
            return element(for: node)
        } else if node == self.node {
            return self
        } else {
            return GenericNode(owningDocument: self, node: node)
        }
    }

    func objectIfValid(_ node: pugi.xml_node) -> (any Node)? {
        node.empty() ? nil : object(for: node)
    }
}
