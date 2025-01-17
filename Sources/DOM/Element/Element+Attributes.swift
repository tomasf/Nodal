import Foundation
import pugixml

public extension Element {
    func removeAllAttributes() {
        node.remove_attributes()
    }

    private var hasNamespaceDeclarations: Bool {
        nodeAttributes.contains(where: { String(cString: $0.name()).hasPrefix("xmlns") })
    }

    var qualifiedAttributes: [(name: String, value: String)] {
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
                invalidateNamespaceCache()
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
                invalidateNamespaceCache()
            }
        }
    }
}
