import Foundation
import pugixml

internal struct AncestorAttributeSequence: Sequence, IteratorProtocol {
    private var node: pugi.xml_node
    private var attribute: pugi.xml_attribute
    private var current: pugi.xml_attribute? = nil

    init(target: pugi.xml_node) {
        node = target
        attribute = node.first_attribute()
    }

    init(target: Element) {
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

internal extension Element {
    var ancestorAttributes: AncestorAttributeSequence {
        AncestorAttributeSequence(target: self)
    }
}

internal extension pugi.xml_node {
    var ancestorAttributes: AncestorAttributeSequence {
        AncestorAttributeSequence(target: self)
    }
}
