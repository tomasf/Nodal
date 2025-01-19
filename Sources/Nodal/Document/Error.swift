import Foundation
import pugixml

public extension Document {
    struct ParseError: Error {
        public let reason: Reason
        public let offset: Int
        public let encoding: String.Encoding

        internal init(_ result: pugi.xml_parse_result) {
            self.reason = .init(result.status)
            self.offset = result.offset
            self.encoding = .init(result.encoding)
        }

        public enum Reason: Sendable {
            case fileNotFound
            case ioError
            case outOfMemory
            case internalError
            case unrecognizedTag
            case badProcessingInstruction
            case badComment
            case badCData
            case badDoctype
            case badPCDATA
            case badStartElement
            case badAttribute
            case badEndElement
            case endElementMismatch
            case appendInvalidRoot
            case noDocumentElement
            case unknown

            internal init(_ pugiStatus: pugi.xml_parse_status) {
                switch pugiStatus {
                case pugi.status_file_not_found: self = .fileNotFound
                case pugi.status_io_error: self = .ioError
                case pugi.status_out_of_memory: self = .outOfMemory
                case pugi.status_internal_error: self = .internalError
                case pugi.status_unrecognized_tag: self = .unrecognizedTag
                case pugi.status_bad_pi: self = .badProcessingInstruction
                case pugi.status_bad_comment: self = .badComment
                case pugi.status_bad_cdata: self = .badCData
                case pugi.status_bad_doctype: self = .badDoctype
                case pugi.status_bad_pcdata: self = .badPCDATA
                case pugi.status_bad_start_element: self = .badStartElement
                case pugi.status_bad_attribute: self = .badAttribute
                case pugi.status_bad_end_element: self = .badEndElement
                case pugi.status_end_element_mismatch: self = .endElementMismatch
                case pugi.status_append_invalid_root: self = .appendInvalidRoot
                case pugi.status_no_document_element: self = .noDocumentElement
                default: self = .unknown
                }
            }
        }
    }

    enum OutputError: Error {
        case undeclaredNamespaces (Set<String>)
    }
}
