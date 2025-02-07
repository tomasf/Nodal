import Foundation

internal extension String {
    var qualifiedNameParts: (prefix: String?, localName: String) {
        guard let colon = range(of: ":", options: .literal) else {
            return (nil, self)
        }
        return (String(self[..<colon.lowerBound]), String(self[colon.upperBound...]))
    }

    init(prefix: String?, localPart: String) {
        if let prefix {
            self = prefix + ":" + localPart
        } else {
            self = localPart
        }
    }
}

public extension String {
    static let fourSpaces = "    "
}
