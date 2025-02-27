import Foundation
import pugixml

/// Represents an XPath query for evaluating expressions against an XML document.
public class XPathQuery {
    internal var query: pugi.xpath_query

    /// Creates an XPath query with the specified expression and optional variables.
    ///
    /// - Parameters:
    ///   - expression: The XPath expression to evaluate.
    ///   - variables: A dictionary of variables used in the expression. Keys correspond to variable names (without `$`), and values must be of type `String`, `Int`, `Double`, or `Bool`. Defaults to an empty dictionary.
    /// - Throws: `ParseError` if the expression is invalid.
    ///
    /// - Example:
    ///   ```swift
    ///   let query = try XPathQuery("//book[@category = $category]", variables: ["category": "fiction"])
    ///   ```
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
    /// Evaluates the XPath expression as a string result relative to the specified base node.
    ///
    /// - Parameter baseNode: The node against which to evaluate the XPath query.
    /// - Returns: The result of the query as a `String`.
    func stringResult(with baseNode: Node) -> String {
        String(query.evaluate_string(.init(baseNode.node)))
    }

    /// Evaluates the XPath expression as a double result relative to the specified base node.
    ///
    /// - Parameter baseNode: The node against which to evaluate the XPath query.
    /// - Returns: The result of the query as a `Double`.
    func doubleResult(with baseNode: Node) -> Double {
        query.evaluate_number(.init(baseNode.node))
    }

    /// Evaluates the XPath expression as an integer result relative to the specified base node.
    ///
    /// - Parameter baseNode: The node against which to evaluate the XPath query.
    /// - Returns: The result of the query as an `Int`.
    func intResult(with baseNode: Node) -> Int {
        Int(doubleResult(with: baseNode))
    }

    /// Evaluates the XPath expression as a boolean result relative to the specified base node.
    ///
    /// - Parameter baseNode: The node against which to evaluate the XPath query.
    /// - Returns: The result of the query as a `Bool`.
    func boolResult(with baseNode: Node) -> Bool {
        query.evaluate_boolean(.init(baseNode.node))
    }

    /// Evaluates the XPath expression as a set of nodes relative to the specified base node.
    ///
    /// - Parameter baseNode: The node against which to evaluate the XPath query.
    /// - Returns: An array of `XPathNode` objects representing the nodes matching the query.
    func nodesResult(with baseNode: Node) -> [XPathNode] {
        let nodeSet = query.evaluate_node_set(.init(baseNode.node))
        return nodeSet.nodes.map { XPathNode(xPathNode: $0, document: baseNode.document) }
    }

    /// Evaluates the XPath expression as a single node relative to the specified base node.
    ///
    /// - Parameter baseNode: The node against which to evaluate the XPath query.
    /// - Returns: A `XPathNode` object representing the first node matching the query.
    func firstNodeResult(with baseNode: Node) -> XPathNode? {
        let xPathNode = query.__evaluate_nodeUnsafe(.init(baseNode.node))
        if xPathNode.node().empty() {
            return nil
        }
        return XPathNode(xPathNode: xPathNode, document: baseNode.document)
    }

    /// Represents an error that occurs when parsing an XPath expression.
    struct ParseError: Error {
        /// A description of the error.
        let description: String

        /// The character offset in the XPath expression where the error occurred.
        let offset: Int

        internal init(_ result: pugi.xpath_parse_result) {
            description = String(cString: result.error)
            offset = result.offset
        }
    }
}

