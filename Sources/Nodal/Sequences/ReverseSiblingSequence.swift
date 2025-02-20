import Foundation
import pugixml

// Visits preceding siblings of the target
internal struct PrecendingSiblingSequence: Sequence, IteratorProtocol {
    private var node: pugi.xml_node

    init(target: pugi.xml_node) {
        node = target.previous_sibling()
    }

    mutating func next() -> pugi.xml_node? {
        guard !node.empty() else { return nil }

        defer { node = node.previous_sibling() }
        return node
    }
}

internal extension pugi.xml_node {
    var precedingSiblings: PrecendingSiblingSequence {
        PrecendingSiblingSequence(target: self)
    }
}
