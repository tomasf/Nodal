import Foundation
import pugixml

internal extension String.Encoding {
    var pugiEncoding: pugi.xml_encoding {
        switch self {
        case .utf8: return pugi.encoding_utf8
        case .utf16LittleEndian: return pugi.encoding_utf16_le
        case .utf16BigEndian: return pugi.encoding_utf16_be
        case .utf16: return pugi.encoding_utf16
        case .utf32LittleEndian: return pugi.encoding_utf32_le
        case .utf32BigEndian: return pugi.encoding_utf32_be
        case .utf32: return pugi.encoding_utf32
        case .isoLatin1: return pugi.encoding_latin1
        default: return pugi.encoding_auto
        }
    }

    init(_ pugiEncoding: pugi.xml_encoding) {
        switch pugiEncoding {
        case pugi.encoding_utf8: self = .utf8
        case pugi.encoding_utf16_le: self = .utf16LittleEndian
        case pugi.encoding_utf16_be: self = .utf16BigEndian
        case pugi.encoding_utf16: self = .utf16
        case pugi.encoding_utf32_le: self = .utf32LittleEndian
        case pugi.encoding_utf32_be: self = .utf32BigEndian
        case pugi.encoding_utf32: self = .utf32
        case pugi.encoding_latin1: self = .isoLatin1
        default: self = .utf8
        }
    }
}
