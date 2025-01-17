import Foundation
import pugixml

public class XPathQuery {
    private var query: pugi.xpath_query

    init(expression: String, variables: [String: Any]) throws(ParseError) {
        var variableSet = pugi.xpath_variable_set()
        for (key, value) in variables {
            guard let variableValue = value as? XPathVariableValue else {
                fatalError("Unsupported variable type for variable \"\(key)\"")
            }
            variableValue.define(in: &variableSet, for: key)
        }

        query = pugi.xpath_query(expression, &variableSet)
        let parseResult = query.__resultUnsafe().pointee
        if parseResult.error != nil {
            throw ParseError(parseResult)
        }
    }

    public func evaluate(with node: Node) -> String {
        String(query.evaluate_string(.init(node.node)))
    }

    public func evaluate(with node: Node) -> Double {
        query.evaluate_number(.init(node.node))
    }

    public func evaluate(with node: Node) -> Int {
        Int(evaluate(with: node) as Double)
    }

    public func evaluate(with node: Node) -> Bool {
        query.evaluate_boolean(.init(node.node))
    }

    public func evaluate(with node: Node) -> [XPathResultNode] {
        let nodeSet = query.evaluate_node_set(.init(node.node))
        return nodeSet.nodes.map { XPathResultNode($0, document: node.document) }
    }

    public var resultType: ResultType {
        .init(query.return_type())
    }

    public enum ResultType {
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

    public struct ParseError: Error {
        let description: String
        let offset: Int

        internal init(_ result: pugi.xpath_parse_result) {
            description = String(cString: result.error)
            offset = result.offset
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
        let name: String
        let value: String
        let parent: Element

        internal init(name: String, value: String, parent: Element) {
            self.name = name
            self.value = value
            self.parent = parent
        }

        internal init(_ xPathNode: pugi.xpath_node, document: Document) {
            self.init(
                name: String(cString: xPathNode.attribute().name()),
                value: String(cString: xPathNode.attribute().value()),
                parent: document.element(for: xPathNode.parent())
            )
        }

        public var expandedName: ExpandedName {
            ExpandedName(qualifiedAttributeName: name, using: parent.namespacesInScope)
        }
    }
}

internal protocol XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String)
}

extension String: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, self)
    }
}

extension Int: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, Double(self))
    }
}

extension Double: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, self)
    }
}

extension Bool: XPathVariableValue {
    func define(in variableSet: inout pugi.xpath_variable_set, for key: String) {
        variableSet.set(key, self)
    }
}
