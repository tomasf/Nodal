@testable import Nodal
import Testing

struct NamespaceTests {
    @Test
    func declarationCache() {
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
    func declarationCacheLoaded() throws {
        let doc = try Document(string: """
        <root xmlns="default">
            <a xmlns="default2" xmlns:foo="foouri">
                <b/><foo:c/>
            </a>
        </root>
        """)

        #expect(doc.namespaceDeclarationCount() == 3)
        #expect(doc.documentElement?.expandedName.namespaceName == "default")

        let a = try XPathQuery("/root/a").firstNodeResult(with: doc.node)?.node
        #expect(a?.expandedName.namespaceName == "default2")

        let b = a?[element: "b"]
        #expect(b?.expandedName.namespaceName == "default2")

        let c = try XPathQuery("foo:c").firstNodeResult(with: a!)?.node
        #expect(c?.expandedName.namespaceName == "foouri")
    }

    @Test
    func shadowing() {
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
    func defaultReset() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        root.declareNamespace("foo", forPrefix: nil)
        let sub = root.addElement("sub")
        let leaf = sub.addElement("leaf")

        // Sub inherits its default namespace from root
        #expect(sub.expandedName.namespaceName == "foo")
        #expect(sub[element: ExpandedName(namespaceName: "foo", localName: "leaf")] == leaf)
        #expect(sub[element: ExpandedName(namespaceName: nil, localName: "leaf")] == nil)

        // Declaring the empty namespace overrides the default namespace; sub and leaf are now in no namespace
        sub.declareNamespace("", forPrefix: nil)
        #expect(sub.expandedName.namespaceName == nil)
        #expect(sub[element: ExpandedName(namespaceName: "foo", localName: "leaf")] == nil)
        #expect(sub[element: ExpandedName(namespaceName: nil, localName: "leaf")] == leaf)
    }

    @Test
    func deferredResolution() {
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

        b.declareNamespace("namespace3", forPrefix: "z")
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

    @Test
    func pendingNamespacesWithCopy() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.addElement("a", namespace: "foo")
        let b = a.addElement("b")
        b[attribute: "z", namespaceName: "foo"] = "test"
        #expect(a.name.hasPrefix("__pending"))
        #expect(a.expandedName.namespaceName == "foo")
        #expect(b[attribute: "z", namespaceName: "foo"] == "test")

        let copy = a.copy(to: root)!
        let bCopy = copy[element: "b"]!
        root.declareNamespace("foo", forPrefix: "f")
        #expect(a.name == "f:a")
        #expect(a.expandedName.namespaceName == "foo")
        #expect(b[attribute: "z", namespaceName: "foo"] == "test")
        #expect(b[attribute: "f:z"] == "test")

        #expect(copy.name == "f:a")
        #expect(copy.expandedName.namespaceName == "foo")
        #expect(bCopy[attribute: "f:z"] == "test")

        #expect(try a.xmlString() == copy.xmlString())
    }
}
