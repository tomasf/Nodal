import Foundation
import pugixml

public extension Element {
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
    func addText(_ text: String, at position: Node.Position = .last) -> Node {
        var textNode = node.addChild(kind: pugi.node_pcdata, at: position)
        textNode.set_value(text)
        return document.object(for: textNode)
    }

    /// Adds a new CDATA node with the specified content to this element at the given position.
    ///
    /// - Parameters:
    ///   - text: The content to include in the CDATA section.
    ///   - position: The position where the CDATA section should be inserted. Defaults to `.last`, adding the CDATA section as the last child of this element.
    /// - Returns: The newly created CDATA node.
    @discardableResult
    func addCDATA(_ text: String, at position: Node.Position = .last) -> Node {
        var cdataNode = node.addChild(kind: pugi.node_cdata, at: position)
        cdataNode.set_value(text)
        return document.object(for: cdataNode)
    }
}
