@testable import Nodal
import Testing

struct HierarchyTests {
    // addChild should return nil if the type of node can't be added to that parent
    @Test
    func addChild() throws {
        let document = Document()
        let a = document.node.addChild(ofKind: .element)
        #expect(a != nil)
        guard let a else { return }

        let innerDoc = a.addChild(ofKind: .document)
        #expect(innerDoc == nil)

        let innerDecl = a.addChild(ofKind: .declaration)
        #expect(innerDecl == nil)

        #expect(a.addChild(ofKind: .comment) != nil)
        #expect(document.node.addChild(ofKind: .comment) != nil)
    }

    @Test
    func attributes() throws {
        let doc = Document()
        let decl = doc.node.addChild(ofKind: .declaration)
        let root = doc.makeDocumentElement(name: "root")

        #expect(decl != nil)
        #expect(decl!.supportsAttributes == true)
        decl![attribute: "q2"] = "v2"

        let a = root.addElement("a")
        #expect(a.supportsAttributes == true)
        a[attribute: "q1"] = "v1"
        let text = a.addText("text")
        #expect(text.supportsAttributes == false)

        #expect(try doc.xmlString(options: .raw) == "<?xml q2=\"v2\"?><root><a q1=\"v1\">text</a></root>")
    }

    @Test
    func textContent() throws {
        let doc = try Document(string: """
        <root>
            foo
            <a>
                bar
                <b>baz<!--comment--><![CDATA[zoing]]>biz</b>
                doz
            </a>
        </root>
""", options: [.default, .trimTextWhitespace])
        #expect(doc.node.textContent == "foobarbazzoingbizdoz")
    }

    @Test
    func move() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.addElement("a")
        let b = root.addElement("b")
        let c = a.addComment("hello")

        #expect(c.move(to: a) == true, "Successful move")
        //#expect(Array(a.children) == [c], "Destination has target")
        #expect(a.move(to: b) == true, "Successful move with children")
        //#expect(c.parent?.parent == b, "Grandparent is correct")

        let doc2 = Document()
        let root2 = doc2.makeDocumentElement(name: "root2")
        #expect(c.move(to: root2) == false, "Move between documents")
        #expect(c.move(to: c) == false, "Move to itself")
    }

    @Test
    func addAt() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.addElement("a")
        let b = root.addElement("b", at: .first)

        #expect(Array(root.children) == [b, a], "Order of children")
        let c = root.addCDATA("c", at: .after(b))
        #expect(Array(root.children) == [b, c, a], "Order of children")
    }

    @Test
    func descendants() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.addElement("a")
        let c = a.addElement("c")
        let t1 = c.addText("t1")
        let t2 = c.addText("t2")
        let x = root.addElement("x")
        let b = root.addElement("b")
        let comment = b.addComment("comment")

        #expect(Array(doc.node.descendants) == [doc.node, root, a, c, t1, t2, x, b, comment])
        #expect(Array(a.descendants) == [a, c, t1, t2])
        #expect(Array(c.descendants) == [c, t1, t2])
    }
}
