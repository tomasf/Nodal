import Foundation
import pugixml

public extension Element {
    var parentElement: Element? {
        parent as? Element
    }

    var elements: [Element] {
        childNodes(ofType: pugi.node_element).map { document.element(for: $0) }
    }

    subscript(element name: String) -> Element? {
        for subnode in childNodes {
            if subnode.type() == pugi.node_element && String(cString: subnode.name()) == name {
                return document.element(for: subnode)
            }
        }
        return nil
    }

    subscript(elements name: String) -> [Element] {
        childNodes.compactMap { subnode in
            if subnode.type() == pugi.node_element && String(cString: subnode.name()) == name {
                return document.element(for: subnode)
            } else {
                return nil
            }
        }
    }

    subscript(elements targetName: ExpandedName) -> [Element] {
        let candidateElements = childNodes.filter { $0.type() == pugi.node_element && String(cString: $0.name()).hasSuffix(targetName.localName) }
        return candidateElements.compactMap {
            let element = document.element(for: $0)
            return element.expandedName == targetName ? element : nil
        }
    }

    subscript(elements localName: String, uri namespaceURI: String) -> [Element] {
        self[elements: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }

    subscript(element targetName: ExpandedName) -> Element? {
        let match = childNodes.first(where: {
            guard $0.type() == pugi.node_element && String(cString: $0.name()).hasSuffix(targetName.localName) else { return false }
            let element = document.element(for: $0)
            return element.expandedName == targetName
        })
        return if let match { document.element(for: match) } else { nil }
    }

    subscript (element localName: String, uri namespaceURI: String) -> Element? {
        self[element: ExpandedName(namespaceName: namespaceURI, localName: localName)]
    }

    // Add an element with a given qualified name
    @discardableResult
    func appendElement(_ name: String) -> Element {
        let element = document.createElementObject(forNode: node.append_child(pugi.node_element))
        element.name = name
        return element
    }

    // Add an element in a namespace that has been declared in this element or in one of its ancestors
    @discardableResult
    func appendElement(_ name: ExpandedName) -> Element {
        let child = appendElement("")
        child.expandedName = name
        return child
    }

    // Add an element in a namespace that has been declared in this element or in one of its ancestors
    @discardableResult
    func appendElement(_ localName: String, namespace namespaceURI: String?) -> Element {
        appendElement(ExpandedName(namespaceName: namespaceURI, localName: localName))
    }

    // Add an element that declares a new namespace, where the element itself is part of that namespace
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
