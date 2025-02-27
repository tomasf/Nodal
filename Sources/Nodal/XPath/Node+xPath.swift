import Foundation
import pugixml

internal extension pugi.xml_node {
    // The index of this node among its qualified namesake siblings
    var elementIndex: Int {
        let name = String(cString: name())
        return precedingSiblings.filter { String(cString: $0.name()) == name }.count
    }

    // The index of this node among its text (pcdata + cdata) siblings
    var textIndex: Int {
        precedingSiblings.filter { $0.type() == pugi.node_cdata || $0.type() == pugi.node_pcdata }.count
    }

    // The index of this comment node among its comment siblings
    var commentIndex: Int {
        precedingSiblings.filter { $0.type() == pugi.node_comment }.count
    }

    // The index of this comment node among its processing instruction siblings
    var piIndex: Int {
        precedingSiblings.filter { $0.type() == pugi.node_pi }.count
    }

    var rawXPath: String {
        if type() == pugi.node_document { return "" }

        let parentPath = parent().rawXPath + "/"
        let thisPathPart = switch type() {
        case pugi.node_element:
            String(cString: name()) + "[\(elementIndex + 1)]"
        case pugi.node_pcdata, pugi.node_cdata:
            "text()[\(textIndex + 1)]"
        case pugi.node_comment:
            "comment()[\(commentIndex + 1)]"
        case pugi.node_pi:
            "processing-instruction()[\(piIndex + 1)]"
        default:
            ""
        }

        return parentPath + thisPathPart
    }
}

public extension Node {
    /// The XPath representation of this XML node.
    ///
    /// This property provides a unique, absolute XPath string that identifies
    /// the position of this node within its XML document. The generated XPath
    /// can be used to query and locate the node in an XML structure and is
    /// useful for debugging purposes.
    ///
    var xPath: String {
        if kind == .document {
            "/"
        } else {
            node.rawXPath
        }
    }
}
