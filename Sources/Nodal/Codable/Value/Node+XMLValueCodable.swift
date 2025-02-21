import Foundation

// Whitespace-separated values, xsd:list-style

public extension Node {
    /// Retrieves the value of an XML attribute and decodes it into a specified type.
    ///
    /// This method attempts to decode the value of the given attribute into the requested type.
    /// If the attribute is missing, it returns `nil`.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: The decoded value, or `nil` if the attribute is not present.
    /// - Throws: `XMLValueError.invalidFormat` if the value cannot be parsed.
    ///
    func value<T: XMLValueDecodable>(forAttribute attribute: any AttributeName) throws -> T? {
        guard let string = self[attribute: attribute] else { return nil }
        return try T.init(xmlStringValue: string.trimmed)
    }

    /// Retrieves the value of an XML attribute and decodes it into a specified type.
    ///
    /// If the attribute is missing, this method *throws an error*.
    ///
    /// - Parameter attribute: The name of the attribute.
    /// - Returns: The decoded value.
    /// - Throws:
    ///   - `XMLValueError.missingAttribute` if the attribute is missing.
    ///   - `XMLValueError.invalidFormat` if the value cannot be parsed.
    ///
    func value<T: XMLValueDecodable>(forAttribute attribute: any AttributeName) throws -> T {
        guard let value: T = try value(forAttribute: attribute) else {
            throw XMLValueError.missingAttribute(attribute)
        }
        return value
    }
}

public extension Node {
    /// Sets the value of an XML attribute by encoding it to a string.
    ///
    /// - Parameters:
    ///   - value: The new value to set, or `nil` to remove the attribute.
    ///   - attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    ///
    /// ## Example Usage
    /// ```swift
    /// personNode.setValue(25, forAttribute: "age") // Sets age="25"
    /// personNode.setValue(nil, forAttribute: "age") // Removes the attribute
    /// ```
    func setValue<T: XMLValueEncodable>(_ value: T?, forAttribute attribute: any AttributeName) {
        self[attribute: attribute] = value?.xmlStringValue
    }
}

public extension Node {
    /// Retrieves the text content of an XML node and decodes it into a specified type.
    ///
    /// This method extracts the concatenated text of all descendant text and CDATA nodes,
    /// then attempts to decode it into the requested type.
    ///
    /// - Returns: The decoded value.
    /// - Throws: `XMLValueError.invalidFormat` if the value cannot be parsed.
    ///
    /// ## Example Usage
    /// ```swift
    /// let weight: Double = try weightNode.content() // Reads <weight>72.5</weight>
    /// ```
    func content<T: XMLValueDecodable>() throws -> T {
        return try T.init(xmlStringValue: textContent.trimmed)
    }

    /// Sets the text content of an XML node by encoding it to a string.
    ///
    /// This method replaces all child nodes with a single text node containing the encoded value.
    ///
    /// - Parameter value: The new text content.
    ///
    /// ## Example Usage
    /// ```swift
    /// weightNode.setContent(72.5) // Sets <weight>72.5</weight>
    /// ```
    func setContent<T: XMLValueEncodable>(_ value: T) {
        textContent = value.xmlStringValue
    }
}
