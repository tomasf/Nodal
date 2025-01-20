@testable import Nodal
import Testing

struct Tests {
    @Test
    func deferredNamespaceResolution() {
        let document = Document()
        let root = document.makeDocumentElement(name: "root")

        // Elements should not have pending records yet
        #expect(document.pendingNameRecordCount == 0)
        let a = root.appendElement("a", namespace: "namespace1")
        let b = root.appendElement("b", namespace: "namespace1")
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

        let e1 = root.appendElement(en1)
        #expect(e1.expandedName == en1)

        #expect(root[elements: en1].count == 1)
        #expect(root[elements: en2].count == 0)

        let e2 = root.appendElement(en2)
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
    func testInvalidation() throws {
        let doc = Document()
        let root = doc.makeDocumentElement(name: "root")
        let a = root.appendElement("a")
        let b = a.appendElement("b")

        #expect(a.isValid == true)
        #expect(b.isValid == true)
        root.removeChild(a)
        #expect(a.isValid == false)
        #expect(b.isValid == false)
    }
}
