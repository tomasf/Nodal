import Foundation
import pugixml

/// Represents an XML element node in the document tree.
///
/// - Note: This class provides functionality for working with XML elements, including accessing their attributes,
///         child nodes, and text content. It extends the `Node` class, inheriting its methods and properties.
public class Element: Node {
    internal override func declaredNamespacesDidChange() {
        let namespaces = declaredNamespaces
        for (element, record) in document.pendingNameRecords(forDescendantsOf: self) {
            if record.attemptResolution(for: element, with: namespaces) {
                document.removePendingNameRecord(for: element)
            }
        }
    }

    internal override var hasNamespaceDeclarations: Bool {
        node.attributes.contains(where: { String(cString: $0.name()).hasPrefix("xmlns") })
    }
}
