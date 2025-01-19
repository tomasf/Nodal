import Foundation
import pugixml

public extension Element {
    @discardableResult
    func appendText(_ text: String) -> Node {
        var textNode = node.append_child(pugi.node_pcdata)
        textNode.set_value(text)
        return document.object(for: textNode)
    }

    @discardableResult
    func appendCDATA(_ text: String) -> Node {
        var cdataNode = node.append_child(pugi.node_cdata)
        cdataNode.set_value(text)
        return document.object(for: cdataNode)
    }

    @discardableResult
    func appendComment(_ text: String) -> Node {
        var commentNode = node.append_child(pugi.node_comment)
        commentNode.set_value(text)
        return document.object(for: commentNode)
    }

    var concatenatedText: String {
        children(ofKind: .text).map(\.value).joined()
    }

    var path: String {
        if let parent = parentElement {
            let index = parent[elements: name].firstIndex(of: self)
            let selector = if let index { "[\(index + 1)]" } else { "" }
            return parent.path + "/" + name + selector
        } else {
            return "/" + name
        }
    }
}
