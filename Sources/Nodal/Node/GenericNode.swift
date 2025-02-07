import Foundation
import pugixml
import Bridge

struct GenericNode: Node {
    let document: Document
    let node: pugi.xml_node

    internal init(owningDocument: Document, node: pugi.xml_node) {
        self.document = owningDocument
        self.node = node
    }
}

extension GenericNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch kind {
        case .element: "Element <\(name)>"
        case .text: "Text \"\(value)\""
        case .cdata: "CDATA \"\(value)\""
        case .comment: "Comment <!--\(value)-->"
        case .doctype: "Document type declaration <!DOCTYPE \(value)>"
        case .processingInstruction: "PI <?\(name) \(value)?>"
        case .declaration: "Declaration <?\(name)...?>"
        case .document: "Document"
        }
    }
}
