import Foundation
import pugixml

public extension Node {
    /// The attributes of this element in document order, represented as an array of expanded names and their corresponding values.
    ///
    /// - Returns: An array of tuples where each tuple contains an `ExpandedName` and the corresponding attribute value.
    ///
    /// - Note: Setting this property replaces all existing attributes with the new ones, preserving the specified order.
    var orderedAttributes: [(name: ExpandedName, value: String)] {
        get {
            return node.attributes.map {(
                ExpandedName(effectiveQualifiedAttributeName: String(cString: $0.name()), in: self),
                String(cString: $0.value())
            )}
        }
        nonmutating set {
            var node = node
            node.remove_attributes()
            for (name, value) in newValue {
                let qName = name.requestQualifiedAttributeName(for: self)
                var attr = node.append_attribute(qName)
                attr.set_value(value)
            }
        }
    }

    /// The attributes of this element as a dictionary, where the keys are `ExpandedName` objects and the values are their corresponding attribute values.
    ///
    /// - Returns: A dictionary of attributes keyed by their expanded names.
    ///
    /// - Note: Setting this property replaces all existing attributes with the new ones. The order of attributes is determined by the dictionary's order.
    var namespacedAttributes: [ExpandedName: String] {
        get { Dictionary(orderedAttributes) { $1 } }
        nonmutating set { orderedAttributes = newValue.map { ($0, $1) } }
    }

    /// Accesses the value of an attribute by its expanded name.
    ///
    /// - Parameter name: The `ExpandedName` of the attribute to access.
    /// - Returns: The value of the attribute if it exists, or `nil` if no such attribute is found.
    ///
    /// - Note: When setting an attribute, its namespace is resolved based on the current scope. If `nil` is assigned, the attribute is removed.
    ///
    /// - Example:
    ///   ```swift
    ///   let name = ExpandedName(namespaceName: "http://example.com", localName: "attribute")
    ///   element[attribute: name] = "value" // Adds or updates the attribute
    ///   let value = element[attribute: name] // Retrieves the value
    ///   element[attribute: name] = nil // Removes the attribute
    ///   ```
    subscript(attribute name: ExpandedName) -> String? {
        get {
            let qName: String
            if let match = name.qualifiedAttributeName(in: self) {
                qName = match
            } else if let placeholder = pendingNameRecord?.attributes[name] {
                // Namespace not in scope; try pending placeholder
                qName = placeholder
            } else {
                return nil
            }

            return self[attribute: qName]
        }
        nonmutating set {
            let qName = name.requestQualifiedAttributeName(for: self)
            self[attribute: qName] = newValue
        }
    }

    /// Accesses the value of an attribute by its local name and optional namespace URI.
    ///
    /// - Parameters:
    ///   - localName: The local name of the attribute to access.
    ///   - namespaceURI: The namespace name of the attribute, or `nil` if the attribute is not namespaced.
    /// - Returns: The value of the attribute if it exists, or `nil` if no such attribute is found.
    ///
    /// - Note: This subscript allows convenient access to attributes by specifying both the local name and namespace.
    ///
    /// - Example:
    ///   ```swift
    ///   element[attribute: "id", namespaceName: nil] = "123" // Sets an attribute with no namespace
    ///   element[attribute: "name", namespaceName: "http://example.com"] = "example" // Sets a namespaced attribute
    ///   let value = element[attribute: "name", namespaceName: "http://example.com"] // Retrieves the value
    ///   element[attribute: "name", namespaceName: "http://example.com"] = nil // Removes the attribute
    ///   ```
    subscript(attribute localName: String, namespaceName namespaceURI: String?) -> String? {
        get {
            self[attribute: ExpandedName(namespaceName: namespaceURI, localName: localName)]
        }
        nonmutating set {
            self[attribute: ExpandedName(namespaceName: namespaceURI, localName: localName)] = newValue
        }
    }
}
