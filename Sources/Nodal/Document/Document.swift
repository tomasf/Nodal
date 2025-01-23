import Foundation
import pugixml
import Bridge

/// Represents an XML document node, providing methods for working with the document structure and serialization.
public class Document: Node {
    internal var pugiDocument = pugi.xml_document()
    internal var pendingNamespaceRecords: [OpaquePointer: PendingNameRecord] = [:]
    internal var namespaceDeclarationsByPrefix: [NamespaceDeclaration.Prefix: [NamespaceDeclaration]] = [:]
    internal var namespaceDeclarationsByName: [String: [NamespaceDeclaration]] = [:]

    /// Creates a new, empty XML document.
    ///
    /// - Note: This initializer creates a document with no content. Elements can be added manually using the API.
    public init() {
        super.init(owningDocument: nil, node: self.pugiDocument.asNode)
    }

    public override var document: Document {
        self
    }

    /// A set of namespace names that are referenced in the document but have not been declared.
    ///
    /// - Note: This property helps identify undeclared namespaces that need to be resolved to generate XML output.
    public var undeclaredNamespaceNames: Set<String> {
        Set(pendingNamespaceRecords.flatMap(\.value.namespaceNames))
    }

    private func save(encoding: String.Encoding = .utf8,
              options: OutputOptions = .default,
              indentation: String = .fourSpaces,
              output: @escaping (Data) -> ()
    ) throws(OutputError) {
        let undeclared = document.undeclaredNamespaceNames
        guard undeclared.isEmpty else {
            throw .undeclaredNamespaces(undeclared)
        }

        xml_document_save_with_block(pugiDocument, indentation, options.rawValue, encoding.pugiEncoding) { buffer, length in
            guard let buffer else { return }
            output(Data(bytes: buffer, count: length))
        }
    }

    /// Saves the XML document to a specified file URL with the given encoding and options.
    ///
    /// - Parameters:
    ///   - fileURL: The location where the XML document should be saved.
    ///   - encoding: The string encoding to use for the file. Defaults to `.utf8`.
    ///   - options: The options for XML output formatting. Defaults to `.default`.
    ///   - indentation: The string to use for indentation in the XML output. Defaults to `.fourSpaces`.
    /// - Throws: `OutputError` if the document contains undeclared namespaces or if an error occurs during serialization.
    ///           Also throws any file-related errors encountered while saving to the provided URL.
    public func save(
        to fileURL: URL,
        encoding: String.Encoding = .utf8,
        options: OutputOptions = .default,
        indentation: String = .fourSpaces
    ) throws {
        FileManager().createFile(atPath: fileURL.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        fileHandle.truncateFile(atOffset: 0)
        defer { fileHandle.closeFile() }

        try save(encoding: encoding, options: options, indentation: indentation) { chunk in
            fileHandle.write(chunk)
        }
    }

    /// Generates the XML data representation of the document with specified options.
    ///
    /// - Parameters:
    ///   - encoding: The string encoding to use for the output. Defaults to `.utf8`.
    ///   - options: The options for XML output formatting. Defaults to `.default`.
    ///   - indentation: The string to use for indentation in the XML output. Defaults to `.fourSpaces`.
    /// - Returns: A `Data` object containing the serialized XML representation of the document.
    /// - Throws: `OutputError` if the document contains undeclared namespaces or if an error occurs during serialization.
    public override func xmlData(
        encoding: String.Encoding = .utf8,
        options: OutputOptions = .default,
        indentation: String = .fourSpaces
    ) throws(OutputError) -> Data {
        var data = Data()
        try save(encoding: encoding, options: options, indentation: indentation) { chunk in
            data.append(chunk)
        }
        return data
    }
}
