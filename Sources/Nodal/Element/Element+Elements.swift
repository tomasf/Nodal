import Foundation
import pugixml

public extension Element {
    /// The parent element of this element, or `nil` if this element has no parent or its parent is not an element.
    var parentElement: Element? {
        parent as? Element
    }

    /// The child elements of this element.
    ///
    /// - Returns: An array of all child nodes that are elements.
    var elements: [Element] {
        childNodes(ofType: pugi.node_element).map { document.element(for: $0) }
    }

    /// Retrieves the first child element with the specified name.
    ///
    /// - Parameter name: The qualified name of the child element to retrieve.
    /// - Returns: The first child element with the specified name, or `nil` if no such element exists.
    subscript(element name: String) -> Element? {
        for subnode in childNodes {
            if subnode.type() == pugi.node_element && String(cString: subnode.name()) == name {
                return document.element(for: subnode)
            }
        }
        return nil
    }

    /// Retrieves all child elements with the specified name.
    ///
    /// - Parameter name: The qualified name of the child elements to retrieve.
    /// - Returns: An array of child elements with the specified name.
    subscript(elements name: String) -> [Element] {
        childNodes.compactMap { subnode in
            if subnode.type() == pugi.node_element && String(cString: subnode.name()) == name {
                return document.element(for: subnode)
            } else {
                return nil
            }
        }
    }

    /// Retrieves all child elements matching the specified expanded name.
    ///
    /// - Parameter targetName: The expanded name (including local name and optional namespace) of the elements to retrieve.
    /// - Returns: An array of child elements matching the expanded name.
    subscript(elements targetName: ExpandedName) -> [Element] {
        let candidateElements = childNodes.filter { $0.type() == pugi.node_element && String(cString: $0.name()).hasSuffix(targetName.localName) }
        return candidateElements.compactMap {
            let element = document.element(for: $0)
            return element.expandedName == targetName ? element : nil
        }
    }

    /// Retrieves all child elements with the specified local name and namespace URI.
    ///
    /// - Parameters:
    ///   - localName: The local name of the elements to retrieve.
    ///   - namespaceURI: The namespace URI of the elements to retrieve.
    /// - Returns: An array of child elements matching the local name and namespace URI.
    subscript(elements localName: String, uri namespaceURI: String) -> [Element] {
        self[elements: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }

    /// Retrieves the first child element matching the specified expanded name.
    ///
    /// - Parameter targetName: The expanded name (including local name and optional namespace) of the element to retrieve.
    /// - Returns: The first child element matching the expanded name, or `nil` if no such element exists.
    subscript(element targetName: ExpandedName) -> Element? {
        let match = childNodes.first(where: {
            guard $0.type() == pugi.node_element && String(cString: $0.name()).hasSuffix(targetName.localName) else { return false }
            let element = document.element(for: $0)
            return element.expandedName == targetName
        })
        return if let match { document.element(for: match) } else { nil }
    }

    /// Retrieves the first child element with the specified local name and namespace URI.
    ///
    /// - Parameters:
    ///   - localName: The local name of the element to retrieve.
    ///   - namespaceURI: The namespace URI of the element to retrieve.
    /// - Returns: The first child element matching the local name and namespace URI, or `nil` if no such element exists.
    subscript(element localName: String, uri namespaceURI: String) -> Element? {
        self[element: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }
}

public extension Element {
    /// Appends a new child element with the specified qualified name to this element.
    ///
    /// - Parameter name: The qualified name of the new element.
    /// - Returns: The newly created child element.
    @discardableResult
    func appendElement(_ name: String) -> Element {
        let element = document.createElementObject(forNode: node.append_child(pugi.node_element))
        element.name = name
        return element
    }

    /// Appends a new child element with the specified expanded name to this element.
    ///
    /// - Parameter name: The expanded name (including local name and optional namespace) of the new element.
    /// - Returns: The newly created child element.
    @discardableResult
    func appendElement(_ name: ExpandedName) -> Element {
        let child = appendElement("")
        child.expandedName = name
        return child
    }

    /// Appends a new child element with the specified local name and optional namespace URI to this element.
    ///
    /// - Parameters:
    ///   - localName: The local name of the new element.
    ///   - namespaceURI: The namespace URI of the new element. Defaults to `nil`.
    /// - Returns: The newly created child element.
    @discardableResult
    func appendElement(_ localName: String, namespace namespaceURI: String?) -> Element {
        appendElement(ExpandedName(namespaceName: namespaceURI, localName: localName))
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
    func appendElement(_ name: ExpandedName, declaringNamespaceWith prefix: String?) -> Element {
        guard let uri = name.namespaceName else {
            preconditionFailure("You can't declare an empty namespace")
        }
        let namespaces = [prefix: uri]
        let element = appendElement(name.qualifiedElementName(using: namespaces))
        element.declareNamespace(uri, forPrefix: prefix)
        return element
    }
}
