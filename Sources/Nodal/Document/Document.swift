import Foundation
import pugixml
import Bridge

public class Document: Node {
    internal var pugiDocument = pugi.xml_document()
    internal var objectDirectory = PointerToObjectMap<Element>(strength: .weak)
    internal var pendingNamespaceRecords = PointerToObjectMap<PendingNameRecord>(strength: .strong)

    internal required init(owningDocument: Document?, node: pugi.xml_node) {
        super.init(owningDocument: nil, node: pugiDocument.asNode)
    }

    public override var document: Document {
        self
    }

    public override func xmlData(
        encoding: String.Encoding = .utf8,
        options: OutputOptions = .default,
        indentation: String = .fourSpaces
    ) throws(OutputError) -> Data {

        let undeclared = document.undeclaredNamespaceNames
        guard undeclared.isEmpty else {
            throw .undeclaredNamespaces(undeclared)
        }

        var data = Data()
        xml_document_save_with_block(pugiDocument, indentation, options.rawValue, encoding.pugiEncoding) { rawPointer, length in
            guard let rawPointer else { return }
            data.append(rawPointer.assumingMemoryBound(to: UInt8.self), count: length)
        }
        return data
    }
}

public extension Document {
    convenience init(xmlString: String, options: ParseOptions = .default) throws(ParseError) {
        self.init()
        let result = pugiDocument.load_string(xmlString, options.rawValue)
        if result.status != pugi.status_ok {
            throw ParseError(result)
        }
    }

    convenience init(xmlData data: Data, encoding: String.Encoding? = nil, options: ParseOptions = .default) throws(ParseError) {
        self.init()
        let result = data.withUnsafeBytes { bufferPointer in
            pugiDocument.load_buffer(bufferPointer.baseAddress, bufferPointer.count, options.rawValue, encoding?.pugiEncoding ?? pugi.encoding_auto)
        }
        if result.status != pugi.status_ok {
            throw ParseError(result)
        }
    }

    convenience init(url: URL, encoding: String.Encoding? = nil, options: ParseOptions = .default) throws(ParseError) {
        self.init()
        let result = url.withUnsafeFileSystemRepresentation { path in
            pugiDocument.load_file(path, options.rawValue, encoding?.pugiEncoding ?? pugi.encoding_auto)
        }
        if result.status != pugi.status_ok {
            throw ParseError(result)
        }
    }

    // Create a new empty XML document
    convenience init() {
        self.init(owningDocument: nil, node: .init())
    }
}

internal extension Document {
    func clearRootElement() -> Element {
        if let oldRoot = documentElement {
            removeChild(oldRoot)
        }
        let rootNode = pugiDocument.append_child(pugi.node_element)
        return element(for: rootNode)
    }
}

internal extension Document {
    func pendingNameRecord(for element: Element) -> PendingNameRecord? {
        pendingNamespaceRecords[element.nodePointer]
    }

    func addPendingNameRecord(for element: Element) -> PendingNameRecord {
        let record = PendingNameRecord(element: element)
        pendingNamespaceRecords[element.nodePointer] = record
        return record
    }

    func removePendingRecord(for element: Element) {
        pendingNamespaceRecords[element.nodePointer] = nil
    }

    func pendingNameRecords(forDescendantsOf parent: Element) -> [(Element, PendingNameRecord)] {
        pendingNamespaceRecords.contents.compactMap {
            $1.belongsToTree(parent) ? (element(for: .init($0)), $1) : nil
        }
    }

    var pendingNameRecordCount: Int {
        pendingNamespaceRecords.count
    }
}

public extension Document {
    var documentElement: Element? {
        let root = pugiDocument.__document_elementUnsafe()
        return root.empty() ? nil : element(for: root)
    }

    func makeDocumentElement(name: String, defaultNamespace uri: String? = nil) -> Element {
        let element = clearRootElement()
        element.name = name
        if let uri {
            element.declareNamespace(uri, forPrefix: nil)
        }
        return element
    }

    func makeDocumentElement(name: ExpandedName, declaringNamespaceFor prefix: String) -> Element {
        let element = clearRootElement()
        if let uri = name.namespaceName {
            element.declareNamespace(uri, forPrefix: prefix)
            element.expandedName = name
        } else {
            element.name = name.localName
        }
        return element
    }

    var undeclaredNamespaceNames: Set<String> {
        Set(pendingNamespaceRecords.contents.flatMap(\.value.namespaceNames))
    }

    func save(
        to fileURL: URL,
        encoding: String.Encoding = .utf8,
        options: OutputOptions = .default,
        indentation: String = .fourSpaces
    ) throws {
        FileManager().createFile(atPath: fileURL.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        fileHandle.truncateFile(atOffset: 0)
        defer { fileHandle.closeFile() }

        xml_document_save_with_block(pugiDocument, indentation, options.rawValue, encoding.pugiEncoding) { buffer, length in
            guard let buffer else { return }
            fileHandle.write(Data(bytes: buffer, count: length))
        }
    }
}

