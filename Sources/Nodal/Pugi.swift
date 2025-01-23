import pugixml
import Bridge

extension pugi.xml_node_type: Hashable {}
extension pugi.xml_node: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(internal_object())
    }

    var nonNull: pugi.xml_node? {
        empty() ? nil : self
    }
}

extension pugi.xml_attribute {
    var nonNull: pugi.xml_attribute? {
        empty() ? nil : self
    }
}

internal extension pugi.xml_document {
    var asNode: pugi.xml_node { xml_document_as_node(self) }
    var documentElement: pugi.xml_node {
        __document_elementUnsafe()
    }
}

internal extension pugi.xpath_node_set {
    var nodes: [pugi.xpath_node] {
        (0..<size()).map { self[$0] }
    }
}

internal extension pugi.xml_node {
    mutating func addChild(kind: pugi.xml_node_type, at childPosition: Node.Position) -> pugi.xml_node {
        guard childPosition.validate(for: self) else {
            fatalError("Peer node for Node.Position must be a valid child of the parent")
        }

        return switch childPosition {
        case .first: prepend_child(kind)
        case .before (let other): insert_child_before(kind, other.node)
        case .after (let other): insert_child_after(kind, other.node)
        case .last: append_child(kind)
        }
    }

    mutating func insertChild(_ child: pugi.xml_node, at childPosition: Node.Position) -> pugi.xml_node {
        guard childPosition.validate(for: self) else {
            fatalError("Peer node for Node.Position must be a valid child of the parent")
        }

        return switch childPosition {
        case .first: prepend_move(child)
        case .before (let other): insert_move_before(child, other.node)
        case .after (let other): insert_move_after(child, other.node)
        case .last: append_move(child)
        }
    }
}
