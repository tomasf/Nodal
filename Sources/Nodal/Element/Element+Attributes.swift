import Foundation
import pugixml

internal extension Element {
    var hasNamespaceDeclarations: Bool {
        nodeAttributes.contains(where: { String(cString: $0.name()).hasPrefix("xmlns") })
    }

    func declaredNamespacesDidChange() {
        let namespaces = declaredNamespaces
        for (element, record) in document.pendingNameRecords(forDescendantsOf: self) {
            if record.attemptResolution(for: element, with: namespaces) {
                document.removePendingNameRecord(for: element)
            }
        }
    }
}

public extension Element {
    /// Removes all attributes from the element.
    ///
    /// - Note: This method clears all attributes associated with the element, including namespace declarations.
    func removeAllAttributes() {
        node.remove_attributes()
    }

    /// The attributes of the element, represented as an array of name-value pairs.
    ///
    /// - Returns: An array of tuples where each tuple contains the qualified name of an attribute and its corresponding value.
    ///
    /// - Note: Setting new attributes replaces all existing attributes. Qualified names, such as those with prefixes, are handled directly when specified.
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

    /// Accesses the value of a specific attribute by its qualified name.
    ///
    /// - Parameter name: The qualified name of the attribute to access.
    /// - Returns: The value of the attribute if it exists, or `nil` if the attribute is not present.
    ///
    /// - Example:
    ///   ```swift
    ///   let element = ...
    ///   element["id"] = "12345" // Sets the "id" attribute
    ///   let idValue = element["id"] // Retrieves the value of the "id" attribute
    ///   element["class"] = nil // Removes the "class" attribute
    ///   ```
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
