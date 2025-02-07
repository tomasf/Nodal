import Foundation
import pugixml

internal extension Document {
    func clearDocumentElement() -> Node {
        if let oldRoot = documentElement {
            node.removeChild(oldRoot)
        }
        resetNamespaceDeclarationCache()
        let rootNode = pugiDocument.append_child(pugi.node_element)
        return node(for: rootNode)
    }
}

public extension Document {
    /// The document (root) element of the document, or `nil` if the document does not have a document element.
    ///
    /// - Note: The document element is the top-level element in the document tree.
    var documentElement: Node? {
        pugiDocument.documentElement.nonNull.map { node(for: $0) }
    }

    /// Creates a new document (root) element for the document with the specified name and optional default namespace URI.
    ///
    /// - Parameters:
    ///   - name: The name of the new document element.
    ///   - uri: The default namespace URI to associate with the document element. Defaults to `nil`.
    /// - Returns: The newly created element.
    ///
    /// - Note: If the document already has a document element, it is removed before creating the new one.
    @discardableResult
    func makeDocumentElement(name: String, defaultNamespace uri: String? = nil) -> Node {
        let element = clearDocumentElement()
        element.name = name
        if let uri {
            element.declareNamespace(uri, forPrefix: nil)
        }
        return element
    }

    /// Creates a new document (root) element for the document using an expanded name and declares a namespace for a prefix.
    ///
    /// - Parameters:
    ///   - name: The expanded name of the new document element, which includes a local name and an optional namespace.
    ///   - prefix: The prefix to declare for the namespace associated with the document element.
    /// - Returns: The newly created element.
    ///
    /// - Note: If the document already has a document element, it is removed before creating the new one.
    @discardableResult
    func makeDocumentElement(name: ExpandedName, declaringNamespaceFor prefix: String) -> Node {
        let element = clearDocumentElement()
        if let uri = name.namespaceName {
            element.declareNamespace(uri, forPrefix: prefix)
            element.expandedName = name
        } else {
            element.name = name.localName
        }
        return element
    }
}
