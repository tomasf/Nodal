import Foundation
import pugixml

public extension Document {
    struct ParseOptions: OptionSet, Sendable {
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        public let rawValue: UInt32
    }
}

public extension Document.ParseOptions {
    /// The default parsing options, including CDATA, escape expansion, normalized attribute values, and normalized EOL characters.
    static let `default`: Self = [.includeCDATA, .expandEscapes, .normalizeAttributeValuesCDATA, .normalizeEOLCharacters]

    /// Includes the document type declaration (`Kind.doctype`) in the parsed tree.
    /// When disabled, the doctype is parsed and checked for correctness but not included in the tree.
    static let includeDTD = Self(rawValue: pugi.parse_doctype)

    /// Includes processing instructions (`Kind.processingInstruction`) in the parsed tree.
    /// When disabled, processing instructions are parsed and checked for correctness but not included in the tree.
    static let includeProcessingInstructions = Self(rawValue: pugi.parse_pi)

    /// Includes comments (`Kind.comment`) in the parsed tree.
    /// When disabled, comments are parsed and checked for correctness but not included in the tree.
    static let includeComments = Self(rawValue: pugi.parse_comments)

    /// Includes CDATA sections (`Kind.cdata`) in the parsed tree.
    /// When disabled, CDATA sections are parsed and checked for correctness but not included in the tree.
    static let includeCDATA = Self(rawValue: pugi.parse_cdata)

    /// Includes the XML declaration (`Kind.declaration`) in the parsed tree.
    /// When disabled, the declaration is parsed and checked for correctness but not included in the tree.
    static let includeDeclaration = Self(rawValue: pugi.parse_declaration)

    /// Includes whitespace-only text nodes (`Kind.text`) in the parsed tree.
    /// When disabled, whitespace-only text nodes are omitted to save memory and simplify document processing.
    static let includeWhitespaceText = Self(rawValue: pugi.parse_ws_pcdata)

    /// Includes whitespace-only text nodes with no sibling nodes (`Kind.text`) in the parsed tree.
    /// Useful for parsing specific whitespace content while omitting other whitespace nodes.
    /// Has no effect if `includeWhitespaceText` is enabled.
    static let includeSingleWhitespaceText = Self(rawValue: pugi.parse_ws_pcdata_single)

    /// Trims leading and trailing whitespace from text nodes (`Kind.text`) in the parsed tree.
    /// Useful for applications where surrounding whitespace is not significant.
    static let trimTextWhitespace = Self(rawValue: pugi.parse_trim_pcdata)

    /// Merges adjacent text nodes (`Kind.text`) into a single node in the parsed tree.
    /// This reduces memory usage and simplifies text node handling.
    /// Incompatible with `parse_embed_pcdata`.
    static let mergeAdjecentText = Self(rawValue: pugi.parse_merge_pcdata)

    /// Expands escape sequences (e.g., `&amp;` → `&`) in the parsed tree.
    /// Ensures that special characters are represented as their unescaped equivalents.
    static let expandEscapes = Self(rawValue: pugi.parse_escapes)

    /// Normalizes end-of-line characters to `\n` in the parsed tree.
    /// Ensures consistent handling of line endings across different XML sources.
    static let normalizeEOLCharacters = Self(rawValue: pugi.parse_eol)

    /// Normalizes attribute values containing CDATA sections in the parsed tree.
    /// Ensures consistent representation of attributes that include CDATA content.
    static let normalizeAttributeValuesCDATA = Self(rawValue: pugi.parse_wconv_attribute)

    /// Normalizes attribute values to conform to the NMTOKENS data type in the parsed tree.
    /// Enforces proper formatting of attributes as per the NMTOKENS specification.
    static let normalizeAttributeValuesNMTOKENS = Self(rawValue: pugi.parse_wnorm_attribute)
}
