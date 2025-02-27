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
}
