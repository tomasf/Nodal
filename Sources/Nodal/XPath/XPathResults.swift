import Foundation
import pugixml

public extension XPathQuery {
    /// The type of the result produced by this XPath query.
    ///
    /// - Returns: A `ResultType` indicating whether the result is a set of nodes, a boolean, a number, or a string.
    var resultType: ResultType {
        .init(query.return_type())
    }

    /// Represents the possible result types of an XPath query.
    enum ResultType {
        /// The result is a set of nodes.
        case nodes
        /// The result is a boolean value.
        case boolean
        /// The result is a numeric value.
        case number
        /// The result is a string value.
        case string

        internal init(_ pugiType: pugi.xpath_value_type) {
            switch pugiType {
            case pugi.xpath_type_node_set: self = .nodes
            case pugi.xpath_type_boolean: self = .boolean
            case pugi.xpath_type_number: self = .number
            case pugi.xpath_type_string: self = .string
            default: fatalError("unknown XPath value type")
            }
        }
    }
}

/// Represents a result node from an XPath query.
///
/// An `XPathResultNode` can represent:
/// - A node in the XML document.
/// - An attribute of a node in the XML document.
/// - A null result, indicating no node or attribute is present.
///
/// The distinction is made based on the following properties:
/// - If `node` is non-`nil` and `attributeName` is `nil`, the result represents a node in the XML document.
/// - If both `node` and `attributeName` are non-`nil`, the result represents an attribute of a node.
/// - If both `node` and `attributeName` are `nil`, the result represents a null result.
public struct XPathResultNode: CustomDebugStringConvertible {
    private let xPathNode: pugi.xpath_node
    private let document: Document

    internal init(xPathNode: pugi.xpath_node, document: Document) {
        self.xPathNode = xPathNode
        self.document = document
    }

    public var debugDescription: String {
        if let attributeName, let node {
            "Attribute '\(attributeName)' in node '\(node)'"
        } else if let node {
            "Node '\(node)'"
        } else {
            "Null"
        }
    }

    /// The node associated with this XPath result, or `nil` if no node is present.
    ///
    /// - Note: If the result references an attribute, this property returns the parent node of the attribute.
    var node: Node? {
        if let node = xPathNode.node().nonNull ?? xPathNode.parent().nonNull {
            document.object(for: node)
        } else {
            nil
        }
    }

    /// The qualified name of the attribute associated with this XPath result, or `nil` if no attribute is present.
    ///
    /// - Note: This property is only relevant when the XPath result references an attribute.
    var attributeName: String? {
        xPathNode.attribute().empty() ? nil : String(cString: xPathNode.attribute().name())
    }
}
