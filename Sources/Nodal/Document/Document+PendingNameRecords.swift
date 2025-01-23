import Foundation
import pugixml

internal extension Document {
    func pendingNameRecord(for element: Element) -> PendingNameRecord? {
        pendingNamespaceRecords[element.nodePointer]
    }

    func expandedName(for elementNode: pugi.xml_node) -> ExpandedName {
        let qName = String(cString: elementNode.name())
        if PendingNameRecord.qualifiedNameIndicatesPending(qName),
           let record = pendingNamespaceRecords[elementNode.internal_object()],
           let name = record.elementName {
            return name
        }

        return ExpandedName(
            namespaceName: namespaceName(forPrefix: .init(qName.qNamePrefix), in: elementNode),
            localName: qName.qNameLocalName
        )
    }

    func addPendingNameRecord(for element: Element) -> PendingNameRecord {
        let record = PendingNameRecord(element: element)
        pendingNamespaceRecords[element.nodePointer] = record
        return record
    }

    func removePendingNameRecord(for element: Element) {
        pendingNamespaceRecords[element.nodePointer] = nil
    }

    func removePendingNameRecords(withinTree ancestor: Element, excludingTarget: Bool = false) {
        let nodePointer = ancestor.nodePointer
        let keys = pendingNamespaceRecords.filter { node, record in
            if excludingTarget && node == nodePointer {
                return false
            }
            return record.ancestors.contains(ancestor.node)
        }.map(\.key)

        for key in keys { pendingNamespaceRecords[key] = nil }
    }

    func pendingNameRecords(forDescendantsOf parent: Node) -> [(Element, PendingNameRecord)] {
        pendingNamespaceRecords.compactMap {
            $1.belongsToTree(parent) ? (element(for: .init($0)), $1) : nil
        }
    }

    var pendingNameRecordCount: Int {
        pendingNamespaceRecords.count
    }
}
