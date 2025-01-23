import Foundation
import pugixml
import Bridge

/// Represents a node in an XML document.
///
/// - Note: This class is the base for all types of XML nodes, including elements, text, comments, and more.
///         It provides common functionality for working with nodes, such as retrieving their name, value, and
///         serialized XML representation.
public class Node {
    private let owningDocument: Document?
    internal var node: pugi.xml_node
    private var notificationToken: Any?

    internal init(owningDocument: Document?, node: pugi.xml_node) {
        self.owningDocument = owningDocument
        self.node = node

        struct NodeBox: @unchecked Sendable { weak var node: Node? }
        let box = NodeBox(node: self)

        notificationToken = NotificationCenter.default.addObserver(forName: .documentDidDeleteNodes, object: nil, queue: nil, using: {
            if let self = box.node,
               ($0.userInfo?[Document.documentUserInfoKey] as? Document) == self.owningDocument,
               let deletedNodes = ($0.userInfo?[Document.deletedNodesUserInfoKey] as? Set<pugi.xml_node>) {
                self.handleDeletedNodes(deletedNodes)
            }
        })
    }

    deinit {
        if let notificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
        }
    }

    internal func invalidate() {
        node = .init()
        if let notificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
        }
        notificationToken = nil
    }

    internal var isValid: Bool {
        node.empty() == false
    }

    internal func handleDeletedNodes(_ nodes: Set<pugi.xml_node>) {
        var node = self.node
        while !node.empty() {
            if nodes.contains(node) {
                invalidate()
                return
            }
            node = node.parent()
        }
    }

    internal func declaredNamespacesDidChange() {}
    internal var hasNamespaceDeclarations: Bool { false }

    /// The document that owns this node.
    ///
    /// - Returns: The `Document` that this node belongs to.
    public var document: Document {
        guard let owningDocument else {
            fatalError("owningDocument should only be nil for Document, which overrides this property")
        }
        return owningDocument
    }

    /// Serializes the node and its children into a `Data` object.
    ///
    /// - Parameters:
    ///   - encoding: The string encoding to use for the output. Defaults to `.utf8`.
    ///   - options: The options for XML output formatting. Defaults to `.default`.
    ///   - indentation: The string to use for indentation in the XML output. Defaults to `.fourSpaces`.
    /// - Returns: A `Data` object containing the serialized XML representation of the node.
    public func xmlData(
        encoding: String.Encoding = .utf8,
        options: OutputOptions = .default,
        indentation: String = .fourSpaces
    ) throws -> Data {
        var data = Data()
        xml_node_print_with_block(node, indentation, options.rawValue, encoding.pugiEncoding, 0) { rawPointer, length in
            guard let rawPointer else { return }
            data.append(rawPointer.assumingMemoryBound(to: UInt8.self), count: length)
        }
        return data
    }

    /// Serializes the node and its children into a string.
    ///
    /// - Parameters:
    ///   - options: The options for XML output formatting. Defaults to `.default`.
    ///   - indentation: The string to use for indentation in the XML output. Defaults to `.fourSpaces`.
    /// - Returns: A string containing the serialized XML representation of the node.
    public func xmlString(options: OutputOptions = .default, indentation: String = .fourSpaces) throws -> String {
        String(data: try xmlData(encoding: .utf8, options: options, indentation: indentation), encoding: .utf8) ?? ""
    }
}

public extension Node {
    /// The name of the node.
    ///
    /// - For elements, this is the qualified name, including a local name and an optional namespace prefix.
    /// - For processing instructions, the name represents the target.
    /// - For other kinds of nodes, the name is an empty string.
    ///
    /// - Note: For an expanded name (including namespace name), see `Element.expandedName`.
    var name: String {
        get {
            String(cString: node.name()) // documented to never return null
        }
        set {
            node.set_name(newValue)
        }
    }

    /// The value of the node.
    ///
    /// - For text, CDATA, comments, DOCTYPEs, and processing instructions, this contains their respective values.
    /// - For other kinds of nodes, the value is an empty string.
    var value: String {
        get {
            String(cString: node.value()) // documented to never return null
        }
        set {
            node.set_value(newValue)
        }
    }

    /// The offset of this node from the beginning of the original XML buffer, if available.
    ///
    /// This property provides the offset in characters from the start of the XML data used to parse the document.
    /// The offset is only available if he node was parsed from a stream or buffer and has not undergone significant changes since parsing.
    ///
    /// - Returns: The character offset from the beginning of the XML buffer, or `nil` if unavailable.
    var sourceOffset: Int? {
        let offset = node.offset_debug()
        return offset == -1 ? nil : offset
    }
}

internal extension Node {
    var nodePointer: OpaquePointer {
        node.internal_object()
    }
}

extension Node: Equatable {
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        lhs.node == rhs.node
    }
}

extension Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch kind {
        case .element: "Element <\(name)>"
        case .text: "Text \"\(value)\""
        case .cdata: "CDATA \"\(value)\""
        case .comment: "Comment <!--\(value)-->"
        case .doctype: "Document type declaration <!DOCTYPE \(value)>"
        case .processingInstruction: "PI <?\(name) \(value)?>"
        case .declaration: "Declaration <?\(name)...?>"
        case .document: "Document"
        }
    }
}
