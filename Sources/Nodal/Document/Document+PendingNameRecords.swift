import Foundation
import pugixml

internal extension Document {
    func pendingNameRecord(for element: Element) -> PendingNameRecord? {
        pendingNamespaceRecords[element.nodePointer]
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
        let keys = pendingNamespaceRecords.contents.filter { node, record in
            if excludingTarget && node == nodePointer {
                return false
            }
            return record.ancestors.contains(ancestor.node)
        }.map(\.key)
        pendingNamespaceRecords.removeObjects(forKeys: keys)
    }

    func pendingNameRecords(forDescendantsOf parent: Element) -> [(Element, PendingNameRecord)] {
        pendingNamespaceRecords.contents.compactMap {
            $1.belongsToTree(parent) ? (element(for: .init($0)), $1) : nil
        }
    }

    var pendingNameRecordCount: Int {
        pendingNamespaceRecords.count
    }
}
