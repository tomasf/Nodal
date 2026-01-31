@testable import Nodal
import Foundation
import Testing

struct ErrorTests {
    // MARK: - XMLValueError

    @Test
    func missingStringAttribute() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!

        #expect(throws: XMLValueError.self) {
            let _: String = try root.value(forAttribute: "missing")
        }

        do {
            let _: String = try root.value(forAttribute: "missing")
            Issue.record("Expected missingAttribute error")
        } catch let error as XMLValueError {
            if case .missingAttribute(let name) = error {
                #expect(name == "missing")
            } else {
                Issue.record("Wrong XMLValueError case")
            }
        }
    }

    @Test
    func missingExpandedAttribute() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!
        let expandedName = ExpandedName(namespaceName: "http://example.com", localName: "attr")

        #expect(throws: XMLValueError.self) {
            let _: String = try root.value(forAttribute: expandedName)
        }

        do {
            let _: String = try root.value(forAttribute: expandedName)
            Issue.record("Expected missingExpandedAttribute error")
        } catch let error as XMLValueError {
            if case .missingExpandedAttribute(let name) = error {
                #expect(name == expandedName)
            } else {
                Issue.record("Wrong XMLValueError case")
            }
        }
    }

    @Test
    func invalidFormatError() throws {
        let doc = try Document(string: "<root value=\"abc\"/>")
        let root = doc.documentElement!

        #expect(throws: XMLValueError.self) {
            let _: Int = try root.value(forAttribute: "value")
        }

        do {
            let _: Int = try root.value(forAttribute: "value")
            Issue.record("Expected invalidFormat error")
        } catch let error as XMLValueError {
            if case .invalidFormat(let expected, let found) = error {
                #expect(!expected.isEmpty)
                #expect(found == "abc")
            } else {
                Issue.record("Wrong XMLValueError case")
            }
        }
    }

    @Test
    func invalidDoubleFormat() throws {
        let doc = try Document(string: "<root value=\"not-a-number\"/>")
        let root = doc.documentElement!

        #expect(throws: XMLValueError.self) {
            let _: Double = try root.value(forAttribute: "value")
        }
    }

    @Test
    func invalidBoolFormat() throws {
        let doc = try Document(string: "<root value=\"maybe\"/>")
        let root = doc.documentElement!

        #expect(throws: XMLValueError.self) {
            let _: Bool = try root.value(forAttribute: "value")
        }
    }

    @Test
    func optionalAttributeReturnsNil() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!

        let value: String? = try root.value(forAttribute: "missing")
        #expect(value == nil)
    }

    // MARK: - XMLElementCodableError

    struct SimpleElement: XMLElementDecodable {
        let name: String

        init(from element: Node) throws {
            name = try element.value(forAttribute: "name")
        }
    }

    @Test
    func elementMissing() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!

        #expect(throws: XMLElementCodableError.self) {
            let _: SimpleElement = try root.decode(elementName: "missing")
        }

        do {
            let _: SimpleElement = try root.decode(elementName: "missing")
            Issue.record("Expected elementMissing error")
        } catch let error as XMLElementCodableError {
            if case .elementMissing(let name) = error {
                #expect(name == "missing")
            } else {
                Issue.record("Wrong XMLElementCodableError case")
            }
        }
    }

    @Test
    func expandedElementMissing() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!
        let expandedName = ExpandedName(namespaceName: "http://example.com", localName: "element")

        #expect(throws: XMLElementCodableError.self) {
            let _: SimpleElement = try root.decode(elementName: expandedName)
        }

        do {
            let _: SimpleElement = try root.decode(elementName: expandedName)
            Issue.record("Expected expandedElementMissing error")
        } catch let error as XMLElementCodableError {
            if case .expandedElementMissing(let name) = error {
                #expect(name == expandedName)
            } else {
                Issue.record("Wrong XMLElementCodableError case")
            }
        }
    }

    @Test
    func documentElementMissing() throws {
        let doc = Document()
        // Empty document has no document element

        #expect(throws: XMLElementCodableError.self) {
            let _: SimpleElement = try doc.node.decode(elementName: "root")
        }
    }

    @Test
    func optionalElementReturnsNil() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!

        let element: SimpleElement? = try root.decode(elementName: "missing")
        #expect(element == nil)
    }

    @Test
    func arrayDecodeReturnsEmpty() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!

        let elements: [SimpleElement] = try root.decode(elementName: "missing")
        #expect(elements.isEmpty)
    }

    // MARK: - Content Errors

    @Test
    func invalidContentFormat() throws {
        let doc = try Document(string: "<root>not-an-int</root>")
        let root = doc.documentElement!

        #expect(throws: XMLValueError.self) {
            let _: Int = try root.content()
        }
    }

    @Test
    func emptyContentConversion() throws {
        let doc = try Document(string: "<root/>")
        let root = doc.documentElement!

        // Empty string content should fail for Int
        #expect(throws: XMLValueError.self) {
            let _: Int = try root.content()
        }
    }

    // MARK: - Array Value Errors

    @Test
    func invalidArrayElementFormat() throws {
        let doc = try Document(string: "<root values=\"1 two 3\"/>")
        let root = doc.documentElement!

        #expect(throws: XMLValueError.self) {
            let _: [Int] = try root.value(forAttribute: "values")
        }
    }

    // MARK: - Nested Decoding Errors

    struct Parent: XMLElementDecodable {
        let child: SimpleElement

        init(from element: Node) throws {
            child = try element.decode(elementName: "child")
        }
    }

    @Test
    func nestedElementMissing() throws {
        let doc = try Document(string: "<parent/>")
        let root = doc.documentElement!

        #expect(throws: XMLElementCodableError.self) {
            _ = try Parent(from: root)
        }
    }

    @Test
    func nestedAttributeInvalid() throws {
        let doc = try Document(string: "<parent><child/></parent>")
        let root = doc.documentElement!

        // Child exists but lacks required "name" attribute
        #expect(throws: XMLValueError.self) {
            _ = try Parent(from: root)
        }
    }
}
