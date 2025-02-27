import Foundation
import pugixml
import Bridge

public extension Node {
    /// The parent node of this node, or `nil` if this node has no parent.
    var parent: Node? {
        document.nodeIfValid(node.parent())
    }

    /// A sequence that traverses all descendant nodes of this node in depth-first order, including the node itself.
    ///
    /// - Important: Avoid making changes to the tree while traversing to prevent unexpected results.
    ///
    /// - Returns: A `NodeDescendants` sequence that iterates over all nodes in the tree, starting with this node.
    var descendants: some Sequence<Node> {
        DescendantSequence(target: self.node).lazy.map { node in
            self.document.node(for: node)
        }
    }

    /// The previous sibling of this node, or `nil` if this node has no previous sibling.
    ///
    /// - Note: A sibling is another node with the same parent as this node, appearing immediately before it in the parent's child list.
    var previousSibling: Node? {
        document.nodeIfValid(node.previous_sibling())
    }

    /// The next sibling of this node, or `nil` if this node has no next sibling.
    ///
    /// - Note: A sibling is another node with the same parent as this node, appearing immediately after it in the parent's child list.
    var nextSibling: Node? {
        document.nodeIfValid(node.next_sibling())
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

    /// Gets or sets the concatenated text content of this node and all its descendant text and CDATA nodes.
    ///
    /// - Getter: Returns a single string containing the concatenated text of all descendant nodes of type `.text` or `.cdata`.
    /// - Setter: Replaces all existing children of this node with a single text node containing the new value.
    ///   - If the node type cannot contain text, a precondition failure occurs.
    ///
    /// Example:
    /// ```xml
    /// <person>
    ///     <name>John</name>
    ///     <age>30</age>
    /// </person>
    /// ```
    ///
    /// ```swift
    /// let name = personNode.textContent // "John30"
    /// personNode.textContent = "New Value" // Replaces all children with a single text node
    /// ```
    ///
    /// - Precondition: The node must be capable of containing text.
    var textContent: String {
        get {
            node.descendants
                .filter { $0.type() == pugi.node_pcdata || $0.type() == pugi.node_cdata }
                .map { String(cString: $0.value()) }
                .joined()
        }
        nonmutating set {
            precondition(canContainChildren(ofKind: .text), "This kind of node can't contain text")
            removeAllChildren()
            addText(newValue)
        }
    }
}

public extension Node {
    /// Specifies the position at which a new child node should be added relative to existing children.
    enum Position {
        /// The new child is added as the first child of the parent node.
        case first

        /// The new child is added immediately before the specified sibling node.
        case before(Node)

        /// The new child is added immediately after the specified sibling node.
        case after(Node)

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
}
