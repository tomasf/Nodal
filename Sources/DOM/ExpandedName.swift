import Foundation

public struct ExpandedName: Hashable, Sendable {
    public let namespaceName: String?
    public let localName: String

    public init(namespaceName uri: String?, localName: String) {
        self.namespaceName = uri
        self.localName = localName
    }
}

internal extension ExpandedName {
    // Returns nil if the namespace could not be resolved
    func qualifiedAttributeName(using namespaces: [String?: String]) -> String? {
        if let namespaceName {
            // Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default
            guard let prefix = namespaces.first(where: { $0.value == namespaceName && $0.key != nil })?.key else {
                return nil
            }
            return prefix + ":" + localName
        } else {
            return localName
        }
    }

    init(qualifiedAttributeName qName: String, using namespaces: [String?: String]) {
        self.init(namespaceName: namespaces[qName.qNamePrefix], localName: qName.qNameLocalName)
    }

    func qualifiedElementName(using namespaces: [String?: String]) -> String {
        let prefix: String?
        if let namespaceName {
            guard let pair = namespaces.first(where: { $0.value == namespaceName }) else {
                fatalError("No namespace declaration found for URI \(namespaceName)")
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
