import Foundation
import pugixml
import Bridge

public class Node {
    private let owningDocument: Document?
    internal var node: pugi.xml_node

    internal required init(owningDocument: Document?, node: pugi.xml_node) {
        self.owningDocument = owningDocument
        self.node = node
    }

    public var document: Document {
        guard let owningDocument else {
            fatalError("owningDocument should only be nil for Document, which overrides this property")
        }
        return owningDocument
    }

    public func xmlData(encoding: String.Encoding = .utf8, options: OutputOptions = .default, indentation: String = .fourSpaces) -> Data {
        var data = Data()
        xml_node_print_with_block(node, indentation, options.rawValue, encoding.pugiEncoding, 0) { rawPointer, length in
            guard let rawPointer else { return }
            data.append(rawPointer.assumingMemoryBound(to: UInt8.self), count: length)
        }
        return data
    }

    public func xmlString(options: OutputOptions = .default, indentation: String = .fourSpaces) -> String {
        String(data: xmlData(encoding: .utf8, options: options, indentation: indentation), encoding: .utf8) ?? ""
    }
}

internal extension Node {
    func childNodes(ofType targetType: pugi.xml_node_type = pugi.node_null) -> [pugi.xml_node] {
        childNodes.filter { targetType == pugi.node_null || $0.type() == targetType }
    }

    func traverse(_ function: @escaping (pugi.xml_node, Int) -> Bool) {
        xml_node_walk_block(&node) { function($0, Int($1)) }
    }
}

extension Node: Equatable {
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        lhs.node == rhs.node
    }
}

public extension Node {
    // The name of the node. For elements, this is the qualified name, i.e. a local name
    // with or without a namespace prefix. For processing instructions, the name represents
    // the target. For other kinds of nodes, name is nil.
    // See also: `Element.expandedName`
    var name: String {
        get {
            String(cString: node.name()) // documented to never return null
        }
        set {
            node.set_name(newValue)
        }
    }

    // The value of the node. This is available for text, CDATA, comments,
    // DOCTYPEs and processing instructions. For other kinds of nodes, value is nil.
    var value: String {
        get {
            String(cString: node.value()) // documented to never return null
        }
        set {
            node.set_value(newValue)
        }
    }

    var children: [Node] {
        childNodes().map { document.object(for: $0) }
    }

    func children(ofKind kind: Kind) -> [Node] {
        childNodes(ofType: kind.pugiType).map {
            document.object(for: $0)
        }
    }

    var parent: Node? {
        let parentNode = node.parent()
        return parentNode.empty() ? nil : document.object(for: parentNode)
    }

    func removeChild(_ child: Node) {
        node.remove_child(child.node)
    }

    func removeAllChildren() {
        node.remove_children()
    }

    // Traverse the entire tree within this node. Return true from the function to continue; false to stop
    func traverseTree(_ function: @escaping (Node, _ level: Int) -> Bool) {
        traverse { function(self.document.object(for: $0), $1) }
    }

    func isDescendant(of ancestor: Node) -> Bool {
        var node = self.node
        while !node.empty() {
            if node == ancestor.node {
                return true
            }
            node = node.parent()
        }
        return false
    }
}

extension Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch kind {
        case .element: "Element <\(name)>"
        case .text: "Text \"(\(value))\""
        case .cdata: "CDATA \"(\(value))\""
        case .comment: "Comment <!--\(value)-->"
        case .doctype: "<!DOCTYPE \(value)>"
        case .processingInstruction: "PI <?\(name) \(value)?>"
        case .document: "Document"
        }
    }
}


