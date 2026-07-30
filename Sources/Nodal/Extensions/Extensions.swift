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

    var trimmed: String {
        // Fast path: most values in real-world XML have no leading or trailing whitespace
        func isASCIIWhitespace(_ byte: UInt8) -> Bool {
            byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
        }
        guard let first = utf8.first, let last = utf8.last,
              isASCIIWhitespace(first) || isASCIIWhitespace(last)
        else {
            return self
        }
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension String {
    static let fourSpaces = "    "

    var nonEmpty: String? {
        isEmpty ? nil : self
    }
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
