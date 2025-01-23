import Foundation
import pugixml

internal class PendingNameRecord {
    var elementName: ExpandedName?
    var attributes: [ExpandedName: String] = [:] // value = qName
    var ancestors: Set<pugi.xml_node> = .init(minimumCapacity: 8) // Ancestors, including the element iself

    private static let pendingPrefix = "__pending"

    init(element: Element) {
        var node = element.node
        while !node.empty() {
            ancestors.insert(node)
            node = node.parent()
        }
    }

    func updateAncestors(with element: Element) {
        ancestors = []
        var node = element.node
        while !node.empty() {
            ancestors.insert(node)
            node = node.parent()
        }
    }

    func belongsToTree(_ node: Node) -> Bool {
        ancestors.contains(node.node)
    }

    // Returns placeholder prefix part
    func addUnresolvedElementName(_ name: ExpandedName, for element: Element) -> String {
        elementName = name
        return Self.pendingPrefix
    }

    func pendingExpandedAttributeName(for placeholderQName: String) -> ExpandedName? {
        attributes.first(where: { $1 == placeholderQName })?.key
    }

    // Returns placeholder qualified name
    func addUnresolvedAttribute(_ name: ExpandedName, in element: Element) -> String {
        if let existingQName = attributes[name] {
            // A pending element for this expanded name already exists, so just replace its value
            return existingQName
        }
        var counter = 0
        var pendingPrefix = Self.pendingPrefix
        while element[attribute: String(prefix: pendingPrefix, localPart: name.localName)] != nil {
            counter += 1
            pendingPrefix = Self.pendingPrefix + "_\(counter)"
        }
        let qName = String(prefix: pendingPrefix, localPart: name.localName)
        attributes[name] = qName
        return qName
    }

    var isEmpty: Bool {
        elementName == nil && attributes.isEmpty
    }

    var namespaceNames: Set<String> {
        var names = Set<String>()
        if let elementName = elementName, let namespaceName = elementName.namespaceName {
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
    func attemptResolution(for element: Element) -> Bool {
        if let elementName,
           let namespaceName = elementName.namespaceName,
           let prefix = element.namespacePrefix(forName: namespaceName)
        {
            element.name = String(prefix: prefix.string, localPart: elementName.localName)
            self.elementName = nil
        }

        attributes = attributes.filter { name, qName in
            guard let value = element[attribute: qName] else {
                return false // The pending attribute is gone? Problem solved, I guess.
            }

            guard let namespaceName = name.namespaceName, let prefix = element.namespacePrefix(forName: namespaceName) else {
                return true // Not resolved. Keep the unresolved attribute record
            }

            element[attribute: qName] = nil
            element[attribute: String(prefix: prefix.string, localPart: name.localName)] = value
            return false // Resolved! Remove attribute record.
        }

        return isEmpty
    }

    static func qualifiedNameIndicatesPending(_ qName: String) -> Bool {
        qName.hasPrefix(pendingPrefix)
    }
}
