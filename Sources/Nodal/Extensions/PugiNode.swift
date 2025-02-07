import Foundation
import pugixml

extension pugi.xml_node: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(internal_object())
    }

    var nonNull: pugi.xml_node? {
        empty() ? nil : self
    }

    func wrapped(in document: Document) -> Node {
        document.node(for: self)
    }
}

internal extension pugi.xml_node {
    func addChild(kind: pugi.xml_node_type, at position: Node.Position) -> pugi.xml_node {
        guard position.validate(for: self) else {
            fatalError("Peer node for Node.Position must be a valid child of the parent")
        }

        var node = self

        return switch position {
        case .first: node.prepend_child(kind)
        case .before (let other): node.insert_child_before(kind, other.node)
        case .after (let other): node.insert_child_after(kind, other.node)
        case .last: node.append_child(kind)
        }
    }

    mutating func insertChild(_ child: pugi.xml_node, at position: Node.Position) -> pugi.xml_node {
        guard position.validate(for: self) else {
            fatalError("Peer node for Node.Position must be a valid child of the parent")
        }

        return switch position {
        case .first: prepend_move(child)
        case .before (let other): insert_move_before(child, other.node)
        case .after (let other): insert_move_after(child, other.node)
        case .last: append_move(child)
        }
    }
}

internal extension pugi.xml_node {
    var explicitNamespacesInScope: [String?: String] {
        var namespaces: [String?: String] = [:]

        for attribute in ancestorAttributes {
            let name = attribute.name()!
            guard strncmp(name, "xmlns", 5) == 0 else { continue }
            let (prefix, localName) = name.qualifiedNameParts

            let namespacePrefix = (prefix == nil) ? nil : localName
            if namespaces[namespacePrefix] == nil {
                namespaces[namespacePrefix] = String(cString: attribute.value())
            }
        }

        return namespaces
    }
}
