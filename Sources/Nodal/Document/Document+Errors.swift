import Foundation
import pugixml

public extension Document {
    /// Represents an error that occurs during the parsing of an XML document.
    struct ParseError: Error, LocalizedError {
        /// The reason for the parse failure.
        public let reason: Reason

        /// A description of the error that occured.
        public let description: String

        /// The character offset in the input where the error occurred.
        public let offset: Int

        /// The string encoding of the input that was being parsed.
        public let encoding: String.Encoding

        internal init(_ result: pugi.xml_parse_result) {
            self.reason = .init(result.status)
            self.offset = result.offset
            self.encoding = .init(result.encoding)
            self.description = String(cString: result.description())
        }

        /// Represents the specific reason for a parse failure.
        public enum Reason: Sendable {
            /// The file was not found during parsing.
            case fileNotFound

            /// An I/O error occurred while reading the file or stream.
            case readError

            /// Memory allocation failed during parsing.
            case outOfMemory

            /// The parser encountered a malformed tag name.
            case badTagName

            /// A start element tag was malformed.
            case badStartElement

            /// An end element tag was malformed.
            case badEndElement

            /// A mismatch occurred between a start tag and an end tag.
            case endElementMismatch

            /// An attribute was malformed.
            case badAttribute

            /// A processing instruction or document declaration was malformed.
            case badProcessingInstruction

            /// A comment was malformed.
            case badComment

            /// A text section was malformed.
            case badText

            /// A CDATA section was malformed.
            case badCDATA

            /// A document type declaration was malformed.
            case badDOCTYPE

            /// An attempt was made to append nodes to an invalid root type.
            case appendInvalidRoot

            /// The document lacks any element nodes.
            case noDocumentElement

            /// An unknown error occurred.
            case unknown

            internal init(_ pugiStatus: pugi.xml_parse_status) {
                switch pugiStatus {
                case pugi.status_file_not_found: self = .fileNotFound
                case pugi.status_io_error: self = .readError
                case pugi.status_out_of_memory: self = .outOfMemory
                case pugi.status_unrecognized_tag: self = .badTagName
                case pugi.status_bad_pi: self = .badProcessingInstruction
                case pugi.status_bad_comment: self = .badComment
                case pugi.status_bad_cdata: self = .badCDATA
                case pugi.status_bad_doctype: self = .badDOCTYPE
                case pugi.status_bad_pcdata: self = .badText
                case pugi.status_bad_start_element: self = .badStartElement
                case pugi.status_bad_attribute: self = .badAttribute
                case pugi.status_bad_end_element: self = .badEndElement
                case pugi.status_end_element_mismatch: self = .endElementMismatch
                case pugi.status_append_invalid_root: self = .appendInvalidRoot
                case pugi.status_no_document_element: self = .noDocumentElement
                case pugi.status_internal_error: self = .unknown
                default: self = .unknown
                }
            }
        }
    }

    enum OutputError: Error {
        /// One or more namespaces were referenced but not declared.
        ///
        /// - Parameter undeclaredNamespaces: A set of undeclared namespace names that caused the error.
        ///
        /// - Discussion:
        ///   To resolve this error, ensure that all referenced namespaces are declared within the document.
        ///   Namespaces can be declared using the `declareNamespace(_:forPrefix:)` method on an `Element`.
        ///
        ///   ### Declaring a Namespace
        ///   - To declare a namespace with a prefix:
        ///     ```swift
        ///     let root = document.makeDocumentElement(name: "root")
        ///     root.declareNamespace("http://example.com/namespace", forPrefix: "ex")
        ///     ```
        ///
        ///   - To declare a default namespace (without a prefix):
        ///     ```swift
        ///     root.declareNamespace("http://example.com/default", forPrefix: nil)
        ///     ```
        ///
        ///   ### Important Notes
        ///   - Attributes can not be part of a default namespace. They must always belong to a namespace with an explicit prefix, or no namespace at all.
        case undeclaredNamespaces (Set<String>)
    }
}
