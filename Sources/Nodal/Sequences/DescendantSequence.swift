import Foundation
import pugixml

// Visits the target and all its descendants
internal struct DescendantSequence: Sequence, IteratorProtocol {
    private var node: pugi.xml_node
    private var root: pugi.xml_node

    init(target: pugi.xml_node) {
        node = target
        root = target
    }

    public mutating func next() -> pugi.xml_node? {
        if node.empty() { return nil }

        let current = node
        if let child = node.first_child().nonNull {
            node = child

        } else if let sibling = node.next_sibling(inside: root).nonNull {
            node = sibling

        } else {
            node = node.parent(inside: root)
            while !node.empty() {
                if let parentSibling = node.next_sibling(inside: root).nonNull {
                    node = parentSibling
                    break
                }
                node = node.parent(inside: root)
            }
        }
        return current
    }
}

internal extension pugi.xml_node {
    var descendants: DescendantSequence {
        DescendantSequence(target: self)
    }

    func parent(inside root: pugi.xml_node) -> pugi.xml_node {
        self == root ? .init() : parent()
    }

    func next_sibling(inside root: pugi.xml_node) -> pugi.xml_node {
        self == root ? .init() : next_sibling()
    }
}
