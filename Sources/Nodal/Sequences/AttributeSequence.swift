import Foundation
import pugixml

// Visits all attributes of the target
internal struct AttributeSequence: Sequence, IteratorProtocol {
    private var attribute: pugi.xml_attribute

    init(target: pugi.xml_node) {
        attribute = target.first_attribute()
    }

    mutating func next() -> pugi.xml_attribute? {
        guard !attribute.empty() else { return nil }

        defer { attribute = attribute.next_attribute() }
        return attribute
    }
}

internal extension pugi.xml_node {
    var attributes: AttributeSequence {
        AttributeSequence(target: self)
    }
}
