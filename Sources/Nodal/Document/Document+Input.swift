import Foundation
import pugixml

public extension Document {
    /// Creates an XML document by parsing the given XML string.
    ///
    /// - Parameters:
    ///   - string: A string containing the XML content to parse.
    ///   - options: The parsing options to use. Defaults to `.default`.
    /// - Throws: `ParseError` if the parsing fails due to malformed XML or other issues.
    ///
    /// - Note: This initializer parses the entire string and builds the corresponding document tree.
    convenience init(string: String, options: ParseOptions = .default) throws(ParseError) {
        self.init()
        try finishSetup(withResult: pugiDocument.load_string(string, options.rawValue))
    }

    /// Creates an XML document by parsing the given data.
    ///
    /// - Parameters:
    ///   - data: A `Data` object containing the XML content to parse.
    ///   - encoding: The character encoding to use. If `nil`, the encoding is automatically detected. Defaults to `nil`.
    ///   - options: The parsing options to use. Defaults to `.default`.
    /// - Throws: `ParseError` if the parsing fails due to malformed XML or other issues.
    ///
    /// - Note: This initializer parses the data and builds the corresponding document tree.
    convenience init(data: Data, encoding: String.Encoding? = nil, options: ParseOptions = .default) throws(ParseError) {
        self.init()
        try finishSetup(withResult: data.withUnsafeBytes { bufferPointer in
            pugiDocument.load_buffer(bufferPointer.baseAddress, bufferPointer.count, options.rawValue, encoding?.pugiEncoding ?? pugi.encoding_auto)
        })
    }

    /// Creates an XML document by loading and parsing the content of a file at the specified URL.
    ///
    /// - Parameters:
    ///   - url: The file URL pointing to the XML document to parse.
    ///   - encoding: The character encoding to use. If `nil`, the encoding is automatically detected. Defaults to `nil`.
    ///   - options: The parsing options to use. Defaults to `.default`.
    /// - Throws: `ParseError` if the parsing fails due to malformed XML, file access issues, or other errors.
    ///
    /// - Note: This initializer reads the file from the provided URL and builds the corresponding document tree.
    convenience init(url fileURL: URL, encoding: String.Encoding? = nil, options: ParseOptions = .default) throws(ParseError) {
        self.init()
        try finishSetup(withResult: fileURL.withUnsafeFileSystemRepresentation { path in
            pugiDocument.load_file(path, options.rawValue, encoding?.pugiEncoding ?? pugi.encoding_auto)
        })
    }
}

internal extension Document {
    func finishSetup(withResult parseResult: pugi.xml_parse_result) throws(ParseError) {
        if parseResult.status != pugi.status_ok {
            throw ParseError(parseResult)
        }
        rebuildNamespaceDeclarationCache()
    }
}
