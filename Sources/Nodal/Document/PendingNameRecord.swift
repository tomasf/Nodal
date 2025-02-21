import Foundation
import pugixml

internal class PendingNameRecord {
    var elementName: (ExpandedName, placeholder: String)?
    var attributes: [ExpandedName: String] = [:] // value = qName
    var ancestors: Set<pugi.xml_node> = .init(minimumCapacity: 8) // Ancestors, including the element itself

    private static let pendingPrefix = "__pending"

    init(element: Node) {
        var node = element.node
        while !node.empty() {
            ancestors.insert(node)
            node = node.parent()
        }
    }

    func updateAncestors(with element: pugi.xml_node) {
        ancestors = []
        var node = element
        while !node.empty() {
            ancestors.insert(node)
            node = node.parent()
        }
    }

    func belongsToTree(_ node: Node) -> Bool {
        ancestors.contains(node.node)
    }

    private func pendingPlaceholder(for name: ExpandedName) -> String {
        Self.pendingPrefix + "_" + UUID().uuidString + ":" + name.localName
    }

    // Returns placeholder qualified name
    func addUnresolvedElementName(_ name: ExpandedName, for element: Node) -> String {
        let placeholder = pendingPlaceholder(for: name)
        elementName = (name, placeholder)
        return placeholder
    }

    func pendingExpandedAttributeName(for placeholderQName: String) -> ExpandedName? {
        attributes.first(where: { $1 == placeholderQName })?.key
    }

    // Returns placeholder qualified name
    func addUnresolvedAttribute(_ name: ExpandedName, in element: Node) -> String {
        if let existingQName = attributes[name] {
            // A pending element for this expanded name already exists, so just replace its value
            return existingQName
        }

        let qName = pendingPlaceholder(for: name)
        attributes[name] = qName
        return qName
    }

    var isEmpty: Bool {
        elementName == nil && attributes.isEmpty
    }

    var namespaceNames: Set<String> {
        var names = Set<String>()
        if let (elementName, _) = elementName, let namespaceName = elementName.namespaceName {
            names.insert(namespaceName)
        }
        for expandedName in attributes.keys {
            if let namespaceName = expandedName.namespaceName {
                names.insert(namespaceName)
            }
        }
        return names
    }

    // Returns true if the element is now completely resolved and the record can be removed
    func attemptResolution(for element: pugi.xml_node, in document: Document) -> Bool {
        if let (elementName, _) = elementName,
           let namespaceName = elementName.namespaceName,
           let prefix = document.namespacePrefix(forName: namespaceName, in: element)
        {
            var element = element
            element.set_name(String(prefix: prefix.string, localPart: elementName.localName))
            self.elementName = nil
        }

        attributes = attributes.filter { name, qName in
            guard var attribute = element.attribute(qName).nonNull else {
                return false // The pending attribute is gone? Problem solved, I guess.
            }

            guard let namespaceName = name.namespaceName,
                  let prefix = document.namespacePrefix(forName: namespaceName, in: element)
            else {
                return true // Not resolved. Keep the unresolved attribute record
            }

            let newQName = String(prefix: prefix.string, localPart: name.localName)
            attribute.set_name(newQName)
            return false // Resolved! Remove attribute record.
        }

        return isEmpty
    }

    static func qualifiedNameIndicatesPending(_ qName: String) -> Bool {
        qName.hasPrefix(pendingPrefix)
    }
}
