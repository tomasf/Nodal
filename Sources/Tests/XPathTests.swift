@testable import Nodal
import pugixml
import Testing

struct XPathTests {
    @Test
    func generatedPaths() {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.addElement("a")
        let b = root.addElement("b")
        let a2 = root.addElement("a")

        // Implementation details
        #expect(a2.node.precedingSiblings.map(doc.node(for:)) == [b, a])
        #expect(a2.node.elementIndex == 1)

        // Elements
        #expect(doc.node.xPath == "/")
        #expect(root.xPath == "/root[1]")
        #expect(a.xPath == "/root[1]/a[1]")
        #expect(a2.xPath == "/root[1]/a[2]")
        #expect(b.xPath == "/root[1]/b[1]")

        // Comments
        let comment = root.addComment("foo")
        #expect(comment.xPath == "/root[1]/comment()[1]")

        // Text
        let text = a2.addText("bar")
        let cData = a2.addCDATA("baz")
        #expect(text.xPath == "/root[1]/a[2]/text()[1]")
        #expect(cData.xPath == "/root[1]/a[2]/text()[2]")
    }

    // MARK: - Query Execution

    @Test
    func stringResult() throws {
        let doc = try Document(string: "<root><child>Hello World</child></root>")
        let query = try XPathQuery("string(/root/child)")
        let result = query.stringResult(with: doc.node)
        #expect(result == "Hello World")
    }

    @Test
    func doubleResult() throws {
        let doc = try Document(string: "<root><item/><item/><item/></root>")
        let query = try XPathQuery("count(//item)")
        let result = query.doubleResult(with: doc.node)
        #expect(result == 3.0)
    }

    @Test
    func intResult() throws {
        let doc = try Document(string: "<root><item/><item/><item/><item/><item/></root>")
        let query = try XPathQuery("count(//item)")
        let result = query.intResult(with: doc.node)
        #expect(result == 5)
    }

    @Test
    func boolResultTrue() throws {
        let doc = try Document(string: "<root><exists/></root>")
        let query = try XPathQuery("boolean(/root/exists)")
        let result = query.boolResult(with: doc.node)
        #expect(result == true)
    }

    @Test
    func boolResultFalse() throws {
        let doc = try Document(string: "<root/>")
        let query = try XPathQuery("boolean(/root/missing)")
        let result = query.boolResult(with: doc.node)
        #expect(result == false)
    }

    @Test
    func nodesResult() throws {
        let doc = try Document(string: "<root><item id=\"1\"/><item id=\"2\"/><item id=\"3\"/></root>")
        let query = try XPathQuery("//item")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 3)
        #expect(results[0].node?[attribute: "id"] == "1")
        #expect(results[1].node?[attribute: "id"] == "2")
        #expect(results[2].node?[attribute: "id"] == "3")
    }

    @Test
    func firstNodeResult() throws {
        let doc = try Document(string: "<root><item id=\"first\"/><item id=\"second\"/></root>")
        let query = try XPathQuery("//item[1]")
        let result = query.firstNodeResult(with: doc.node)
        #expect(result?.node?[attribute: "id"] == "first")
    }

    @Test
    func emptyResult() throws {
        let doc = try Document(string: "<root/>")
        let query = try XPathQuery("//nonexistent")
        let results = query.nodesResult(with: doc.node)
        #expect(results.isEmpty)
    }

    @Test
    func emptyFirstNodeResult() throws {
        let doc = try Document(string: "<root/>")
        let query = try XPathQuery("//nonexistent")
        let result = query.firstNodeResult(with: doc.node)
        #expect(result == nil)
    }

    // MARK: - Variables

    @Test
    func queryWithStringVariable() throws {
        let doc = try Document(string: "<root><book category=\"fiction\"/><book category=\"science\"/></root>")
        let query = try XPathQuery("//book[@category = $cat]", variables: ["cat": "fiction"])
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
        #expect(results[0].node?[attribute: "category"] == "fiction")
    }

    @Test
    func queryWithIntVariable() throws {
        let doc = try Document(string: "<root><item pos=\"1\"/><item pos=\"2\"/><item pos=\"3\"/></root>")
        let query = try XPathQuery("//item[@pos = $position]", variables: ["position": 2])
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
        #expect(results[0].node?[attribute: "pos"] == "2")
    }

    @Test
    func queryWithDoubleVariable() throws {
        let doc = try Document(string: "<root><price value=\"9.99\"/><price value=\"19.99\"/></root>")
        let query = try XPathQuery("//price[@value > $min]", variables: ["min": 10.0])
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
        #expect(results[0].node?[attribute: "value"] == "19.99")
    }

    // MARK: - Errors

    @Test
    func invalidXPathSyntax() {
        #expect(throws: XPathQuery.ParseError.self) {
            _ = try XPathQuery("[invalid xpath")
        }
    }

    @Test
    func parseErrorOffset() {
        do {
            _ = try XPathQuery("/root[")
            Issue.record("Expected parse error")
        } catch let error as XPathQuery.ParseError {
            #expect(error.offset >= 0)
            #expect(!error.description.isEmpty)
        }
    }

    @Test
    func unclosedString() {
        #expect(throws: XPathQuery.ParseError.self) {
            _ = try XPathQuery("//item[@name='unclosed]")
        }
    }

    @Test
    func invalidFunction() {
        // pugixml throws a parse error for unrecognized functions
        #expect(throws: XPathQuery.ParseError.self) {
            _ = try XPathQuery("unknown_function()")
        }
    }

    // MARK: - Edge Cases

    @Test
    func attributeSelection() throws {
        let doc = try Document(string: "<root><item id=\"a\"/><item id=\"b\"/></root>")
        let query = try XPathQuery("//@id")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 2)
        // XPath returns attribute nodes - access via attributeName and parent node
        #expect(results[0].attributeName == "id")
        #expect(results[0].node?[attribute: "id"] == "a")
        #expect(results[1].attributeName == "id")
        #expect(results[1].node?[attribute: "id"] == "b")
    }

    @Test
    func predicates() throws {
        let doc = try Document(string: """
            <root>
                <item type="a" priority="1"/>
                <item type="b" priority="2"/>
                <item type="a" priority="3"/>
            </root>
        """)
        let query = try XPathQuery("//item[@type='a']")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 2)
        #expect(results[0].node?[attribute: "priority"] == "1")
        #expect(results[1].node?[attribute: "priority"] == "3")
    }

    @Test
    func numericPredicates() throws {
        let doc = try Document(string: "<root><item/><item/><item/></root>")
        let query = try XPathQuery("//item[2]")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
    }

    @Test
    func lastPredicate() throws {
        let doc = try Document(string: "<root><item id=\"1\"/><item id=\"2\"/><item id=\"3\"/></root>")
        let query = try XPathQuery("//item[last()]")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
        #expect(results[0].node?[attribute: "id"] == "3")
    }

    @Test
    func positionPredicate() throws {
        let doc = try Document(string: "<root><item/><item/><item/></root>")
        let query = try XPathQuery("//item[position() > 1]")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 2)
    }

    @Test
    func descendantAxis() throws {
        let doc = try Document(string: "<root><a><b><c/></b></a></root>")
        let query = try XPathQuery("//c")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
        #expect(results[0].node?.name == "c")
    }

    @Test
    func ancestorAxis() throws {
        let doc = try Document(string: "<root><parent><child/></parent></root>")
        let query = try XPathQuery("//child/ancestor::*")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 2) // parent and root
    }

    @Test
    func textNodeSelection() throws {
        let doc = try Document(string: "<root>Hello</root>")
        let query = try XPathQuery("/root/text()")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
        #expect(results[0].node?.kind == .text)
    }

    @Test
    func namespaceQuery() throws {
        let doc = try Document(string: """
            <root xmlns:ns="http://example.com">
                <ns:item/>
            </root>
        """)
        // Note: XPath namespace handling may require namespace registration
        let query = try XPathQuery("//*[local-name()='item']")
        let results = query.nodesResult(with: doc.node)
        #expect(results.count == 1)
    }
}
