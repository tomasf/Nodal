import Foundation
import pugixml

/// Represents an XML element node in the document tree.
///
/// - Note: This class provides functionality for working with XML elements, including accessing their attributes,
///         child nodes, and text content. It extends the `Node` class, inheriting its methods and properties.
public class Element: Node {
    internal var cachedNamespacesInScope: [String?: String]?

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


