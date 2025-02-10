import Foundation

/// A type that can be represented as a string in XML, either as an attribute value or text content.
///
/// Types conforming to this protocol define how their values should be serialized into an XML-compatible string.
/// This is useful for encoding values into XML attributes, text nodes, or CDATA sections.
public protocol XMLValueEncodable {
    /// Converts the value to an XML-compatible string representation.
    ///
    /// - Returns: A `String` representation suitable for use in an XML attribute or text content.
    var xmlStringValue: String { get }
}

/// A type that can be initialized from an XML-compatible string, used in attributes or text content.
///
/// Types conforming to this protocol define how to **decode** an XML string representation into a Swift value.
/// This allows structured data to be reconstructed from XML documents.
public protocol XMLValueDecodable {
    /// Initializes an instance from an XML-compatible string.
    ///
    /// - Parameter xmlStringValue: The string representation of the value.
    /// - Throws: `XMLValueError.invalidFormat` if the string cannot be parsed.
    init(xmlStringValue: String) throws
}

public typealias XMLValueCodable = XMLValueEncodable & XMLValueDecodable


internal extension Array where Element: XMLValueDecodable {
    init(xmlStringValue: String) throws {
        self = try xmlStringValue
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map {
                try Element.init(xmlStringValue: $0)
            }
    }
}

internal extension Array where Element: XMLValueEncodable {
    var xmlStringValue: String {
        map(\.xmlStringValue).joined(separator: " ")
    }
}

public enum XMLValueError: Error {
    case invalidFormat(expected: String, found: String)
    case missingAttribute (String)
    case missingExpandedAttribute (ExpandedName)
}
