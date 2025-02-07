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

extension UnsafePointer<CChar> {
    var qualifiedNameParts: (prefix: String?, localName: String) {
        guard let separator = strstr(self, ":"),
              let prefix = String(data: Data(bytes: self, count: distance(to: separator)), encoding: .utf8)
        else {
            return (nil, String(cString: self))
        }

        return (prefix, String(cString: separator + 1))
    }
}
