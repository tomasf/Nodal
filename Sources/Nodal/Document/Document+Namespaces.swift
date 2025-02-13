import Foundation
import pugixml

public extension Document {
    /// A set of namespace names that are referenced in the document but have not been declared.
    ///
    /// - Note: This property helps identify undeclared namespaces that need to be resolved to generate XML output.
    var undeclaredNamespaceNames: Set<String> {
        Set(pendingNamespaceRecords.flatMap(\.value.namespaceNames))
    }
}

internal extension Document {
    typealias Prefix = NamespaceDeclaration.Prefix

    static let xmlNamespace = (prefix: Prefix("xml"), name: "http://www.w3.org/XML/1998/namespace")
    static let xmlnsNamespace = (prefix: Prefix("xmlns"), name: "http://www.w3.org/2000/xmlns/")

    struct NamespaceDeclaration {
        var node: pugi.xml_node
        var prefix: Prefix
        var namespaceName: String

        enum Prefix: Hashable {
            case defaultNamespace
            case named (String)

            init(_ string: String?) {
                self = if let string { .named(string) } else { .defaultNamespace }
            }

            var string: String? {
                switch self {
                case .named (let string): string
                case .defaultNamespace: nil
                }
            }
        }
    }

    func namespaceDeclarationCount(for node: Node? = nil) -> Int {
        namespaceDeclarationsByPrefix.reduce(0) { result, item in
            result + item.value.filter { if let node { $0.node == node.node } else { true } }.count
        }
    }

    func namespaceName(forPrefix prefix: Prefix, in element: pugi.xml_node) -> String? {
        if prefix == Self.xmlNamespace.prefix { return Self.xmlNamespace.name }
        if prefix == Self.xmlnsNamespace.prefix { return Self.xmlnsNamespace.name }

        guard let candidates = namespaceDeclarationsByPrefix[prefix] else {
            return nil
        }

        // Optimization: If the only candidate is the root element, then it's guaranteed to be right
        if candidates.count == 1, candidates[0].node == pugiDocument.documentElement {
            return candidates[0].namespaceName.nonEmpty
        }

        var node = element
        while(!node.empty()) {
            for candidate in candidates where candidate.node == node {
                return candidate.namespaceName.nonEmpty
            }
            node = node.parent()
        }
        return nil
    }

    func namespacePrefix(forName name: String, in element: pugi.xml_node) -> Prefix? {
        if name == Self.xmlNamespace.name { return Self.xmlNamespace.prefix }
        if name == Self.xmlnsNamespace.name { return Self.xmlnsNamespace.prefix }

        guard let candidates = namespaceDeclarationsByName[name], !candidates.isEmpty else {
            return nil
        }

        // Optimization: If the only candidate is the root element, and the found prefix
        // is the only declaration for that prefix (no shadowing), then we've found our match
        if candidates.count == 1, candidates[0].node == pugiDocument.documentElement {
            let prefix = candidates[0].prefix
            if namespaceDeclarationsByPrefix[prefix]?.count == 1 {
                return candidates[0].prefix
            }
        }

        var node = element
        while(!node.empty()) {
            for candidate in candidates where candidate.node == node {
                if namespaceName(forPrefix: candidate.prefix, in: element) == name {
                    return candidate.prefix
                }
            }
            node = node.parent()
        }
        return nil
    }

    func resetNamespaceDeclarationCache() {
        namespaceDeclarationsByName = [:]
        namespaceDeclarationsByPrefix = [:]
    }

    private func addNamespaceDeclarations(for node: pugi.xml_node) {
        for attribute in node.attributes {
            let name = attribute.name()!
            guard strncmp(name, "xmlns", 5) == 0 else { continue }

            let (prefix, localName) = name.qualifiedNameParts
            let declaration = NamespaceDeclaration(
                node: node,
                prefix: prefix == nil ? .defaultNamespace : .named(localName),
                namespaceName: String(cString: attribute.value())
            )
            namespaceDeclarationsByName[declaration.namespaceName, default: []].append(declaration)
            namespaceDeclarationsByPrefix[declaration.prefix, default: []].append(declaration)
        }
    }

    private func removeNamespaceDeclarations(for nodes: Set<pugi.xml_node>) {
        namespaceDeclarationsByName = namespaceDeclarationsByName.mapValues {
            $0.filter { !nodes.contains($0.node) }
        }
        namespaceDeclarationsByPrefix = namespaceDeclarationsByPrefix.mapValues {
            $0.filter { !nodes.contains($0.node) }
        }
    }

    func removeNamespaceDeclarations(for tree: pugi.xml_node, excludingTarget: Bool = false) {
        let descendants = Set(tree.descendants.filter { $0.type() == pugi.node_element && (!excludingTarget || $0 != tree) })
        removeNamespaceDeclarations(for: descendants)
    }

    func rebuildNamespaceDeclarationCache(for element: Node) {
        removeNamespaceDeclarations(for: [element.node])
        addNamespaceDeclarations(for: element.node)
    }

    func rebuildNamespaceDeclarationCache() {
        resetNamespaceDeclarationCache()

        for node in pugiDocument.documentElement.descendants {
            guard node.type() == pugi.node_element else { continue }
            addNamespaceDeclarations(for: node)
        }
    }

    func declaredNamespacesDidChange(for element: Node) {
        rebuildNamespaceDeclarationCache(for: element)
        for (element, record) in pendingNameRecords(forDescendantsOf: element) {
            if record.attemptResolution(for: element, in: self) {
                removePendingNameRecord(for: element)
            }
        }
    }
}
