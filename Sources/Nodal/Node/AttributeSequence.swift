import Foundation
import pugixml

internal struct AttributeSequence: Sequence, IteratorProtocol {
    private let target: Node
    private var current: pugi.xml_attribute? = nil

    init(target: Node) {
        self.target = target
    }

    mutating func next() -> pugi.xml_attribute? {
        let next = if let current {
            current.next_attribute()
        } else {
            target.node.first_attribute()
        }
        self.current = next
        return next.empty() ? nil : next
    }
}

internal extension Node {
    var nodeAttributes: AttributeSequence {
        AttributeSequence(target: self)
    }
}
