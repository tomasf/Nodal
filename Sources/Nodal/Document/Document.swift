import Foundation
import pugixml
import Bridge

/// Represents an XML document node, providing methods for working with the document structure and serialization.
public class Document {
    internal var pugiDocument = pugi.xml_document()
    internal var pendingNamespaceRecords: [OpaquePointer: PendingNameRecord] = [:]
    internal var namespaceDeclarationsByPrefix: [NamespaceDeclaration.Prefix: [NamespaceDeclaration]] = [:]
    internal var namespaceDeclarationsByName: [String: [NamespaceDeclaration]] = [:]

    /// Creates a new, empty XML document.
    ///
    /// - Note: This initializer creates a document with no content.
    public init() {}

    /// The root node of the document.
    ///
    /// This property provides access to the underlying document node, which represents
    /// the entire XML document. This node is always of type ``Node/Kind/document``.
    public var node: Node {
        node(for: pugiDocument.asNode)
    }
}

internal extension Document {
    // Create a Nodal Node for a pugi node
    func node(for pugiNode: pugi.xml_node) -> Node {
        assert(pugiNode.empty() == false)
        return Node(document: self, node: pugiNode)
    }

    func nodeIfValid(_ pugiNode: pugi.xml_node) -> Node? {
        pugiNode.empty() ? nil : node(for: pugiNode)
    }
}
