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
    ///   - name: The name of the new document element; either a String or an ExpandedName
    ///   - uri: The default namespace URI to associate with the document element. Defaults to `nil`.
    /// - Returns: The newly created element.
    ///
    /// - Note: If the document already has a document element, it is removed before creating the new one.
    @discardableResult
    func makeDocumentElement(name: ElementName, defaultNamespace uri: String? = nil) -> Node {
        let element = clearDocumentElement()
        if let uri {
            element.declareNamespace(uri, forPrefix: nil)
        }
        element.name = name.requestQualifiedName(for: element)
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

public extension Document {
    /// Decodes the root element of the XML document into a Swift type conforming to `XMLElementDecodable`.
    ///
    /// This method extracts the *root element* of the XML document and attempts to decode it into the specified type.
    ///
    /// ## Example Usage
    /// ```swift
    /// let xml = """
    /// <Person name="Alice">
    ///     <age>30</age>
    /// </Person>
    /// """
    /// let document = try Document(xmlString: xml)
    /// let person: Person = try document.decoded(as: Person.self)
    /// ```
    ///
    /// - Parameter type: The type to decode the document into. Must conform to `XMLElementDecodable`.
    /// - Returns: An instance of `T`, constructed from the root XML element.
    /// - Throws: `XMLElementCodableError.documentElementMissing` if the document has no root element.
    /// - SeeAlso: `init(_:elementName:)`
    ///
    func decoded<T: XMLElementDecodable>(as type: T.Type) throws -> T {
        guard let root = documentElement else {
            throw XMLElementCodableError.documentElementMissing
        }

        return try T.init(from: root)
    }

    /// Creates an XML document from an instance of `XMLElementEncodable`.
    ///
    /// This initializes a new XML document with the specified *root element name*, then encodes the given object into it.
    ///
    /// - Parameters:
    ///   - item: The object to encode into XML. Must conform to `XMLElementEncodable`.
    ///   - elementName: The name of the root element in the XML document; either a String or an ExpandedName
    /// - SeeAlso: `decoded(as:)`
    ///
    convenience init<T: XMLElementEncodable>(_ item: T, elementName: ElementName) {
        self.init()
        let root = makeDocumentElement(name: elementName)
        item.encode(to: root)
    }
}
