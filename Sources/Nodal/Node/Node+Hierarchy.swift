import Foundation
import pugixml
import Bridge

internal extension Node {
    func childNodes(ofType targetType: pugi.xml_node_type = pugi.node_null) -> [pugi.xml_node] {
        childNodes.filter { targetType == pugi.node_null || $0.type() == targetType }
    }

    func traverse(_ function: @escaping (pugi.xml_node, Int) -> Bool) {
        xml_node_walk_block(&node) { function($0, Int($1)) }
    }
}

public extension Node {
    /// The parent node of this node, or `nil` if this node has no parent.
    var parent: Node? {
        document.objectIfValid(node.parent())
    }

    /// The child nodes of this node.
    ///
    /// - Returns: An array of `Node` objects representing all child nodes of this node.
    var children: [Node] {
        childNodes().map { document.object(for: $0) }
    }

    /// Retrieves the child nodes of a specific kind.
    ///
    /// - Parameter kind: The kind of child nodes to retrieve.
    /// - Returns: An array of `Node` objects of the specified kind.
    func children(ofKind kind: Kind) -> [Node] {
        childNodes(ofType: kind.pugiType).map {
            document.object(for: $0)
        }
    }


    /// The previous sibling of this node, or `nil` if this node has no previous sibling.
    ///
    /// - Note: A sibling is another node with the same parent as this node, appearing immediately before it in the parent's child list.
    var previousSibling: Node? {
        document.objectIfValid(node.previous_sibling())
    }

    /// The next sibling of this node, or `nil` if this node has no next sibling.
    ///
    /// - Note: A sibling is another node with the same parent as this node, appearing immediately after it in the parent's child list.
    var nextSibling: Node? {
        document.objectIfValid(node.next_sibling())
    }

    /// Traverses the entire subtree within this node, invoking a callback function for each node.
    ///
    /// - Parameter function: A closure that is called for each node. The closure takes two parameters:
    ///   - node: The current `Node` being traversed.
    ///   - level: The depth level of the current node relative to the starting node.
    ///   Return `true` from the closure to continue traversal, or `false` to stop.
    ///
    /// - Note: The traversal order is determined by the underlying XML structure.
    func traverseTree(_ function: @escaping (Node, _ level: Int) -> Bool) {
        traverse { function(self.document.object(for: $0), $1) }
    }

    /// Determines whether this node is a descendant of the specified ancestor node.
    ///
    /// - Parameter ancestor: The potential ancestor node.
    /// - Returns: `true` if this node is a descendant of the specified ancestor or if this node is the same as the ancestor, otherwise `false`.
    func isDescendant(of ancestor: Node) -> Bool {
        var node = self.node
        while !node.empty() {
            if node == ancestor.node {
                return true
            }
            node = node.parent()
        }
        return false
    }
}

public extension Node {
    /// Adds a new child node of the specified kind to this node.
    ///
    /// - Parameter kind: The kind of child node to add.
    /// - Returns: The newly created child node, or `nil` if that kind of child can't be added to this node.
    func addChild(ofKind kind: Kind) -> Node? {
        document.objectIfValid(node.append_child(kind.pugiType))
    }

    /// Removes the specified child node from this node.
    ///
    /// - Parameter child: The child node to remove.
    func removeChild(_ child: Node) {
        if let element = child as? Element {
            document.removePendingNameRecords(withinTree: element)
            document.sendNoteDeletionNotification(for: [element.node])
        }
        node.remove_child(child.node)
    }

    /// Removes all child nodes from this node.
    func removeAllChildren() {
        if let element = self as? Element {
            document.removePendingNameRecords(withinTree: element, excludingTarget: true)
            document.sendNoteDeletionNotification(for: Set(children.map(\.node)))
        }
        node.remove_children()
    }
}
