import Foundation
internal import pugixml
internal import Bridge

/// Represents an XML document node, providing methods for working with the document structure and serialization.
public class Document {
    internal var pugiDocument = pugi.xml_document()
    internal var pendingNamespaceRecords: [OpaquePointer: PendingNameRecord] = [:]
    internal var namespaceDeclarationsByPrefix: [NamespaceDeclaration.Prefix: [NamespaceDeclaration]] = [:]
    internal var namespaceDeclarationsByName: [String: [NamespaceDeclaration]] = [:]

    /// The format used for encoding and decoding `Date` values.
    ///
    /// This property affects how `Date` values are serialized to and from XML
    /// when using methods like `value(forAttribute:)`, `setValue(_:forAttribute:)`,
    /// `content()`, and `setContent()` on nodes belonging to this document.
    ///
    /// The default value is ``XMLDateFormat/iso8601``.
    public var dateFormat: XMLDateFormat = .iso8601

    /// The format used for encoding and decoding `Data` values.
    ///
    /// This property affects how binary data is serialized to and from XML
    /// when using methods like `value(forAttribute:)`, `setValue(_:forAttribute:)`,
    /// `content()`, and `setContent()` on nodes belonging to this document.
    ///
    /// The default value is ``XMLDataFormat/base64``.
    public var dataFormat: XMLDataFormat = .base64

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

extension Document: CustomDebugStringConvertible {
    public var debugDescription: String {
        let pointer = String(format: "%p", Int(bitPattern: pugiDocument.asNode.internal_object()))
        var parts: [String] = []

        for child in node.children {
            switch child.kind {
            case .declaration, .doctype, .element:
                parts.append(child.debugContent)
            case .comment:
                parts.append("<!--...-->")
            case .processingInstruction:
                parts.append("<?\(child.name)...?>")
            default:
                break
            }
        }

        if parts.isEmpty {
            return "Document \(pointer): (empty)"
        }
        return "Document \(pointer): \(parts.joined(separator: " "))"
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
