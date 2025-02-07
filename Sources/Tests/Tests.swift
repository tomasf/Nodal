@testable import Nodal
import Testing

struct Tests {
    @Test
    func namespaceDeclarationCache() {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.addElement("a")

        root.declareNamespace("uri-foo", forPrefix: "foo")
        #expect(doc.namespaceDeclarationCount(for: root) == 1)
        #expect(a.namespaceName(forPrefix: .named("foo")) == "uri-foo")

        a.declareNamespace("uri-bar", forPrefix: "foo")
        #expect(doc.namespaceDeclarationCount(for: a) == 1)
        #expect(doc.namespaceDeclarationCount() == 2)
        #expect(a.namespaceName(forPrefix: .named("foo")) == "uri-bar")

        doc.makeDocumentElement(name: "cleared")
        #expect(doc.namespaceDeclarationCount() == 0)
    }

    @Test
    func namespaceDeclarationCacheLoaded() throws {
        let doc = try Document(string: """
        <root xmlns="default">
            <a xmlns="default2" xmlns:foo="foouri">
                <b/><foo:c/>
            </a>
        </root>
        """)

        #expect(doc.namespaceDeclarationCount() == 3)
        #expect(doc.documentElement?.expandedName.namespaceName == "default")

        let a = try XPathQuery("/root/a").firstNodeResult(with: doc)?.node as? Element
        #expect(a?.expandedName.namespaceName == "default2")

        let b = a?[element: "b"]
        #expect(b?.expandedName.namespaceName == "default2")

        let c = try XPathQuery("foo:c").firstNodeResult(with: a!)?.node as? Element
        #expect(c?.expandedName.namespaceName == "foouri")
    }

    @Test
    func namespaceShadowing() {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let sub = root.addElement("sub")
        root.declareNamespace("foo", forPrefix: "a")
        sub.declareNamespace("bar", forPrefix: "a")

        // Sub now shadows the a prefix, preventing its children from referencing the URI "foo"
        #expect(sub.namespacePrefix(forName: "foo") == nil)
        #expect(sub.namespaceName(forPrefix: .named("a")) == "bar")

        // Foo should still be visible at root
        #expect(root.namespacePrefix(forName: "foo") == .named("a"))

        // Because foo isn't visible, trying to use it will register a pending record
        #expect(doc.pendingNameRecordCount == 0)
        let child = sub.addElement("baz", namespace: "foo")
        #expect(doc.pendingNameRecordCount == 1)

        // Unrelated. No change.
        root.declareNamespace("fraz", forPrefix: "c")
        #expect(doc.pendingNameRecordCount == 1)

        // Until we add a visible prefix for foo
        root.declareNamespace("foo", forPrefix: "b")
        #expect(doc.pendingNameRecordCount == 0)
        #expect(child.name == "b:baz")
    }

    @Test
    func deferredNamespaceResolution() {
        let document = Document()
        let root = document.makeDocumentElement(name: "root")

        // Elements should not have pending records yet
        #expect(document.pendingNameRecordCount == 0)
        let a = root.addElement("a", namespace: "namespace1")
        let b = root.addElement("b", namespace: "namespace1")
        #expect(document.pendingNameRecordCount == 2)

        #expect(PendingNameRecord.qualifiedNameIndicatesPending(a.name))
        root.declareNamespace("namespace2", forPrefix: "x")
        #expect(document.pendingNameRecordCount == 2)
        #expect(PendingNameRecord.qualifiedNameIndicatesPending(a.name))
        root.declareNamespace("namespace1", forPrefix: "y")
        #expect(a.name == "y:a")
        #expect(document.pendingNameRecordCount == 0)

        a[attribute: "b", namespaceName: "namespace2"] = "foo"
        #expect(document.pendingNameRecordCount == 0)
        #expect(a[attribute: "__pending:b"] == nil)
        #expect(a[attribute: "x:b"] == "foo")

        a[attribute: "c", namespaceName: "namespace3"] = "bar"
        #expect(a[attribute: "c", namespaceName: "namespace3"] == "bar")
        #expect(document.pendingNameRecordCount == 1)

        #expect(a[attribute: "__pending:c"] == "bar")
        b.declareNamespace("namespace3", forPrefix: "z")
        #expect(a[attribute: "__pending:c"] == "bar")
        #expect(document.pendingNameRecordCount == 1)

        root.declareNamespace("namespace3", forPrefix: "aa")
        #expect(a[attribute: "aa:c"] == "bar")
    }

    @Test
    func expandedNames() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let nn1 = "namespace1"
        let nn2 = "namespace2"

        root.declareNamespace(nn2, forPrefix: "n2")

        let en1 = ExpandedName(namespaceName: nn1, localName: "local1")
        let en2 = ExpandedName(namespaceName: nn2, localName: "local2")

        let e1 = root.addElement(en1)
        #expect(e1.expandedName == en1)

        #expect(root[elements: en1].count == 1)
        #expect(root[elements: en2].count == 0)

        let e2 = root.addElement(en2)
        #expect(e2.expandedName == en2)
        #expect(root[elements: en2].count == 1)

        root.declareNamespace(nn1, forPrefix: "n1")
        #expect(e1.expandedName == en1)

        #expect(doc.pendingNameRecordCount == 0)
        _ = try doc.xmlData() // Should not throw
    }

    // addChild should return nil if the type of node can't be added to that parent
    @Test
    func addChild() throws {
        let document = Document()
        let a = document.addChild(ofKind: .element)
        #expect(a != nil)
        guard let a else { return }

        let innerDoc = a.addChild(ofKind: .document)
        #expect(innerDoc == nil)

        let innerDecl = a.addChild(ofKind: .declaration)
        #expect(innerDecl == nil)

        #expect(a.addChild(ofKind: .comment) != nil)
        #expect(document.addChild(ofKind: .comment) != nil)
    }

    @Test
    func attributes() throws {
        let doc = Document()
        let decl = doc.addChild(ofKind: .declaration)
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
        #expect(doc.textContent == "foobarbazzoingbizdoz")
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

        //#expect(Array(root.children) == [b, a], "Order of children")
        let c = root.addCDATA("c", at: .after(b))
        //#expect(Array(root.children) == [b, c, a], "Order of children")
    }
}
