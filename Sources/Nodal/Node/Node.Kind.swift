import Foundation
import pugixml

/// Represents the types of XML nodes.
public extension Node {
    enum Kind {
        /// The root of an XML document.
        case document
        
        /// An XML element node.
        ///
        /// - Serialized form: `<elementName ...>...</elementName>` or `<elementName.../>`
        case element
        
        /// A text node containing plain character data.
        ///
        /// - Serialized form: text content
        case text
        
        /// A CDATA section node.
        ///
        /// - Serialized form: `<![CDATA[some text]]>`
        case cdata
        
        /// A comment node.
        ///
        /// - Serialized form: `<!-- comment -->`
        case comment
        
        /// A processing instruction node.
        ///
        /// - Serialized form: `<?target data?>`
        case processingInstruction
        
        /// An XML declaration node.
        ///
        /// - Serialized form: `<?xml version="1.0"?>`
        case declaration
        
        /// A DOCTYPE declaration node.
        ///
        /// - Serialized form: `<!DOCTYPE rootElement SYSTEM "url">`
        case doctype
        
        
        internal init(_ pugiType: pugi.xml_node_type) {
            self = switch pugiType {
            case pugi.node_document: .document
            case pugi.node_element: .element
            case pugi.node_pcdata: .text
            case pugi.node_cdata: .cdata
            case pugi.node_comment: .comment
            case pugi.node_pi: .processingInstruction
            case pugi.node_declaration: .declaration
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
            case .declaration: pugi.node_declaration
            case .doctype: pugi.node_doctype
            }
        }
    }
}
