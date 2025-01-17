import Foundation
import pugixml

public struct OutputOptions: OptionSet, Sendable {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    public let rawValue: UInt32
}

public extension OutputOptions {
    // Default formatting: Nodes are indented based on their depth in the DOM tree.
    static let `default`: Self = [.indent]

    // Indent the nodes that are written to output stream with as many indentation strings as the node depth in the DOM tree.
    static let indent = Self(rawValue: pugi.format_indent)

    // Write encoding-specific BOM to the output stream.
    static let writeBOM = Self(rawValue: pugi.format_write_bom)

    // Use raw output mode (no indentation and no line breaks are written).
    static let raw = Self(rawValue: pugi.format_raw)

    // Omit the default XML declaration even if there is no declaration in the document.
    static let noDeclaration = Self(rawValue: pugi.format_no_declaration)

    // Don't escape attribute values and PCDATA contents.
    static let noEscapes = Self(rawValue: pugi.format_no_escapes)

    // Open file using text mode in xml_document::save_file. Enables special character conversions on some systems.
    static let saveFileText = Self(rawValue: pugi.format_save_file_text)

    // Write every attribute on a new line with appropriate indentation.
    static let indentAttributes = Self(rawValue: pugi.format_indent_attributes)

    // Don't output empty element tags. Instead, write explicit start and end tags even if there are no children.
    static let noEmptyElementTags = Self(rawValue: pugi.format_no_empty_element_tags)

    // Skip characters in the range [0; 32) instead of encoding them as "&#xNN;".
    static let skipControlChars = Self(rawValue: pugi.format_skip_control_chars)

    // Use single quotes (' ') instead of double quotes (" ") for enclosing attribute values.
    static let attributeSingleQuote = Self(rawValue: pugi.format_attribute_single_quote)
}
