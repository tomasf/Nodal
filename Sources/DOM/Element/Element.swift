import Foundation
import pugixml

public class Element: Node {
    internal var cachedNamespacesInScope: [String?: String]?

    required internal init(document: Document, node: pugi.xml_node) {
        super.init(document: document, node: node)
        assert(node.type() == pugi.node_element)
    }

    internal func invalidateNamespaceCache() {
        cachedNamespacesInScope = nil
        traverse { node, _ in
            if node.type() == pugi.node_element, let element = self.document.existingElementObject(forNode: node) {
                element.cachedNamespacesInScope = nil
            }
            return true
        }
    }
}


