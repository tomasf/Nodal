import Foundation

/// Specifies how `Data` values are encoded and decoded in XML.
///
/// Use this enum to configure the `dataFormat` property on `Document` to control
/// how binary data is serialized to and from XML attributes and text content.
///
/// ## Example
/// ```swift
/// let doc = Document()
/// doc.dataFormat = .hex
///
/// let root = doc.makeDocumentElement(name: "file")
/// root.setValue(someData, forAttribute: "checksum")
/// ```
public enum XMLDataFormat: Sendable {
    /// Base64 encoding (default).
    ///
    /// This is the most common encoding for binary data in XML.
    case base64

    /// Hexadecimal encoding (e.g., "48656c6c6f" for "Hello").
    ///
    /// Uses lowercase hexadecimal digits.
    case hex

    /// Fully custom encoding and decoding using closures.
    ///
    /// Use this option when you need complete control over the data representation.
    ///
    /// ## Example
    /// ```swift
    /// doc.dataFormat = .custom(
    ///     encode: { data in data.map { String(format: "%02X", $0) }.joined() },
    ///     decode: { string in
    ///         // Custom decoding logic
    ///     }
    /// )
    /// ```
    case custom(
        encode: @Sendable (Data) -> String,
        decode: @Sendable (String) throws -> Data
    )
}

extension XMLDataFormat {
    func encode(_ data: Data) -> String {
        switch self {
        case .base64:
            return data.base64EncodedString()
        case .hex:
            return data.map { String(format: "%02x", $0) }.joined()
        case .custom(let encode, _):
            return encode(data)
        }
    }

    func decode(_ string: String) throws -> Data {
        switch self {
        case .base64:
            guard let data = Data(base64Encoded: string) else {
                throw XMLValueError.invalidFormat(expected: "base64-encoded data", found: string)
            }
            return data
        case .hex:
            return try decodeHex(string)
        case .custom(_, let decode):
            return try decode(string)
        }
    }

    private func decodeHex(_ string: String) throws -> Data {
        let hex = string.lowercased()
        guard hex.count % 2 == 0 else {
            throw XMLValueError.invalidFormat(expected: "hex-encoded data (even length)", found: string)
        }

        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else {
                throw XMLValueError.invalidFormat(expected: "hex-encoded data", found: string)
            }
            data.append(byte)
            index = nextIndex
        }

        return data
    }
}
