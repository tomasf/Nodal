import Foundation
import pugixml

// Visits the target and all its descendants
internal struct DescendantSequence: Sequence, IteratorProtocol {
    private var node: pugi.xml_node

    init(target: pugi.xml_node) {
        node = target
    }

    public mutating func next() -> pugi.xml_node? {
        if node.empty() { return nil }

        let current = node
        if let child = node.first_child().nonNull {
            node = child
        } else if let sibling = node.next_sibling().nonNull {
            node = sibling
        } else {
            node = node.parent()
            while !node.empty() {
                if let parentSibling = node.next_sibling().nonNull {
                    node = parentSibling
                    break
                }
                node = node.parent()
            }
        }
        return current
    }
}

internal extension pugi.xml_node {
    var descendants: DescendantSequence {
        DescendantSequence(target: self)
    }
}
