import Foundation
import pugixml

internal extension Document {
    // Get an Element object for an element node
    func element(for node: pugi.xml_node) -> Element {
        Element(owningDocument: self, node: node)
    }

    // This gets a Node object for any node. Non-element objects are not reused.
    func object(for node: pugi.xml_node) -> Node {
        assert(node.empty() == false)
        if node.type() == pugi.node_element {
            return element(for: node)
        } else {
            return Node(owningDocument: self, node: node)
        }
    }

    func objectIfValid(_ node: pugi.xml_node) -> Node? {
        node.empty() ? nil : object(for: node)
    }

    static let deletedNodesUserInfoKey = "Nodal.DeletedNodes"

    // Ideally, we'd use the object parameter on NotificationCenter to filter on document,
    // but swift-corelibs-foundation seems to require that the class inherits from NSObject
    // for that to work, so we use this as a workaround.
    static let documentUserInfoKey = "Nodal.Document"

    func sendNoteDeletionNotification(for nodes: Set<pugi.xml_node>) {
        NotificationCenter.default.post(name: .documentDidDeleteNodes, object: self, userInfo: [
            Self.deletedNodesUserInfoKey: nodes,
            Self.documentUserInfoKey: self
        ])
    }
}

internal extension Notification.Name {
    static let documentDidDeleteNodes = Notification.Name("Nodal.Document.didDeleteNodes")
}
