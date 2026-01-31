import Foundation

public extension Node {
    /// Retrieves the value of an XML attribute and decodes it into an array of the specified type.
    ///
    /// This method attempts to decode the *whitespace-separated* values of the given attribute into an array.
    /// If the attribute is missing, it returns `nil`.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: An array of decoded values, or `nil` if the attribute is not present.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    /// ## Example Usage
    /// ```swift
    /// let numbers: [Int]? = try personNode.value(forAttribute: "numbers") // "10 20 30" → [10, 20, 30]
    /// ```
    func value<T: XMLValueDecodable>(forAttribute attribute: any AttributeName) throws -> [T]? {
        guard let string = self[attribute: attribute] else { return nil }
        return try [T](xmlStringValue: string)
    }

    /// Retrieves the value of an XML attribute and decodes it into an array of the specified type.
    ///
    /// If the attribute is missing, this method *throws an error*.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: An array of decoded values.
    /// - Throws:
    ///   - `XMLValueError.missingAttribute` if the attribute is missing.
    ///   - `XMLValueError.invalidFormat` if the values cannot be parsed.
    ///
    /// ## Example Usage
    /// ```swift
    /// let numbers: [Int] = try personNode.value(forAttribute: "numbers") // "10  20\n30" → [10, 20, 30]
    /// ```
    func value<T: XMLValueDecodable>(forAttribute attribute: any AttributeName) throws -> [T] {
        guard let value: [T] = try value(forAttribute: attribute) else {
            throw XMLValueError.missingAttribute(attribute)
        }
        return value
    }
}

public extension Node {
    /// Sets the value of an XML attribute with an array of values, encoding them as a *whitespace-separated* list.
    ///
    /// - Parameters:
    ///   - value: The new array to set, or `nil` to remove the attribute.
    ///   - attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    ///
    /// ## Example Usage
    /// ```swift
    /// personNode.setValue([10, 20, 30], forAttribute: "numbers") // Sets numbers="10 20 30"
    /// personNode.setValue(nil, forAttribute: "numbers") // Removes the attribute
    /// ```
    func setValue<T: XMLValueEncodable>(_ value: [T]?, forAttribute attribute: any AttributeName) {
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

// MARK: - Data arrays (uses document.dataFormat)

public extension Node {
    /// Retrieves the value of an XML attribute and decodes it as an array of `Data`.
    ///
    /// The data format is determined by the document's ``Document/dataFormat`` property.
    /// Values are expected to be whitespace-separated.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: An array of decoded data, or `nil` if the attribute is not present.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    func value(forAttribute attribute: any AttributeName) throws -> [Data]? {
        guard let string = self[attribute: attribute] else { return nil }
        return try string
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { try document.dataFormat.decode($0) }
    }

    /// Retrieves the value of an XML attribute and decodes it as an array of `Data`.
    ///
    /// The data format is determined by the document's ``Document/dataFormat`` property.
    /// If the attribute is missing, this method *throws an error*.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: An array of decoded data.
    /// - Throws:
    ///   - `XMLValueError.missingAttribute` if the attribute is missing.
    ///   - `XMLValueError.invalidFormat` if the values cannot be parsed.
    func value(forAttribute attribute: any AttributeName) throws -> [Data] {
        guard let value: [Data] = try value(forAttribute: attribute) else {
            throw XMLValueError.missingAttribute(attribute)
        }
        return value
    }

    /// Sets the value of an XML attribute with an array of `Data`, encoding them as a whitespace-separated list.
    ///
    /// The data format is determined by the document's ``Document/dataFormat`` property.
    ///
    /// - Parameters:
    ///   - value: The array of data to set, or `nil` to remove the attribute.
    ///   - attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    func setValue(_ value: [Data]?, forAttribute attribute: any AttributeName) {
        self[attribute: attribute] = value.map {
            $0.map { document.dataFormat.encode($0) }.joined(separator: " ")
        }
    }

    /// Retrieves the text content of an XML node and decodes it as an array of `Data`.
    ///
    /// The data format is determined by the document's ``Document/dataFormat`` property.
    /// Values are expected to be whitespace-separated.
    ///
    /// - Returns: An array of decoded data.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    func content() throws -> [Data] {
        try textContent
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { try document.dataFormat.decode($0) }
    }

    /// Sets the text content of an XML node with an array of `Data`, encoding them as a whitespace-separated list.
    ///
    /// The data format is determined by the document's ``Document/dataFormat`` property.
    ///
    /// - Parameter value: The array of data to set.
    func setContent(_ value: [Data]) {
        textContent = value.map { document.dataFormat.encode($0) }.joined(separator: " ")
    }
}

// MARK: - Date arrays (uses document.dateFormat)

public extension Node {
    /// Retrieves the value of an XML attribute and decodes it as an array of dates.
    ///
    /// The date format is determined by the document's ``Document/dateFormat`` property.
    /// Values are expected to be whitespace-separated.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: An array of decoded dates, or `nil` if the attribute is not present.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    func value(forAttribute attribute: any AttributeName) throws -> [Date]? {
        guard let string = self[attribute: attribute] else { return nil }
        return try string
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { try document.dateFormat.decode($0) }
    }

    /// Retrieves the value of an XML attribute and decodes it as an array of dates.
    ///
    /// The date format is determined by the document's ``Document/dateFormat`` property.
    /// If the attribute is missing, this method *throws an error*.
    ///
    /// - Parameter attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    /// - Returns: An array of decoded dates.
    /// - Throws:
    ///   - `XMLValueError.missingAttribute` if the attribute is missing.
    ///   - `XMLValueError.invalidFormat` if the values cannot be parsed.
    func value(forAttribute attribute: any AttributeName) throws -> [Date] {
        guard let value: [Date] = try value(forAttribute: attribute) else {
            throw XMLValueError.missingAttribute(attribute)
        }
        return value
    }

    /// Sets the value of an XML attribute with an array of dates, encoding them as a whitespace-separated list.
    ///
    /// The date format is determined by the document's ``Document/dateFormat`` property.
    ///
    /// - Parameters:
    ///   - value: The array of dates to set, or `nil` to remove the attribute.
    ///   - attribute: The name of the attribute; either a `String` or an `ExpandedName`.
    func setValue(_ value: [Date]?, forAttribute attribute: any AttributeName) {
        self[attribute: attribute] = value.map {
            $0.map { document.dateFormat.encode($0) }.joined(separator: " ")
        }
    }

    /// Retrieves the text content of an XML node and decodes it as an array of dates.
    ///
    /// The date format is determined by the document's ``Document/dateFormat`` property.
    /// Values are expected to be whitespace-separated.
    ///
    /// - Returns: An array of decoded dates.
    /// - Throws: `XMLValueError.invalidFormat` if the values cannot be parsed.
    func content() throws -> [Date] {
        try textContent
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { try document.dateFormat.decode($0) }
    }

    /// Sets the text content of an XML node with an array of dates, encoding them as a whitespace-separated list.
    ///
    /// The date format is determined by the document's ``Document/dateFormat`` property.
    ///
    /// - Parameter value: The array of dates to set.
    func setContent(_ value: [Date]) {
        textContent = value.map { document.dateFormat.encode($0) }.joined(separator: " ")
    }
}
