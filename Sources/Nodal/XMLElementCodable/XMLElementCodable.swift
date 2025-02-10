import Foundation

/// A type that can be serialized as an XML element.
///
/// Types conforming to this protocol define how they should be encoded as an XML element within a document.
/// This is useful for structured XML serialization where values are represented as elements.
public protocol XMLElementEncodable {
    /// Encodes the instance into an XML element.
    ///
    /// Implementations should add attributes, child elements or text content on the provided `Node`.
    ///
    /// - Parameter element: The XML node to encode into.
    func encode(to element: Node)
}

/// A type that can be initialized from an XML element.
///
/// Types conforming to this protocol define how they should be decoded from an XML element.
/// This allows structured XML parsing where values are extracted from elements.
///
public protocol XMLElementDecodable {
    /// Initializes an instance from an XML element.
    ///
    /// Implementations should extract relevant values from attributes, child elements, or text content.
    ///
    /// - Parameter element: The XML node to decode from.
    /// - Throws: `XMLElementCodableError` if required data is missing or invalid.
    init(from element: Node) throws
}

/// A type that can be both encoded to and decoded from an XML element.
///
/// Types conforming to this protocol can be seamlessly converted to and from XML elements,
/// allowing structured XML serialization and deserialization.
public typealias XMLElementCodable = XMLElementEncodable & XMLElementDecodable

public enum XMLElementCodableError: Error {
    case elementMissing (any ElementName)
    case containerMissing (any ElementName)
}
