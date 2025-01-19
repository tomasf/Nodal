import Foundation
import pugixml

public extension Element {
    var orderedAttributes: [(name: ExpandedName, value: String)] {
        get {
            let namespaces = namespacesInScope
            return nodeAttributes.map {(
                ExpandedName(effectiveQualifiedAttributeName: String(cString: $0.name()), in: self, using: namespaces),
                String(cString: $0.value())
            )}
        }
        set {
            let namespaces = namespacesInScope
            node.remove_attributes()
            for (name, value) in newValue {
                let qName = name.effectiveQualifiedAttributeName(for: self, using: namespaces)
                var attr = node.append_attribute(qName)
                attr.set_value(value)
            }
        }
    }

    var namespacedAttributes: [ExpandedName: String] {
        get { Dictionary(orderedAttributes) { $1 } }
        set { orderedAttributes = newValue.map { ($0, $1) } }
    }

    subscript(attribute name: ExpandedName) -> String? {
        get {
            let qName: String
            if let match = name.qualifiedAttributeName(using: namespacesInScope) {
                qName = match
            } else if let placeholder = pendingNameRecord?.attributes[name] {
                // Namespace not in scope; try pending placeholder
                qName = placeholder
            } else {
                return nil
            }

            return self[attribute: qName]
        }
        set {
            let qName = name.effectiveQualifiedAttributeName(for: self, using: namespacesInScope)
            self[attribute: qName] = newValue
        }
    }

    subscript(attribute localName: String, uri namespaceURI: String?) -> String? {
        get {
            self[attribute: ExpandedName(namespaceName: namespaceURI, localName: localName)]
        }
        set {
            self[attribute: ExpandedName(namespaceName: namespaceURI, localName: localName)] = newValue
        }
    }
}
