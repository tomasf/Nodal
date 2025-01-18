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

public enum XPathResultNode {
    case null
    case node (Node)
    case attribute (Attribute)

    internal init(_ xPathNode: pugi.xpath_node, document: Document) {
        if !xPathNode.node().empty() {
            self = .node(document.object(for: xPathNode.node()))
        } else if !xPathNode.attribute().empty() {
            self = .attribute(.init(xPathNode, document: document))
        } else {
            self = .null
        }
    }
}

public extension XPathResultNode {
    struct Attribute {
        private let node: pugi.xpath_node
        private let document: Document

        internal init(_ node: pugi.xpath_node, document: Document) {
            self.node = node
            self.document = document
        }

        public var name: String {
            String(cString: node.attribute().name())
        }

        public var value: String {
            String(cString: node.attribute().value())
        }

        public var parent: Element {
            document.element(for: node.parent())
        }

        public var expandedName: ExpandedName {
            ExpandedName(qualifiedAttributeName: name, using: parent.namespacesInScope)
        }
    }
}
