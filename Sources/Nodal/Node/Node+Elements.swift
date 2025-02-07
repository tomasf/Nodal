import Foundation
import pugixml

public extension Node {
    /// The parent element of this node, or `nil` if its parent is not an element.
    var parentElement: Node? {
        guard parent?.kind == .element else { return nil }
        return parent
    }

    /// The child elements of this node.
    ///
    /// - Returns: An array of all child nodes that are elements.
    var elements: [Node] {
        node.children
            .filter { $0.type() == pugi.node_element }
            .map { document.node(for: $0) }
    }

    /// Retrieves the first child element with the specified name.
    ///
    /// - Parameter name: The qualified name of the child element to retrieve.
    /// - Returns: The first child element with the specified name, or `nil` if no such element exists.
    subscript(element name: String) -> Node? {
        node.children.first {
            $0.type() == pugi.node_element && String(cString: $0.name()) == name
        }?.wrapped(in: document)
    }

    /// Retrieves all child elements with the specified name.
    ///
    /// - Parameter name: The qualified name of the child elements to retrieve.
    /// - Returns: An array of child elements with the specified name.
    subscript(elements name: String) -> [Node] {
        node.children.lazy.filter {
            $0.type() == pugi.node_element && String(cString: $0.name()) == name
        }.map { $0.wrapped(in: document) }
    }

    /// Retrieves all child elements matching the specified expanded name.
    ///
    /// - Parameter targetName: The expanded name (including local name and optional namespace) of the elements to retrieve.
    /// - Returns: An array of child elements matching the expanded name.
    subscript(elements targetName: ExpandedName) -> [Node] {
        return node.children.lazy.filter {
            $0.type() == pugi.node_element
            && String(cString: $0.name()).hasSuffix(targetName.localName)
            && self.document.expandedName(for: $0) == targetName
        }.map { $0.wrapped(in: document) }
    }

    /// Retrieves all child elements with the specified local name and namespace URI.
    ///
    /// - Parameters:
    ///   - localName: The local name of the elements to retrieve.
    ///   - namespaceURI: The namespace URI of the elements to retrieve.
    /// - Returns: An array of child elements matching the local name and namespace URI.
    subscript(elements localName: String, uri namespaceURI: String) -> [Node] {
        self[elements: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }

    /// Retrieves the first child element matching the specified expanded name.
    ///
    /// - Parameter targetName: The expanded name (including local name and optional namespace) of the element to retrieve.
    /// - Returns: The first child element matching the expanded name, or `nil` if no such element exists.
    subscript(element targetName: ExpandedName) -> Node? {
        node.children.lazy.first {
            $0.type() == pugi.node_element
            && String(cString: $0.name()).hasSuffix(targetName.localName)
            && document.expandedName(for: $0) == targetName
        }?.wrapped(in: document)
    }

    /// Retrieves the first child element with the specified local name and namespace URI.
    ///
    /// - Parameters:
    ///   - localName: The local name of the element to retrieve.
    ///   - namespaceURI: The namespace URI of the element to retrieve.
    /// - Returns: The first child element matching the local name and namespace URI, or `nil` if no such element exists.
    subscript(element localName: String, uri namespaceURI: String) -> Node? {
        self[element: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }
}

public extension Node {
    /// Adds a new child element with the specified qualified name to this element at the given position.
    ///
    /// - Parameters:
    ///   - name: The qualified name of the new element.
    ///   - position: The position where the new child element should be inserted. Defaults to `.last`, adding the element as the last child of this element.
    /// - Returns: The newly created child element.
    @discardableResult
    func addElement(_ name: String, at position: Position = .last) -> Node {
        precondition(canContainChildren(ofKind: .element), "This kind of node can't contain elements")
        let element = document.node(for: node.addChild(kind: pugi.node_element, at: position))
        element.name = name
        return element
    }

    /// Adds a new child element with the specified expanded name to this element at the given position.
    ///
    /// - Parameters:
    ///   - name: The expanded name of the new element, including the local name and an optional namespace.
    ///   - position: The position where the new child element should be inserted. Defaults to `.last`, adding the element as the last child of this element.
    /// - Returns: The newly created child element.
    @discardableResult
    func addElement(_ name: ExpandedName, at position: Position = .last) -> Node {
        let child = addElement("", at: position)
        child.expandedName = name
        return child
    }

    /// Adds a new child element with the specified local name and optional namespace URI to this element at the given position.
    ///
    /// - Parameters:
    ///   - localName: The local name of the new element.
    ///   - namespaceName: The namespace name (URI) of the new element. Defaults to `nil` if the element does not belong to a namespace.
    ///   - position: The position where the new child element should be inserted. Defaults to `.last`, adding the element as the last child of this element.
    /// - Returns: The newly created child element.
    @discardableResult
    func addElement(_ localName: String, namespace namespaceName: String?, at position: Position = .last) -> Node {
        addElement(ExpandedName(namespaceName: namespaceName, localName: localName), at: position)
    }

    /// Appends a new child element that declares a namespace, with the element itself being part of that namespace.
    ///
    /// - Parameters:
    ///   - name: The expanded name (including local name and namespace) of the new element.
    ///   - prefix: The prefix to associate with the declared namespace. Pass `nil` for a default namespace.
    /// - Returns: The newly created child element.
    ///
    /// - Precondition: The expanded name must include a namespace URI.
    @discardableResult
    func addElement(_ name: ExpandedName, declaringNamespaceWith prefix: String?, at position: Position = .last) -> Node {
        guard let uri = name.namespaceName else {
            preconditionFailure("You can't declare an empty namespace")
        }
        let element = addElement("", at: position)
        element.declareNamespace(uri, forPrefix: prefix)
        element.expandedName = name
        return element
    }
}
