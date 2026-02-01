import Foundation

extension String: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { self }
    public init(xmlStringValue: String, for node: Node) throws { self = xmlStringValue }
}

extension Bool: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { self ? "true" : "false" }

    public init(xmlStringValue: String, for node: Node) throws {
        switch xmlStringValue {
        case "true", "1": self = true
        case "false", "0": self = false
        default: throw XMLValueError.invalidFormat(expected: "Boolean", found: xmlStringValue)
        }
    }
}

extension Double: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let double = Double(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Double", found: xmlStringValue)
        }
        self = double
    }
}

extension Float: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let float = Float(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Float", found: xmlStringValue)
        }
        self = float
    }
}

extension Int: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let int = Int(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int", found: xmlStringValue)
        }
        self = int
    }
}

extension Int8: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = Int8(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int8", found: xmlStringValue)
        }
        self = value
    }
}

extension Int16: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = Int16(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int16", found: xmlStringValue)
        }
        self = value
    }
}

extension Int32: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = Int32(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int32", found: xmlStringValue)
        }
        self = value
    }
}

extension Int64: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = Int64(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int64", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = UInt(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt8: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = UInt8(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt8", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt16: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = UInt16(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt16", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt32: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = UInt32(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt32", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt64: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { String(self) }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = UInt64(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt64", found: xmlStringValue)
        }
        self = value
    }
}

extension UUID: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { uuidString }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let value = UUID(uuidString: xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UUID", found: xmlStringValue)
        }
        self = value
    }
}

extension URL: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String { absoluteString }

    public init(xmlStringValue: String, for node: Node) throws {
        guard let url = URL(string: xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "URL", found: xmlStringValue)
        }
        self = url
    }
}

extension Date: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String {
        node.document.dateFormat.encode(self)
    }

    public init(xmlStringValue: String, for node: Node) throws {
        self = try node.document.dateFormat.decode(xmlStringValue)
    }
}

extension Data: XMLValueCodable {
    public func xmlStringValue(for node: Node) -> String {
        node.document.dataFormat.encode(self)
    }

    public init(xmlStringValue: String, for node: Node) throws {
        self = try node.document.dataFormat.decode(xmlStringValue)
    }
}

extension RawRepresentable where RawValue: XMLValueEncodable {
    public func xmlStringValue(for node: Node) -> String {
        rawValue.xmlStringValue(for: node)
    }
}

extension RawRepresentable where RawValue: XMLValueDecodable {
    public init(xmlStringValue string: String, for node: Node) throws {
        let raw = try RawValue(xmlStringValue: string, for: node)
        guard let value = Self(rawValue: raw) else {
            throw XMLValueError.invalidFormat(expected: "\(String(describing: Self.self))", found: string)
        }
        self = value
    }
}
