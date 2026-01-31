@testable import Nodal
import Foundation
import Testing

struct OutputTests {
    // MARK: - Output Options

    @Test
    func writeBOM() throws {
        let doc = Document()
        _ = doc.makeDocumentElement(name: "root")

        let dataWithBOM = try doc.xmlData(options: [.default, .writeBOM])
        // UTF-8 BOM is EF BB BF
        let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
        let prefix = Array(dataWithBOM.prefix(3))
        #expect(prefix == bom)

        let dataWithoutBOM = try doc.xmlData()
        let prefixNoBOM = Array(dataWithoutBOM.prefix(3))
        #expect(prefixNoBOM != bom)
    }

    @Test
    func noDeclaration() throws {
        let doc = Document()
        _ = doc.makeDocumentElement(name: "root")

        let withDeclaration = try doc.xmlString()
        #expect(withDeclaration.contains("<?xml"))

        let withoutDeclaration = try doc.xmlString(options: [.default, .noDeclaration])
        #expect(!withoutDeclaration.contains("<?xml"))
    }

    @Test
    func noEmptyElementTags() throws {
        let doc = Document()
        _ = doc.makeDocumentElement(name: "empty")

        let defaultOutput = try doc.xmlString(options: .raw)
        #expect(defaultOutput.contains("<empty/>") || defaultOutput.contains("<empty />"))

        let explicitTags = try doc.xmlString(options: [.raw, .noEmptyElementTags])
        #expect(explicitTags.contains("<empty></empty>"))
    }

    @Test
    func indentAttributes() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root[attribute: "attr1"] = "value1"
        root[attribute: "attr2"] = "value2"

        let indented = try doc.xmlString(options: [.default, .indentAttributes])
        // Each attribute should be on a new line
        let lines = indented.split(separator: "\n")
        #expect(lines.count >= 3) // Declaration, root start with attrs on separate lines
    }

    @Test
    func attributeSingleQuote() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root[attribute: "attr"] = "value"

        let singleQuote = try doc.xmlString(options: [.raw, .attributeSingleQuote])
        #expect(singleQuote.contains("attr='value'"))

        let doubleQuote = try doc.xmlString(options: .raw)
        #expect(doubleQuote.contains("attr=\"value\""))
    }

    @Test
    func rawOutput() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        _ = root.addElement("child")

        let raw = try doc.xmlString(options: .raw)
        #expect(!raw.contains("\n") || raw.components(separatedBy: "\n").count <= 2)

        let formatted = try doc.xmlString(options: .default)
        #expect(formatted.contains("\n"))
    }

    @Test
    func customIndentation() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        _ = root.addElement("child")

        let tabIndent = try doc.xmlString(options: .default, indentation: "\t")
        #expect(tabIndent.contains("\t<child"))

        let twoSpaces = try doc.xmlString(options: .default, indentation: "  ")
        #expect(twoSpaces.contains("  <child"))
    }

    // MARK: - Namespace Output

    @Test
    func undeclaredNamespaceError() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        _ = root.addElement("child", namespace: "http://undeclared.example.com")

        // Note: More idiomatic test code triggers Swift 6.2 compiler bug (rdar://FB...).
        // Using explicit error extraction as workaround.
        var caughtNamespaces: Set<String>?
        do {
            _ = try doc.xmlData()
        } catch {
            if case Document.OutputError.undeclaredNamespaces(let ns) = error {
                caughtNamespaces = ns
            }
        }
        #expect(caughtNamespaces?.contains("http://undeclared.example.com") == true)
    }

    @Test
    func declaredNamespaceOutput() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root.declareNamespace("http://example.com", forPrefix: "ex")
        _ = root.addElement("child", namespace: "http://example.com")

        let output = try doc.xmlString(options: .raw)
        #expect(output.contains("xmlns:ex"))
        #expect(output.contains("ex:child"))
    }

    // MARK: - Round-trip

    @Test
    func preserveStructure() throws {
        let original = Document()
        let root = original.makeDocumentElement(name: "root")
        root[attribute: "id"] = "123"
        let child = root.addElement("child")
        child.textContent = "Hello World"
        _ = root.addElement("empty")

        let serialized = try original.xmlString(options: .raw)
        let reparsed = try Document(string: serialized)

        #expect(reparsed.documentElement?.name == "root")
        #expect(reparsed.documentElement?[attribute: "id"] == "123")
        #expect(reparsed.documentElement?[element: "child"]?.textContent == "Hello World")
        #expect(reparsed.documentElement?[element: "empty"] != nil)
    }

    @Test
    func preserveNamespaces() throws {
        let original = Document()
        let root = original.makeDocumentElement(name: "root")
        root.declareNamespace("http://example.com", forPrefix: "ex")
        root.declareNamespace("http://default.com", forPrefix: nil)
        let child = root.addElement("child", namespace: "http://example.com")
        child[attribute: "attr", namespaceName: "http://example.com"] = "value"

        let serialized = try original.xmlString(options: .raw)
        let reparsed = try Document(string: serialized)

        let reparsedChild = reparsed.documentElement?[element: ExpandedName(namespaceName: "http://example.com", localName: "child")]
        #expect(reparsedChild != nil)
        #expect(reparsedChild?[attribute: "attr", namespaceName: "http://example.com"] == "value")
    }

    @Test
    func preserveCDATA() throws {
        let original = Document()
        let root = original.makeDocumentElement(name: "root")
        _ = root.addCDATA("<script>alert('hello')</script>")

        let serialized = try original.xmlString(options: .raw)
        #expect(serialized.contains("<![CDATA[<script>alert('hello')</script>]]>"))

        let reparsed = try Document(string: serialized)
        let cdataNode = reparsed.documentElement?.children.first { $0.kind == .cdata }
        #expect(cdataNode != nil)
    }

    // MARK: - Encoding Output

    @Test
    func utf16Output() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root.textContent = "Hello"

        let utf16Data = try doc.xmlData(encoding: .utf16)
        // UTF-16 data should be larger than UTF-8 for ASCII content
        let utf8Data = try doc.xmlData(encoding: .utf8)
        #expect(utf16Data.count > utf8Data.count)

        // Should be parseable
        let reparsed = try Document(data: utf16Data)
        #expect(reparsed.documentElement?.textContent == "Hello")
    }

    @Test
    func specialCharacterEscaping() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root.textContent = "<>&\""
        root[attribute: "special"] = "<>&\""

        let output = try doc.xmlString(options: .raw)
        #expect(output.contains("&lt;"))
        #expect(output.contains("&gt;"))
        #expect(output.contains("&amp;"))
    }

    @Test
    func noEscapes() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root.textContent = "test"

        // With noEscapes, special chars won't be escaped (use carefully)
        let output = try doc.xmlString(options: [.raw, .noEscapes])
        #expect(output.contains("<root>test</root>"))
    }
}
