import Foundation
import pugixml

/// Represents an XML element node in the document tree.
///
/// - Note: This class provides functionality for working with XML elements, including accessing their attributes,
///         child nodes, and text content. It extends the `Node` class, inheriting its methods and properties.
public struct Element: Node {
    public let document: Document
    public let node: pugi.xml_node

    internal init(owningDocument: Document, node: pugi.xml_node) {
        self.document = owningDocument
        self.node = node
    }

    internal var hasNamespaceDeclarations: Bool {
        node.attributes.contains(where: {
            String(cString: $0.name()).hasPrefix("xmlns")
        })
    }

    public static func ==(lhs: Element, rhs: Element) -> Bool {
        lhs.node == rhs.node
    }
}
