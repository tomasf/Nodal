import Foundation

/// Specifies how `Date` values are encoded and decoded in XML.
///
/// Use this enum to configure the `dateFormat` property on `Document` to control
/// how dates are serialized to and from XML attributes and text content.
///
/// ## Example
/// ```swift
/// let doc = Document()
/// doc.dateFormat = .iso8601
///
/// let root = doc.makeDocumentElement(name: "event")
/// root.setValue(Date.now, forAttribute: "created")
/// ```
public enum XMLDateFormat: Sendable {
    /// ISO 8601 format (e.g., "2024-01-15T10:30:00Z").
    ///
    /// This is the default format and the most common for XML interchange.
    case iso8601

    /// Seconds since January 1, 1970 (Unix timestamp as a floating-point number).
    case secondsSince1970

    /// Milliseconds since January 1, 1970 (integer value).
    case millisecondsSince1970

    /// A custom date format using the provided `DateFormatter`.
    ///
    /// - Note: Ensure the formatter is configured appropriately for your use case,
    ///   including locale and time zone settings.
    case formatted(DateFormatter)

    /// Fully custom encoding and decoding using closures.
    ///
    /// Use this option when you need complete control over the date representation.
    ///
    /// ## Example
    /// ```swift
    /// doc.dateFormat = .custom(
    ///     encode: { date in String(Int(date.timeIntervalSince1970)) },
    ///     decode: { string in
    ///         guard let seconds = Int(string) else { throw MyError.invalidDate }
    ///         return Date(timeIntervalSince1970: Double(seconds))
    ///     }
    /// )
    /// ```
    case custom(
        encode: @Sendable (Date) -> String,
        decode: @Sendable (String) throws -> Date
    )
}

extension XMLDateFormat {
    private static func makeISO8601Formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    func encode(_ date: Date) -> String {
        switch self {
        case .iso8601:
            return Self.makeISO8601Formatter().string(from: date)
        case .secondsSince1970:
            return String(date.timeIntervalSince1970)
        case .millisecondsSince1970:
            return String(Int64(date.timeIntervalSince1970 * 1000))
        case .formatted(let formatter):
            return formatter.string(from: date)
        case .custom(let encode, _):
            return encode(date)
        }
    }

    func decode(_ string: String) throws -> Date {
        switch self {
        case .iso8601:
            guard let date = Self.makeISO8601Formatter().date(from: string) else {
                throw XMLValueError.invalidFormat(expected: "ISO 8601 date", found: string)
            }
            return date
        case .secondsSince1970:
            guard let interval = Double(string) else {
                throw XMLValueError.invalidFormat(expected: "seconds since 1970", found: string)
            }
            return Date(timeIntervalSince1970: interval)
        case .millisecondsSince1970:
            guard let milliseconds = Int64(string) else {
                throw XMLValueError.invalidFormat(expected: "milliseconds since 1970", found: string)
            }
            return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
        case .formatted(let formatter):
            guard let date = formatter.date(from: string) else {
                throw XMLValueError.invalidFormat(expected: "formatted date", found: string)
            }
            return date
        case .custom(_, let decode):
            return try decode(string)
        }
    }
}

extension XMLDateFormat {
    /// Creates a date format using Foundation's `Date.FormatStyle`.
    ///
    /// This uses the modern formatting API available in iOS 15+ / macOS 12+.
    ///
    /// ## Example
    /// ```swift
    /// doc.dateFormat = .style(.dateTime.year().month().day())
    /// ```
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public static func style(_ style: Date.FormatStyle) -> XMLDateFormat {
        .custom(
            encode: { date in date.formatted(style) },
            decode: { string in try Date(string, strategy: style) }
        )
    }
}
