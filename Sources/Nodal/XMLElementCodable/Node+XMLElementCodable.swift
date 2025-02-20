import Foundation

public extension Node {
    /// Decodes an optional XML element into the specified type.
    ///
    /// This method searches for a child element with the given name and attempts to decode it.
    /// If the element is missing, it returns `nil`.
    ///
    /// - Parameter name: The name of the element to decode; either a `String` or an `ExpandedName`.
    /// - Returns: A decoded instance of `T`, or `nil` if the element is not present.
    /// - Throws: `XMLElementCodableError.invalidFormat` if the element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: any ElementName) throws -> T? {
        guard let element = self[element: name] else { return nil }
        return try T.init(from: element)
    }

    /// Decodes an XML element into the specified type.
    ///
    /// If the element is missing, this method *throws an error*.
    ///
    /// - Parameter name: The name of the element to decode; either a `String` or an `ExpandedName`.
    /// - Returns: A decoded instance of `T`.
    /// - Throws:
    ///   - `XMLElementCodableError.elementMissing` if the element is missing.
    ///   - `XMLElementCodableError.invalidFormat` if the element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: any ElementName) throws -> T {
        guard let element: T = try decode(elementName: name) else { throw XMLElementCodableError.elementMissing(name) }
        return element
    }

    /// Decodes an array of XML elements into the specified type.
    ///
    /// This method searches for all child elements matching the given name and decodes them.
    /// If a `containerName` is provided, it looks inside that container element first.
    ///
    /// - Parameters:
    ///   - name: The name of the elements to decode; either a `String` or an `ExpandedName`.
    ///   - containerName: The optional container element name. If provided, the method searches inside this container.
    /// - Returns: An array of decoded values.
    /// - Throws:
    ///   - `XMLElementCodableError.invalidFormat` if any element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: any ElementName, containedIn containerName: ElementName? = nil) throws -> [T] {
        let parent: Node
        if let containerName {
            guard let container = self[element: containerName] else {
                return []
            }
            parent = container
        } else {
            parent = self
        }
        return try parent[elements: name].map { try T.init(from: $0) }
    }
}

public extension Node {
    /// Encodes an optional value as an XML element.
    ///
    /// If the provided value is `nil`, no element is added.
    ///
    /// - Parameters:
    ///   - item: The value to encode.
    ///   - name: The name of the XML element to create; either a `String` or an `ExpandedName`.
    ///
    func encode<T: XMLElementEncodable>(_ item: T?, elementName name: any ElementName) {
        guard let item else { return }
        item.encode(to: addElement(name))
    }

    /// Encodes an array of values as XML elements.
    ///
    /// This method creates an element for each value in `items`. If `containerName` is provided, all elements are wrapped inside that container.
    ///
    /// - Parameters:
    ///   - items: The array of values to encode. If this is empty, this method does nothing.
    ///   - name: The name of each XML element; either a `String` or an `ExpandedName`.
    ///   - containerName: An optional container element name; either a `String` or an `ExpandedName`. If provided, the elements are placed inside this container.
    ///
    func encode<T: XMLElementEncodable>(_ items: [T], elementName name: any ElementName, containedIn containerName: (any ElementName)? = nil) {
        guard items.isEmpty == false else { return }
        let parent: Node
        if let containerName {
            parent = addElement(containerName)
        } else {
            parent = self
        }
        for item in items {
            parent.encode(item, elementName: name)
        }
    }
}
