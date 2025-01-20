import Foundation
import pugixml

public typealias NamespaceBindings = [String?: String]

internal extension NamespaceBindings {
    func elementPrefix(for namespaceName: String) -> String?? {
        if self[nil] == namespaceName {
            return nil as String?
        }
        return first(where: { $0.value == namespaceName })?.key
    }

    func attributePrefix(for namespaceName: String) -> String? {
        first(where: { $0.key != nil && $0.value == namespaceName })?.key
    }

    var nameToPrefixMapping: [String: String?] {
        [String: String?](map { ($1, $0) })  { $0 == nil || $1 == nil ? nil as String? : $0 }
    }
}
