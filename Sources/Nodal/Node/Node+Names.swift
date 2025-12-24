import Foundation
internal import pugixml

internal extension String {
    func matchesElementName(node: pugi.xml_node, in document: Document) -> Bool {
        String(cString: node.name()) == self
    }
}

internal extension ExpandedName {
    func matchesElementName(node: pugi.xml_node, in document: Document) -> Bool {
        String(cString: node.name()).hasSuffix(localName) && document.expandedName(for: node) == self
    }
}


public protocol AttributeName: Sendable {
    func requestQualifiedName(in node: Node) -> String
    func qualifiedName(in: Node) -> String?
}

extension String: AttributeName {
    public func requestQualifiedName(in node: Node) -> String {
        self
    }

    public func qualifiedName(in: Node) -> String? {
        self
    }
}

extension ExpandedName: AttributeName {
    public func requestQualifiedName(in node: Node) -> String {
        requestQualifiedAttributeName(for: node)
    }

    public func qualifiedName(in node: Node) -> String? {
        if let match = qualifiedAttributeName(in: node) {
            return match
        } else if let placeholder = node.pendingNameRecord?.attributes[self] {
            // Namespace not in scope; try pending placeholder
            return placeholder
        } else {
            return nil
        }
    }
}
