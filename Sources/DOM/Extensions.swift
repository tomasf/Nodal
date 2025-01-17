import Foundation

internal extension String {
    var qNamePrefix: String? {
        guard let colon = range(of: ":") else { return nil }
        return String(self[..<colon.lowerBound])
    }

    var qNameLocalName: String {
        guard let colon = range(of: ":") else { return self }
        return String(self[colon.upperBound...])
    }
}

public extension String {
    static let fourSpaces = "    "
}
