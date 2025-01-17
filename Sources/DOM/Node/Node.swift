import Foundation
import pugixml
import Bridge

public class Node {
    public let document: Document
    internal var node: pugi.xml_node

    internal required init(document: Document, node: pugi.xml_node) {
        self.document = document
        self.node = node
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
    var name: String {
        get {
            String(cString: node.name()) // documented to never return null
        }
        set {
            node.set_name(newValue)
        }
    }

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
        document.object(for: node.parent())
    }

    func removeChild(_ child: Node) {
        node.remove_child(child.node)
    }

    func removeAllChildren() {
        node.remove_children()
    }

    func xmlData(encoding: String.Encoding = .utf8, options: OutputOptions = .default, indentation: String = .fourSpaces) -> Data {
        var data = Data()
        xml_node_print_with_block(node, indentation, options.rawValue, encoding.pugiEncoding, 0) { rawPointer, length in
            guard let rawPointer else { return }
            data.append(rawPointer.assumingMemoryBound(to: UInt8.self), count: length)
        }
        return data
    }

    func xmlString(options: OutputOptions = .default, indentation: String = .fourSpaces) -> String {
        String(data: xmlData(encoding: .utf8, options: options, indentation: indentation), encoding: .utf8) ?? ""
    }

    var xmlString: String {
        xmlString(options: .default)
    }

    // Traverse the entire tree within this node. Return true from the function to continue; false to stop
    func traverseTree(_ function: @escaping (Node, _ level: Int) -> Bool) {
        traverse { function(self.document.object(for: $0), $1) }
    }
}

extension Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch kind {
        case .element: "Element <\(name)>"
        case .text: "Text \"(\(value))\""
        case .cdata: "CDATA \"(\(value))\""
        case .comment: "Comment <!--\(value)-->"
        case .doctype: "DOCTYPE <!DOCTYPE \(value)>"
        case .processingInstruction: "Processing instruction <?\(name) \(value)?>"
        case .document: "Document"
        }
    }
}

internal extension pugi.xpath_node_set {
    var nodes: [pugi.xpath_node] {
        (0..<size()).map { self[$0] }
    }
}
