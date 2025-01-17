import Foundation
import pugixml

internal extension Document {
    // Associate an Element object with an element node
    func setElementObject(_ element: Element, forNode node: pugi.xml_node) {
        NSMapInsert(
            objectDirectory,
            UnsafeRawPointer(node.internal_object()),
            UnsafeRawPointer(Unmanaged.passUnretained(element).toOpaque())
        )
    }

    // Fetches any already existing Element object for a given element node
    func existingElementObject(forNode node: pugi.xml_node) -> Element? {
        //print("Getting object. Count: \(objectDirectory.count)")
        guard let pointer = NSMapGet(objectDirectory, UnsafeRawPointer(node.internal_object())) else {
            return nil
        }
        return Unmanaged<Element>.fromOpaque(pointer).takeUnretainedValue()
    }

    // Create a new Element object for a given node
    // This can be used directly for newly created nodes, to avoid checking the map table first
    func createElementObject(forNode node: pugi.xml_node) -> Element {
        let new = Element(document: self, node: node)
        setElementObject(new, forNode: node)
        //print("Created object. Count: \(objectDirectory.count)")
        return new
    }

    // Get an Element object for an element node
    // This returns an existing object if one exists; otherwise creates one
    func element(for node: pugi.xml_node) -> Element {
        if let existing = existingElementObject(forNode: node) {
            return existing
        } else {
            return createElementObject(forNode: node)
        }
    }

    // This gets a Node object for any node. Non-element objects are not reused.
    func object(for node: pugi.xml_node) -> Node {
        assert(node.empty() == false)
        if node.type() == pugi.node_element {
            return element(for: node)
        } else {
            return Node(document: self, node: node)
        }
    }
}
