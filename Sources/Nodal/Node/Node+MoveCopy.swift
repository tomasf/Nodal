import Foundation
import pugixml
import Bridge

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
        var parentNode = parent.node
        guard let resultNode = document.nodeIfValid(parentNode.copyChild(self.node, to: position)) else {
            return nil
        }

        // Copy pending records
        for (oldNode, newNode) in zip(self.node.descendants, resultNode.node.descendants) {
            guard let record = document.pendingNameRecord(for: oldNode) else { continue }
            resultNode.document.addPendingNameRecord(for: newNode, copiedFrom: record)
        }

        return resultNode
    }
}
