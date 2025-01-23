import Foundation
import pugixml

internal extension ExpandedName {
    init(effectiveQualifiedAttributeName qName: String, in element: Element) {
        if PendingNameRecord.qualifiedNameIndicatesPending(qName),
           let record = element.pendingNameRecord,
           let pendingExpandedName = record.pendingExpandedAttributeName(for: qName) {
            self = pendingExpandedName
            return
        }

        if let prefix = qName.qNamePrefix {
            let namespaceName = element.namespaceName(forPrefix: .named(prefix))
            self.init(namespaceName: namespaceName, localName: qName.qNameLocalName)
        } else {
            self.init(namespaceName: nil, localName: qName)
        }
    }

    func requestQualifiedElementName(for element: Element) -> String {
        let prefix: String?
        if let namespaceName {
            if let match = element.namespacePrefix(forName: namespaceName) {
                prefix = match.string
            } else {
                prefix = element.requirePendingNameRecord().addUnresolvedElementName(self, for: element)
            }
        } else {
            guard element.namespaceName(forPrefix: .defaultNamespace) == nil else {
                fatalError("Can't use a nil namespace when there's a default namespace in scope")
            }
            prefix = nil
        }

        return String(prefix: prefix, localPart: localName)
    }

    func requestQualifiedAttributeName(for element: Element) -> String {
        guard let namespaceName else {
            return localName
        }

        // Reminder: Attributes in a namespace MUST have a prefix. An attribute can not belong to a namespace that is only declared as default

        guard let prefix = element.namespacePrefix(forName: namespaceName),
              let prefixString = prefix.string
        else {
            return element.requirePendingNameRecord().addUnresolvedAttribute(self, in: element)
        }
        return String(prefix: prefixString, localPart: localName)
    }
}
