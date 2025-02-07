import Foundation
import pugixml
import Bridge

public extension Node {
    /// The parent node of this node, or `nil` if this node has no parent.
    var parent: (any Node)? {
        document.objectIfValid(node.parent())
    }

    /// The child nodes of this node.
    ///
    /// - Returns: An array of `Node` objects representing all child nodes of this node.
    var children: some Sequence<any Node> {
        node.children.lazy.map { self.document.object(for: $0) }
    }

    /// Retrieves the child nodes of a specific kind.
    ///
    /// - Parameter kind: The kind of child nodes to retrieve.
    /// - Returns: An array of `Node` objects of the specified kind.
    func children(ofKind kind: NodeKind) -> some Sequence<any Node> {
        let pugiType = kind.pugiType
        return node.children.lazy
            .filter { $0.type() == pugiType }
            .map { self.document.object(for: $0) }
    }

    /// A sequence that traverses all descendant nodes of this node in depth-first order, including the node itself.
    ///
    /// - Important: Avoid making changes to the tree while traversing to prevent unexpected results.
    ///
    /// - Returns: A `NodeDescendants` sequence that iterates over all nodes in the tree, starting with this node.
    var descendants: some Sequence<any Node> {
        DescendantSequence(target: self.node).lazy.map { node in
            self.document.object(for: node)
        }
    }

    /// The previous sibling of this node, or `nil` if this node has no previous sibling.
    ///
    /// - Note: A sibling is another node with the same parent as this node, appearing immediately before it in the parent's child list.
    var previousSibling: (any Node)? {
        document.objectIfValid(node.previous_sibling())
    }

    /// The next sibling of this node, or `nil` if this node has no next sibling.
    ///
    /// - Note: A sibling is another node with the same parent as this node, appearing immediately after it in the parent's child list.
    var nextSibling: (any Node)? {
        document.objectIfValid(node.next_sibling())
    }

    /// Determines whether this node is a descendant of the specified ancestor node.
    ///
    /// - Parameter ancestor: The potential ancestor node.
    /// - Returns: `true` if this node is a descendant of the specified ancestor or if this node is the same as the ancestor, otherwise `false`.
    func isDescendant(of ancestor: any Node) -> Bool {
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
    /// Adds a new child node of the specified kind to this node at the given position.
    ///
    /// - Parameters:
    ///   - kind: The kind of child node to add (e.g., element, text, comment).
    ///   - position: The position where the new child node should be inserted. Defaults to `.last`, adding the child as the last child of this node.
    /// - Returns: The newly created child node, or `nil` if that kind of child can't be added to this node.
    func addChild(ofKind kind: NodeKind, at position: ChildPosition = .last) -> (any Node)? {
        document.objectIfValid(node.addChild(kind: kind.pugiType, at: position))
    }

    /// Removes the specified child node from this node.
    ///
    /// - Parameter child: The child node to remove.
    func removeChild(_ child: any Node) {
        if let element = child as? Element {
            document.removeNamespaceDeclarations(for: child.node)
            document.removePendingNameRecords(withinTree: element)
        }
        var node = node
        node.remove_child(child.node)
    }

    /// Removes all child nodes from this node.
    func removeAllChildren() {
        if let element = self as? Element {
            document.removeNamespaceDeclarations(for: element.node, excludingTarget: true)
            document.removePendingNameRecords(withinTree: element, excludingTarget: true)
        }
        var node = node
        node.remove_children()
    }
}

public extension Node {
    /// Moves this node to a new parent node at the specified position within the parent's children.
    ///
    /// - Parameters:
    ///   - parent: The new parent node to which this node should be moved.
    ///   - position: The position within the parent's children where this node should be inserted. Defaults to `.last`, adding the node as the last child of the parent.
    /// - Returns: A Boolean value indicating whether the move was successful.
    ///            Returns `false` if the node cannot be moved. Examples of such cases include:
    ///            - The new parent node belongs to a different document.
    ///            - The node is being moved to within itself, which would create an invalid structure.
    @discardableResult
    func move(to parent: any Node, at position: ChildPosition = .last) -> Bool {
        let records = document.pendingNameRecords(forDescendantsOf: self)
        var destination = parent.node

        if destination.insertChild(self.node, at: position).empty() {
            return false
        }

        for (node, record) in records {
            record.updateAncestors(with: node)
        }
        return true
    }
}

public extension Node {
    /// Adds a new comment with the specified content to this node at the given position.
    ///
    /// - Parameters:
    ///   - text: The content to include in the comment.
    ///   - position: The position where the comment node should be inserted. Defaults to `.last`, adding the comment as the last child of this node.
    /// - Returns: The newly created comment node.
    @discardableResult
    func addComment(_ text: String, at position: ChildPosition = .last) -> any Node {
        var commentNode = node.addChild(kind: pugi.node_comment, at: position)
        commentNode.set_value(text)
        return document.object(for: commentNode)
    }

    /// Concatenates the values of all descendant text and CDATA nodes of this node.
    ///
    /// - Returns: A single string containing the concatenated text of all descendant nodes of type `.text` or `.cdata`.
    var textContent: String {
        node.descendants
            .filter { $0.type() == pugi.node_pcdata || $0.type() == pugi.node_cdata }
            .map { String(cString: $0.value()) }
            .joined()
    }
}

/// Specifies the position at which a new child node should be added relative to existing children.
public enum ChildPosition {
    /// The new child is added as the first child of the parent node.
    case first

    /// The new child is added immediately before the specified sibling node.
    case before(any Node)

    /// The new child is added immediately after the specified sibling node.
    case after(any Node)

    /// The new child is added as the last child of the parent node.
    case last

    internal func validate(for parent: pugi.xml_node) -> Bool {
        switch self {
        case .first, .last: true
        case .before (let node): node.parent?.node == parent
        case .after (let node): node.parent?.node == parent
        }
    }
}
