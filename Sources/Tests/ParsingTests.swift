@testable import Nodal
import Foundation
import Testing

struct ParsingTests {
    // MARK: - Malformed XML

    @Test
    func badEndElement() {
        #expect(throws: Document.ParseError.self) {
            _ = try Document(string: "<root><unclosed></root>")
        }
    }

    @Test
    func endElementMismatch() {
        do {
            _ = try Document(string: "<a></b>")
            Issue.record("Expected endElementMismatch error")
        } catch let error as Document.ParseError {
            #expect(error.reason == .endElementMismatch)
        }
    }

    @Test
    func badAttribute() {
        #expect(throws: Document.ParseError.self) {
            _ = try Document(string: "<root attr=noQuotes/>")
        }
    }

    @Test
    func badComment() {
        #expect(throws: Document.ParseError.self) {
            _ = try Document(string: "<root><!- bad --></root>")
        }
    }

    @Test
    func badCDATA() {
        #expect(throws: Document.ParseError.self) {
            _ = try Document(string: "<root><![CDATA[unclosed</root>")
        }
    }

    @Test
    func badStartElement() {
        #expect(throws: Document.ParseError.self) {
            _ = try Document(string: "<123invalid/>")
        }
    }

    // MARK: - Encoding

    @Test
    func utf16Parsing() throws {
        let xmlString = "<?xml version=\"1.0\" encoding=\"UTF-16\"?><root>Hello</root>"
        let utf16Data = xmlString.data(using: .utf16)!
        let doc = try Document(data: utf16Data)
        #expect(doc.documentElement?.textContent == "Hello")
    }

    @Test
    func latin1Parsing() throws {
        let xmlString = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><root>Héllo</root>"
        let latin1Data = xmlString.data(using: .isoLatin1)!
        let doc = try Document(data: latin1Data, encoding: .isoLatin1)
        #expect(doc.documentElement?.textContent == "Héllo")
    }

    @Test
    func dataWithEncodingRoundTrip() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root.textContent = "Ünïcödé"

        let utf16Data = try doc.xmlData(encoding: .utf16)
        let reparsed = try Document(data: utf16Data)
        #expect(reparsed.documentElement?.textContent == "Ünïcödé")
    }

    // MARK: - File I/O

    @Test
    func fileNotFound() {
        let nonexistentURL = URL(fileURLWithPath: "/nonexistent/path/to/file.xml")
        do {
            _ = try Document(url: nonexistentURL)
            Issue.record("Expected fileNotFound error")
        } catch let error as Document.ParseError {
            #expect(error.reason == .fileNotFound)
        }
    }

    // MARK: - Parse Options

    @Test
    func whitespacePreservation() throws {
        let xml = "<root>  text  </root>"

        // Without whitespace preservation (default), whitespace is trimmed or ignored
        let defaultDoc = try Document(string: xml)
        let defaultText = defaultDoc.documentElement?.textContent ?? ""

        // With whitespace preservation
        let preservedDoc = try Document(string: xml, options: [.default, .includeWhitespaceText])
        let preservedText = preservedDoc.documentElement?.textContent ?? ""

        #expect(preservedText == "  text  ")
        #expect(defaultText == "  text  ") // Both preserve text content by default
    }

    @Test
    func trimWhitespace() throws {
        let xml = "<root>  text  </root>"
        let doc = try Document(string: xml, options: [.default, .trimTextWhitespace])
        #expect(doc.documentElement?.textContent == "text")
    }

    @Test
    func includeComments() throws {
        let xml = "<root><!--comment--></root>"

        let withComments = try Document(string: xml, options: [.default, .includeComments])
        let commentCount = withComments.documentElement?.children.filter { $0.kind == .comment }.count ?? 0
        #expect(commentCount == 1)

        let withoutComments = try Document(string: xml)
        let noCommentCount = withoutComments.documentElement?.children.filter { $0.kind == .comment }.count ?? 0
        #expect(noCommentCount == 0)
    }

    @Test
    func includeProcessingInstructions() throws {
        let xml = "<root><?pi target?></root>"

        let withPI = try Document(string: xml, options: [.default, .includeProcessingInstructions])
        let piCount = withPI.documentElement?.children.filter { $0.kind == .processingInstruction }.count ?? 0
        #expect(piCount == 1)

        let withoutPI = try Document(string: xml)
        let noPiCount = withoutPI.documentElement?.children.filter { $0.kind == .processingInstruction }.count ?? 0
        #expect(noPiCount == 0)
    }

    @Test
    func includeDeclaration() throws {
        let xml = "<?xml version=\"1.0\"?><root/>"

        let withDecl = try Document(string: xml, options: [.default, .includeDeclaration])
        let declCount = withDecl.node.children.filter { $0.kind == .declaration }.count
        #expect(declCount == 1)

        let withoutDecl = try Document(string: xml)
        let noDeclCount = withoutDecl.node.children.filter { $0.kind == .declaration }.count
        #expect(noDeclCount == 0)
    }

    @Test
    func expandEscapes() throws {
        let xml = "<root>&lt;escaped&gt;</root>"

        let doc = try Document(string: xml)
        #expect(doc.documentElement?.textContent == "<escaped>")
    }

    // MARK: - Error Details

    @Test
    func parseErrorOffset() {
        let xml = "<root><valid/><invalid</root>"
        do {
            _ = try Document(string: xml)
            Issue.record("Expected parse error")
        } catch let error as Document.ParseError {
            #expect(error.offset > 0)
            #expect(!error.description.isEmpty)
        }
    }
}
