import Foundation
import pugixml

internal struct NodeChildren: Sequence, IteratorProtocol {
    private let target: Node
    private var current: pugi.xml_node? = nil

    init(target: Node) {
        self.target = target
    }

    mutating func next() -> pugi.xml_node? {
        let next = if let current {
            current.next_sibling()
        } else {
            target.node.first_child()
        }
        self.current = next
        return next.empty() ? nil : next
    }
}

internal extension Node {
    var childNodes: NodeChildren {
        NodeChildren(target: self)
    }
}
