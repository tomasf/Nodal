import Foundation
import pugixml

// Visits all children of the target
internal struct ChildSequence: Sequence, IteratorProtocol {
    private var node: pugi.xml_node

    init(target: pugi.xml_node) {
        node = target.first_child()
    }

    mutating func next() -> pugi.xml_node? {
        guard !node.empty() else { return nil }

        let current = node
        node = node.next_sibling()
        return current
    }
}

internal extension pugi.xml_node {
    var children: ChildSequence {
        ChildSequence(target: self)
    }
}
