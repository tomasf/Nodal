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

        let namespaceName = element.namespaceName(for: qName.qNamePrefix)
        self.init(namespaceName: namespaceName, localName: qName.qNameLocalName)
    }

    func requestQualifiedElementName(for element: Element) -> String {
        let prefix: String?
        if let namespaceName {
            if let match = element.prefix(for: namespaceName) {
                prefix = match == "" ? nil : match
            } else {
                prefix = element.requirePendingNameRecord().addUnresolvedElementName(self, for: element)
            }
        } else {
            guard element.namespaceName(for: nil) == nil else {
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
        guard let prefix = element.prefix(for: namespaceName), prefix != "" else {
            return element.requirePendingNameRecord().addUnresolvedAttribute(self, in: element)
        }
        return String(prefix: prefix, localPart: localName)
    }
}
