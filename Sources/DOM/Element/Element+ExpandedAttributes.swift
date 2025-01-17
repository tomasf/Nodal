import Foundation
import pugixml

public extension Element {
    var orderedAttributes: [(name: ExpandedName, value: String)] {
        get {
            let namespaces = namespacesInScope
            return nodeAttributes.map {(
                ExpandedName(qualifiedAttributeName: String(cString: $0.name()), using: namespaces),
                String(cString: $0.value())
            )}
        }
        set {
            let namespaces = namespacesInScope
            node.remove_attributes()
            for (name, value) in newValue {
                guard let qName = name.qualifiedAttributeName(using: namespaces) else {
                    fatalError("Undeclared namespace \(name.uri ?? "")")
                }
                var attr = node.append_attribute(qName)
                attr.set_value(value)
            }
        }
    }

    var attributes: [ExpandedName: String] {
        get { Dictionary(orderedAttributes) { $1 } }
        set { orderedAttributes = newValue.map { ($0, $1) } }
    }

    subscript(attribute name: ExpandedName) -> String? {
        get {
            // Trying to retrieve with an unknown namespace is fine
            guard let qName = name.qualifiedAttributeName(using: namespacesInScope) else { return nil }
            return self[attribute: qName]
        }
        set {
            // Setting with one is not.
            guard let qName = name.qualifiedAttributeName(using: namespacesInScope) else {
                fatalError("Undeclared namespace \(name.uri ?? "")")
            }
            self[attribute: qName] = newValue
        }
    }

    subscript(attribute localName: String, uri namespaceURI: String?) -> String? {
        get {
            self[attribute: ExpandedName(uri: namespaceURI, localName: localName)]
        }
        set {
            self[attribute: ExpandedName(uri: namespaceURI, localName: localName)] = newValue
        }
    }
}
