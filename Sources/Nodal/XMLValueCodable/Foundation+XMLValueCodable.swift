import Foundation

extension String: XMLValueCodable {
    public var xmlStringValue: String { self }
    public init(xmlStringValue: String) throws { self = xmlStringValue }
}

extension Bool: XMLValueCodable {
    public var xmlStringValue: String { self ? "true" : "false" }

    public init(xmlStringValue: String) throws {
        switch xmlStringValue {
        case "true", "1": self = true
        case "false", "0": self = false
        default: throw XMLValueError.invalidFormat(expected: "Boolean", found: xmlStringValue)
        }
    }
}

extension Double: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let double = Double(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Double", found: xmlStringValue)
        }
        self = double
    }
}

extension Float: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let float = Float(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Float", found: xmlStringValue)
        }
        self = float
    }
}

extension Int: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let int = Int(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int", found: xmlStringValue)
        }
        self = int
    }
}

extension Int8: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = Int8(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int8", found: xmlStringValue)
        }
        self = value
    }
}

extension Int16: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = Int16(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int16", found: xmlStringValue)
        }
        self = value
    }
}

extension Int32: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = Int32(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int32", found: xmlStringValue)
        }
        self = value
    }
}

extension Int64: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = Int64(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "Int64", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = UInt(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt8: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = UInt8(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt8", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt16: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = UInt16(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt16", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt32: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = UInt32(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt32", found: xmlStringValue)
        }
        self = value
    }
}

extension UInt64: XMLValueCodable {
    public var xmlStringValue: String { String(self) }

    public init(xmlStringValue: String) throws {
        guard let value = UInt64(xmlStringValue) else {
            throw XMLValueError.invalidFormat(expected: "UInt64", found: xmlStringValue)
        }
        self = value
    }
}
