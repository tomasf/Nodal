import Foundation
import pugixml
import Bridge

internal extension Node {
    // After copying a node, the new nodes lack records for pending namespaces.
    // So we need to traverse the new tree, find pending qualified names,
    // look them up in existing records and add request new pending records
    func addPendingRecords(copiedFrom originalNode: Node) {
        let records = document.pendingNameRecords(forDescendantsOf: originalNode).map { $1 }

        for descNode in node.descendants where descNode.type() == pugi.node_element {
            var record: PendingNameRecord?

            // Pending element names
            let qName = String(cString: descNode.name())
            if PendingNameRecord.qualifiedNameIndicatesPending(qName) {
                record = records.first(where: { $0.elementName?.placeholder == qName })
                if let record, let recordName = record.elementName {
                    let node = document.node(for: descNode)
                    node.name = recordName.0.requestQualifiedElementName(for: node)
                }
            }

            // Pending attribute names
            for var attribute in descNode.attributes {
                let qName = String(cString: attribute.name())
                if PendingNameRecord.qualifiedNameIndicatesPending(qName) {
                    if record == nil {
                        record = records.lazy.first { record in
                            record.attributes.contains(where: { $1 == qName })
                        }
                    }

                    if let record, let expandedName = record.attributes.first(where: { $1 == qName })?.key {
                        let node = document.node(for: descNode)
                        attribute.set_name(expandedName.requestQualifiedAttributeName(for: node))
                    }
                }
            }
        }
    }
}

public extension Node {
    /// Moves this node to a new parent node at the specified position within the parent's children.
    ///
    /// - Parameters:
    ///   - parent: The new parent node to which this node should be moved.
    ///   - position: The position within the parent's children where this node should be inserted. Defaults to `.last`, adding the node as the last child of the parent.
    /// - Returns: A Boolean value indicating whether the move was successful.
    ///            Returns `false` if the node cannot be moved. Examples of such cases include:
    ///            - The new parent node belongs to a different document.
    ///            - The node is being moved to within itself, which would create an invalid structure.
    @discardableResult
    func move(to parent: Node, at position: Position = .last) -> Bool {
        let records = document.pendingNameRecords(forDescendantsOf: self)
        var destination = parent.node

        if destination.insertChild(self.node, at: position).empty() {
            return false
        }

        for (node, record) in records {
            record.updateAncestors(with: node)
        }
        return true
    }

    /// Creates a copy of this node and inserts it into a new parent node at the specified position.
    ///
    /// - Parameters:
    ///   - parent: The new parent node to which the copied node should be added.
    ///   - position: The position within the parent's children where the copied node should be inserted. Defaults to `.last`, adding the node as the last child of the parent.
    ///
    /// - Returns: The newly created copied node if the copy is successful, or `nil` if the copy operation fails.
    ///
    /// - Important:
    ///   - Copying between different documents is supported.
    ///   - The destination node must be able to contain a node of the same kind as the copied node.
    ///
    /// - Discussion:
    ///   This method performs a deep copy of the node and all its descendants, preserving the structure and attributes.
    ///
    @discardableResult
    func copy(to parent: Node, at position: Position = .last) -> Node? {
        var node = parent.node
        let resultNode = document.nodeIfValid(node.copyChild(self.node, to: position))
        resultNode?.addPendingRecords(copiedFrom: self)
        return resultNode
    }
}
