import Foundation
internal import pugixml

public extension Node {
    /// Decodes an optional XML element into the specified type.
    ///
    /// This method searches for a child element with the given name and attempts to decode it.
    /// If the element is missing, it returns `nil`.
    ///
    /// - Parameter name: The name of the element to decode.
    /// - Returns: A decoded instance of `T`, or `nil` if the element is not present.
    /// - Throws: `XMLElementCodableError.invalidFormat` if the element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: String) throws -> T? {
        guard let element = self[element: name] else { return nil }
        return try T.init(from: element)
    }

    /// Decodes an optional XML element into the specified type.
    ///
    /// This method searches for a child element with the given expanded name and attempts to decode it.
    /// If the element is missing, it returns `nil`.
    ///
    /// - Parameter name: The expanded name of the element to decode.
    /// - Returns: A decoded instance of `T`, or `nil` if the element is not present.
    /// - Throws: `XMLElementCodableError.invalidFormat` if the element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: ExpandedName) throws -> T? {
        guard let element = self[element: name] else { return nil }
        return try T.init(from: element)
    }

    /// Decodes an XML element into the specified type.
    ///
    /// If the element is missing, this method *throws an error*.
    ///
    /// - Parameter name: The name of the element to decode.
    /// - Returns: A decoded instance of `T`.
    /// - Throws:
    ///   - `XMLElementCodableError.elementMissing` if the element is missing.
    ///   - `XMLElementCodableError.invalidFormat` if the element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: String) throws -> T {
        guard let element: T = try decode(elementName: name) else { throw XMLElementCodableError.elementMissing(name) }
        return element
    }

    /// Decodes an XML element into the specified type.
    ///
    /// If the element is missing, this method *throws an error*.
    ///
    /// - Parameter name: The expanded name of the element to decode.
    /// - Returns: A decoded instance of `T`.
    /// - Throws:
    ///   - `XMLElementCodableError.elementMissing` if the element is missing.
    ///   - `XMLElementCodableError.invalidFormat` if the element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: ExpandedName) throws -> T {
        guard let element: T = try decode(elementName: name) else { throw XMLElementCodableError.expandedElementMissing(name) }
        return element
    }

    /// Decodes an array of XML elements into the specified type.
    ///
    /// This method searches for all child elements matching the given name and decodes them.
    /// If a `containerName` is provided, it looks inside that container element first.
    ///
    /// - Parameters:
    ///   - name: The name of the elements to decode.
    ///   - containerName: The optional container element name. If provided, the method searches inside this container.
    /// - Returns: An array of decoded values.
    /// - Throws:
    ///   - `XMLElementCodableError.invalidFormat` if any element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: String, containedIn containerName: String? = nil) throws -> [T] {
        let parent: Node
        if let containerName {
            guard let container = self[element: containerName] else {
                return []
            }
            parent = container
        } else {
            parent = self
        }
        // Collect raw pugixml nodes (no ARC, unlike `Node`) to get an exact count first,
        // so `result` below can reserve capacity instead of growing repeatedly.
        let matches: [pugi.xml_node] = parent.node.children.filter {
            $0.type() == pugi.node_element && name.matchesElementName(node: $0, in: parent.document)
        }
        var result: [T] = []
        result.reserveCapacity(matches.count)
        for child in matches {
            result.append(try T.init(from: child.wrapped(in: parent.document)))
        }
        return result
    }

    /// Decodes an array of XML elements into the specified type.
    ///
    /// This method searches for all child elements matching the given expanded name and decodes them.
    /// If a `containerName` is provided, it looks inside that container element first.
    ///
    /// - Parameters:
    ///   - name: The expanded name of the elements to decode.
    ///   - containerName: The optional container element name. If provided, the method searches inside this container.
    /// - Returns: An array of decoded values.
    /// - Throws:
    ///   - `XMLElementCodableError.invalidFormat` if any element cannot be parsed.
    ///
    func decode<T: XMLElementDecodable>(elementName name: ExpandedName, containedIn containerName: ExpandedName? = nil) throws -> [T] {
        let parent: Node
        if let containerName {
            guard let container = self[element: containerName] else {
                return []
            }
            parent = container
        } else {
            parent = self
        }
        // See the `String`-keyed overload above for why this avoids `[elements:]`.
        let matches: [pugi.xml_node] = parent.node.children.filter {
            $0.type() == pugi.node_element && name.matchesElementName(node: $0, in: parent.document)
        }
        var result: [T] = []
        result.reserveCapacity(matches.count)
        for child in matches {
            result.append(try T.init(from: child.wrapped(in: parent.document)))
        }
        return result
    }
}

public extension Node {
    /// Encodes an optional value as an XML element.
    ///
    /// If the provided value is `nil`, no element is added.
    ///
    /// - Parameters:
    ///   - item: The value to encode.
    ///   - name: The name of the XML element to create.
    ///
    func encode<T: XMLElementEncodable>(_ item: T?, elementName name: String) {
        guard let item else { return }
        item.encode(to: addElement(name))
    }

    /// Encodes an optional value as an XML element.
    ///
    /// If the provided value is `nil`, no element is added.
    ///
    /// - Parameters:
    ///   - item: The value to encode.
    ///   - name: The expanded name of the XML element to create.
    ///
    func encode<T: XMLElementEncodable>(_ item: T?, elementName name: ExpandedName) {
        guard let item else { return }
        item.encode(to: addElement(name))
    }

    /// Encodes an array of values as XML elements.
    ///
    /// This method creates an element for each value in `items`. If `containerName` is provided, all elements are wrapped inside that container.
    ///
    /// - Parameters:
    ///   - items: The array of values to encode. If this is empty, this method does nothing.
    ///   - name: The name of each XML element.
    ///   - containerName: An optional container element name. If provided, the elements are placed inside this container.
    ///
    func encode<T: XMLElementEncodable>(_ items: [T], elementName name: String, containedIn containerName: String? = nil) {
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

    /// Encodes an array of values as XML elements.
    ///
    /// This method creates an element for each value in `items`. If `containerName` is provided, all elements are wrapped inside that container.
    ///
    /// - Parameters:
    ///   - items: The array of values to encode. If this is empty, this method does nothing.
    ///   - name: The expanded name of each XML element.
    ///   - containerName: An optional container element name. If provided, the elements are placed inside this container.
    ///
    func encode<T: XMLElementEncodable>(_ items: [T], elementName name: ExpandedName, containedIn containerName: ExpandedName? = nil) {
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
