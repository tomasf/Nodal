import Foundation
import pugixml

public extension Node {
    /// The child nodes of this node.
    ///
    /// - Returns: An array of `Node` objects representing all child nodes of this node.
    var children: some Sequence<Node> {
        node.children.lazy.map { self.document.node(for: $0) }
    }

    /// Retrieves the child nodes of a specific kind.
    ///
    /// - Parameter kind: The kind of child nodes to retrieve.
    /// - Returns: An array of `Node` objects of the specified kind.
    func children(ofKind kind: Kind) -> some Sequence<Node> {
        let pugiType = kind.pugiType
        return node.children.lazy
            .filter { $0.type() == pugiType }
            .map { self.document.node(for: $0) }
    }

    /// Determines whether this node can contain a child node of the specified kind.
    ///
    /// This method enforces XML structural rules, ensuring that only valid child nodes
    /// can be added to a given node based on its type.
    ///
    /// - Parameter childKind: The kind of node to check.
    /// - Returns: `true` if this node type allows the specified child node type, otherwise `false`.
    ///
    /// - SeeAlso: ``Node.Kind``
    /// 
    func canContainChildren(ofKind childKind: Kind) -> Bool {
        switch childKind {
        case .document:
            false
        case .comment, .element, .processingInstruction:
            kind == .document || kind == .element
        case .text, .cdata:
            kind == .element
        case .declaration, .doctype:
            kind == .document
        }
    }

    /// Adds a new child node of the specified kind to this node at the given position.
    ///
    /// - Parameters:
    ///   - kind: The kind of child node to add (e.g., element, text, comment).
    ///   - position: The position where the new child node should be inserted. Defaults to `.last`, adding the child as the last child of this node.
    /// - Returns: The newly created child node, or `nil` if that kind of child can't be added to this node.
    func addChild(ofKind kind: Kind, at position: Position = .last) -> Node? {
        document.nodeIfValid(node.addChild(kind: kind.pugiType, at: position))
    }

    /// Removes the specified child node from this node.
    ///
    /// - Parameter child: The child node to remove.
    func removeChild(_ child: Node) {
        if child.kind == .element {
            document.removeNamespaceDeclarations(for: child.node)
            document.removePendingNameRecords(withinTree: child)
        }
        var node = node
        node.remove_child(child.node)
    }

    /// Removes all child nodes from this node.
    func removeAllChildren() {
        if kind == .element {
            document.removeNamespaceDeclarations(for: node, excludingTarget: true)
            document.removePendingNameRecords(withinTree: self, excludingTarget: true)
        }
        var node = node
        node.remove_children()
    }
}

public extension Node {
    /// Adds a new text node with the specified content to this element at the given position.
    ///
    /// - Parameters:
    ///   - text: The text content to add as a new text node.
    ///   - position: The position where the text node should be inserted. Defaults to `.last`, adding the text node as the last child of this element.
    /// - Returns: The newly created text node.
    ///
    /// - Example:
    ///   ```swift
    ///   let element: Element = ...
    ///   element.addText("Hello, world!")
    ///   ```
    @discardableResult
    func addText(_ text: String, at position: Position = .last) -> Node {
        precondition(canContainChildren(ofKind: .text), "This kind of node can't contain text")
        var textNode = node.addChild(kind: pugi.node_pcdata, at: position)
        textNode.set_value(text)
        return document.node(for: textNode)
    }

    /// Adds a new CDATA node with the specified content to this element at the given position.
    ///
    /// - Parameters:
    ///   - text: The content to include in the CDATA section.
    ///   - position: The position where the CDATA section should be inserted. Defaults to `.last`, adding the CDATA section as the last child of this element.
    /// - Returns: The newly created CDATA node.
    @discardableResult
    func addCDATA(_ text: String, at position: Position = .last) -> Node {
        precondition(canContainChildren(ofKind: .cdata), "This kind of node can't contain CDATA")
        var cdataNode = node.addChild(kind: pugi.node_cdata, at: position)
        cdataNode.set_value(text)
        return document.node(for: cdataNode)
    }

    /// Adds a new comment with the specified content to this node at the given position.
    ///
    /// - Parameters:
    ///   - text: The content to include in the comment.
    ///   - position: The position where the comment node should be inserted. Defaults to `.last`, adding the comment as the last child of this node.
    /// - Returns: The newly created comment node.
    @discardableResult
    func addComment(_ text: String, at position: Position = .last) -> Node {
        precondition(canContainChildren(ofKind: .comment), "This kind of node can't contain comments")
        var commentNode = node.addChild(kind: pugi.node_comment, at: position)
        commentNode.set_value(text)
        return document.node(for: commentNode)
    }
}
