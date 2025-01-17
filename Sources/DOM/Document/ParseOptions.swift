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
    static let `default`: Self = [.includeCDATA, .expandEscapes, .normalizeAttributeValuesCDATA, .normalizeEOLCharacters]

    static let includeDTD = Self(rawValue: pugi.parse_doctype)
    static let includeProcessingInstructions = Self(rawValue: pugi.parse_pi)
    static let includeComments = Self(rawValue: pugi.parse_comments)
    static let includeCDATA = Self(rawValue: pugi.parse_cdata)

    static let includeWhitespaceText = Self(rawValue: pugi.parse_ws_pcdata)
    static let includeSingleWhitespaceText = Self(rawValue: pugi.parse_ws_pcdata_single)
    static let trimTextWhitespace = Self(rawValue: pugi.parse_trim_pcdata)
    static let mergeAdjecentText = Self(rawValue: pugi.parse_merge_pcdata)

    static let expandEscapes = Self(rawValue: pugi.parse_escapes)
    static let normalizeEOLCharacters = Self(rawValue: pugi.parse_eol)
    static let normalizeAttributeValuesCDATA = Self(rawValue: pugi.parse_wconv_attribute)
    static let normalizeAttributeValuesNMTOKENS = Self(rawValue: pugi.parse_wnorm_attribute)
}
