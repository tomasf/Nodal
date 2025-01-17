import Foundation

public struct ExpandedName: Hashable, Sendable {
    public let uri: String?
    public let localName: String

    public init(uri namespaceURI: String?, localName: String) {
        self.uri = namespaceURI
        self.localName = localName
    }
}

internal extension ExpandedName {
    // Returns nil if the namespace could not be resolved
    func qualifiedAttributeName(using namespaces: [String?: String]) -> String? {
        if let uri {
            // Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default
            guard let prefix = namespaces.first(where: { $0.value == uri && $0.key != nil })?.key else {
                return nil
            }
            return prefix + ":" + localName
        } else {
            return localName
        }
    }

    init(qualifiedAttributeName qName: String, using namespaces: [String?: String]) {
        self.init(uri: namespaces[qName.qNamePrefix], localName: qName.qNameLocalName)
    }

    func qualifiedElementName(using namespaces: [String?: String]) -> String {
        let prefix: String?
        if let uri {
            guard let pair = namespaces.first(where: { $0.value == uri }) else {
                fatalError("No namespace declaration found for URI \(uri)")
            }
            prefix = pair.key
        } else {
            guard namespaces[nil] == nil else {
                fatalError("Can't use a nil namespace when there's a default namespace in scope")
            }
            prefix = nil
        }

        return if let prefix { prefix + ":" + localName } else { localName }
    }
}
