import Foundation
import pugixml

internal extension Document {
    func pendingNameRecord(for element: Node) -> PendingNameRecord? {
        pendingNamespaceRecords[element.nodePointer]
    }

    func expandedName(for elementNode: pugi.xml_node) -> ExpandedName {
        let qName = String(cString: elementNode.name())
        if PendingNameRecord.qualifiedNameIndicatesPending(qName),
           let record = pendingNamespaceRecords[elementNode.internal_object()],
           let name = record.elementName {
            return name
        }

        let (prefix, localName) = elementNode.name().qualifiedNameParts

        return ExpandedName(
            namespaceName: namespaceName(forPrefix: .init(prefix), in: elementNode),
            localName: localName
        )
    }

    func addPendingNameRecord(for element: Node) -> PendingNameRecord {
        let record = PendingNameRecord(element: element)
        pendingNamespaceRecords[element.nodePointer] = record
        return record
    }

    func removePendingNameRecord(for element: pugi.xml_node) {
        pendingNamespaceRecords[element.internal_object()] = nil
    }

    func removePendingNameRecords(withinTree ancestor: Node, excludingTarget: Bool = false) {
        let nodePointer = ancestor.nodePointer
        let keys = pendingNamespaceRecords.filter { node, record in
            if excludingTarget && node == nodePointer {
                return false
            }
            return record.ancestors.contains(ancestor.node)
        }.map(\.key)

        for key in keys { pendingNamespaceRecords[key] = nil }
    }

    func pendingNameRecords(forDescendantsOf parent: Node) -> [(pugi.xml_node, PendingNameRecord)] {
        pendingNamespaceRecords.compactMap {
            $1.belongsToTree(parent) ? (.init($0), $1) : nil
        }
    }

    var pendingNameRecordCount: Int {
        pendingNamespaceRecords.count
    }
}
