import Foundation
import pugixml

public class XPathQuery {
    internal var query: pugi.xpath_query

    // Create an XPath query. If the expression isn't a valid query, a ParseError is thrown.
    // Variable can be used with $name in the expression, and their values must be of one of
    // the types String, Int, Double or Bool.
    public init(_ expression: String, variables: [String: Any] = [:]) throws(ParseError) {
        var variableSet = pugi.xpath_variable_set()
        for (key, value) in variables {
            guard let variableValue = value as? XPathVariableValue else {
                preconditionFailure("Unsupported variable type for name \"\(key)\"")
            }
            variableValue.define(in: &variableSet, for: key)
        }

        query = pugi.xpath_query(expression, &variableSet)
        let parseResult = query.__resultUnsafe().pointee
        if parseResult.error != nil {
            throw ParseError(parseResult)
        }
    }
}

public extension XPathQuery {
    func stringValue(with node: Node) -> String {
        String(query.evaluate_string(.init(node.node)))
    }

    func doubleValue(with node: Node) -> Double {
        query.evaluate_number(.init(node.node))
    }

    func intValue(with node: Node) -> Int {
        Int(doubleValue(with: node))
    }

    func boolValue(with node: Node) -> Bool {
        query.evaluate_boolean(.init(node.node))
    }

    func nodes(with node: Node) -> [XPathResultNode] {
        let nodeSet = query.evaluate_node_set(.init(node.node))
        return nodeSet.nodes.compactMap { XPathResultNode(xPathNode: $0, document: node.document) }
    }

    struct ParseError: Error {
        let description: String
        let offset: Int

        internal init(_ result: pugi.xpath_parse_result) {
            description = String(cString: result.error)
            offset = result.offset
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
