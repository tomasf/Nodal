import Foundation
import pugixml

public extension XPathQuery {
    var resultType: ResultType {
        .init(query.return_type())
    }

    enum ResultType {
        case nodes
        case boolean
        case number
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

    var node: Node? {
        if let node = xPathNode.node().nonNull ?? xPathNode.parent().nonNull {
            document.object(for: node)
        } else {
            nil
        }
    }

    var attributeName: String? {
        xPathNode.attribute().empty() ? nil : String(cString: xPathNode.attribute().name())
    }
}
