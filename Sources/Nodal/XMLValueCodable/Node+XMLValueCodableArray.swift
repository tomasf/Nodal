import Foundation

public extension Node {
    /// Retrieves the value of an XML attribute and decodes it into an array of the specified type.
    ///
    /// This method attempts to decode the *whitespace-separated* values of the given attribute into an array.
    /// If the attribute is missing, it returns `nil`.
    ///
    /// - Parameter attribute: The name of the attribute.
    /// - Returns: An array of decoded values, or `nil` if the attribute is not present.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    /// ## Example Usage
    /// ```swift
    /// let numbers: [Int]? = try personNode.value(forAttribute: "numbers") // "10 20 30" → [10, 20, 30]
    /// ```
    func value<T: XMLValueDecodable>(forAttribute attribute: String) throws -> [T]? {
        guard let string = self[attribute: attribute] else { return nil }
        return try [T](xmlStringValue: string)
    }

    /// Retrieves the value of an XML attribute and decodes it into an array of the specified type.
    ///
    /// If the attribute is missing, this method *throws an error*.
    ///
    /// - Parameter attribute: The name of the attribute.
    /// - Returns: An array of decoded values.
    /// - Throws:
    ///   - `XMLValueError.missingAttribute` if the attribute is missing.
    ///   - `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    /// ## Example Usage
    /// ```swift
    /// let numbers: [Int] = try personNode.value(forAttribute: "numbers") // "10  20\n30" → [10, 20, 30]
    /// ```
    func value<T: XMLValueDecodable>(forAttribute attribute: String) throws -> [T] {
        guard let value: [T] = try value(forAttribute: attribute) else {
            throw XMLValueError.missingAttribute(attribute)
        }
        return value
    }
}

public extension Node {
    /// Retrieves the value of a namespaced XML attribute and decodes it into an array of the specified type.
    ///
    /// This method attempts to decode the *whitespace-separated* values of the given attribute into an array.
    /// If the attribute is missing, it returns `nil`.
    ///
    /// - Parameter attribute: The `ExpandedName` of the attribute (including namespace information).
    /// - Returns: An array of decoded values, or `nil` if the attribute is not present.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    func value<T: XMLValueDecodable>(forAttribute attribute: ExpandedName) throws -> [T]? {
        guard let string = self[attribute: attribute] else { return nil }
        return try [T](xmlStringValue: string)
    }

    /// Retrieves the value of a namespaced XML attribute and decodes it into an array of the specified type.
    ///
    /// If the attribute is missing, this method *throws an error*.
    ///
    /// - Parameter attribute: The `ExpandedName` of the attribute (including namespace information).
    /// - Returns: An array of decoded values.
    /// - Throws:
    ///   - `XMLValueError.missingExpandedAttribute` if the attribute is missing.
    ///   - `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    func value<T: XMLValueDecodable>(forAttribute attribute: ExpandedName) throws -> [T] {
        guard let value: [T] = try value(forAttribute: attribute) else {
            throw XMLValueError.missingExpandedAttribute(attribute)
        }
        return value
    }
}

public extension Node {
    /// Sets the value of an XML attribute with an array of values, encoding them as a *whitespace-separated* list.
    ///
    /// - Parameters:
    ///   - value: The new array to set, or `nil` to remove the attribute.
    ///   - attribute: The name of the attribute.
    ///
    /// ## Example Usage
    /// ```swift
    /// personNode.setValue([10, 20, 30], forAttribute: "numbers") // Sets numbers="10 20 30"
    /// personNode.setValue(nil, forAttribute: "numbers") // Removes the attribute
    /// ```
    func setValue<T: XMLValueEncodable>(_ value: [T]?, forAttribute attribute: String) {
        self[attribute: attribute] = value?.xmlStringValue
    }

    /// Sets the value of a namespaced XML attribute with an array of values, encoding them as a *whitespace-separated* list.
    ///
    /// - Parameters:
    ///   - value: The new array to set, or `nil` to remove the attribute.
    ///   - attribute: The `ExpandedName` of the attribute (including namespace information).
    ///
    func setValue<T: XMLValueEncodable>(_ value: [T]?, forAttribute attribute: ExpandedName) {
        self[attribute: attribute] = value?.xmlStringValue
    }
}

public extension Node {
    /// Retrieves the text content of an XML node and decodes it into an array of the specified type.
    ///
    /// This method extracts the concatenated text of all descendant text and CDATA nodes,
    /// then attempts to decode it as a *whitespace-separated* list.
    ///
    /// - Returns: An array of decoded values.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    func content<T: XMLValueDecodable>() throws -> [T] {
        return try [T](xmlStringValue: textContent)
    }

    /// Sets the text content of an XML node with an array of values, encoding them as a *whitespace-separated* list.
    ///
    /// This method replaces all child nodes with a single text node containing the encoded values.
    ///
    /// - Parameter value: The new text content as an array.
    ///
    /// ## Example Usage
    /// ```swift
    /// personNode.setContent([10, 20, 30]) // Sets `<numbers>10 20 30</numbers>`
    /// ```
    func setContent<T: XMLValueEncodable>(_ value: [T]) {
        textContent = value.xmlStringValue
    }
}
