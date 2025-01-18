import Foundation
import pugixml

public extension Node {
    var kind: Kind {
        Kind(node.type())
    }

    enum Kind {
        case document
        case element
        case text
        case cdata
        case comment
        case processingInstruction
        //case declaration
        case doctype

        internal init(_ pugiType: pugi.xml_node_type) {
            self = switch pugiType {
            case pugi.node_document: .document
            case pugi.node_element: .element
            case pugi.node_pcdata: .text
            case pugi.node_cdata: .cdata
            case pugi.node_comment: .comment
            case pugi.node_pi: .processingInstruction
            //case pugi.node_declaration: .declaration
            case pugi.node_doctype: .doctype
            case pugi.node_null: preconditionFailure("Null nodes should never become objects")
            default: preconditionFailure("Unknown node type")
            }
        }

        internal var pugiType: pugi.xml_node_type {
            switch self {
            case .document: pugi.node_document
            case .element: pugi.node_element
            case .text: pugi.node_pcdata
            case .cdata: pugi.node_cdata
            case .comment: pugi.node_comment
            case .processingInstruction: pugi.node_pi
            //case .declaration: pugi.node_declaration
            case .doctype: pugi.node_doctype
            }
        }
    }
}
