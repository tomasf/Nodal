import Foundation
import pugixml

// Visits all attributes of the target and its ancestors
internal struct AncestorAttributeSequence: Sequence, IteratorProtocol {
    private var node: pugi.xml_node
    private var attribute: pugi.xml_attribute

    init(target: pugi.xml_node) {
        node = target
        attribute = node.first_attribute()
    }

    init(target: Node) {
        self.init(target: target.node)
    }

    mutating func next() -> pugi.xml_attribute? {
        while attribute.empty() {
            node = node.parent()
            if node.empty() {
                return nil
            }
            attribute = node.first_attribute()
        }

        let result = attribute
        attribute = attribute.next_attribute()
        return result
    }
}

internal extension pugi.xml_node {
    var ancestorAttributes: AncestorAttributeSequence {
        AncestorAttributeSequence(target: self)
    }
}
