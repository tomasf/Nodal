import Foundation
import pugixml

internal extension Element {
    var hasNamespaceDeclarations: Bool {
        nodeAttributes.contains(where: { String(cString: $0.name()).hasPrefix("xmlns") })
    }

    func declaredNamespacesDidChange() {
        invalidateNamespaceCache()
        let namespaces = declaredNamespaces
        for (element, record) in document.pendingNameRecords(forDescendantsOf: self) {
            if record.attemptResolution(for: element, with: namespaces) {
                document.removePendingRecord(for: element)
            }
        }
    }
}

public extension Element {
    func removeAllAttributes() {
        node.remove_attributes()
    }

    var attributes: [(name: String, value: String)] {
        get {
            return nodeAttributes.map {(
                String(cString: $0.name()),
                String(cString: $0.value())
            )}
        }
        set {
            var didTouchNamespaces = hasNamespaceDeclarations
            node.remove_attributes()
            for (name, value) in newValue {
                var attr = node.append_attribute(name)
                attr.set_value(value)
                if name.hasPrefix("xmlns") {
                    didTouchNamespaces = true
                }
            }
            if didTouchNamespaces {
                declaredNamespacesDidChange()
            }
        }
    }

    subscript(attribute name: String) -> String? {
        get {
            let attribute = node.attribute(name)
            return attribute.empty() ? nil : String(cString: attribute.value())
        }
        set {
            var attr = node.attribute(name)
            if attr.empty() {
                if newValue != nil {
                    attr = node.append_attribute(name)
                    attr.set_value(newValue)
                }
            } else {
                if let newValue {
                    attr.set_value(newValue)
                } else {
                    node.remove_attribute(attr)
                }
            }
            if name.hasPrefix("xmlns") {
                declaredNamespacesDidChange()
            }
        }
    }
}
