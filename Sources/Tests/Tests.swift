@testable import Nodal
import Testing

struct Tests {
    @Test
    func namespaceResolution() {
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
}
