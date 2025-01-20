import Foundation
import pugixml

public extension Element {
    /// Appends a new text node with the specified content to the element.
    ///
    /// - Parameter text: The text content to add as a new text node.
    /// - Returns: The newly created text node.
    ///
    /// - Note: This method adds a node of type `.text` containing the given text.
    ///
    /// - Example:
    ///   ```swift
    ///   let element: Element = ...
    ///   element.appendText("Hello, world!")
    ///   ```
    @discardableResult
    func appendText(_ text: String) -> Node {
        var textNode = node.append_child(pugi.node_pcdata)
        textNode.set_value(text)
        return document.object(for: textNode)
    }

    /// Appends a new CDATA section with the specified content to the element.
    ///
    /// - Parameter text: The content to include in the CDATA section.
    /// - Returns: The newly created CDATA node.
    ///
    /// - Note: This method adds a node of type `.cdata` containing the given content.
    @discardableResult
    func appendCDATA(_ text: String) -> Node {
        var cdataNode = node.append_child(pugi.node_cdata)
        cdataNode.set_value(text)
        return document.object(for: cdataNode)
    }

    /// Appends a new comment with the specified content to the element.
    ///
    /// - Parameter text: The content to include in the comment.
    /// - Returns: The newly created comment node.
    ///
    /// - Note: This method adds a node of type `.comment` containing the given content.
    @discardableResult
    func appendComment(_ text: String) -> Node {
        var commentNode = node.append_child(pugi.node_comment)
        commentNode.set_value(text)
        return document.object(for: commentNode)
    }
}
