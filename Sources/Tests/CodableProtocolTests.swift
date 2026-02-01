@testable import Nodal
import Foundation
import Testing

struct CodableProtocolTests {
    @Test
    func valueCodable() throws {
        let doc = try Document(string: "<root value=\"12345 \" list=\"12 \t34   56 \"/>")
        let root = doc.documentElement!
        let intValue: Int = try root.value(forAttribute: "value")
        #expect(intValue == 12345)

        let doubleValue: Double = try root.value(forAttribute: "value")
        #expect(Swift.abs(doubleValue - 12345.0) < .ulpOfOne)

        #expect(throws: XMLValueError.self) {
            let _: Bool = try root.value(forAttribute: "value")
        }

        root.setValue(true, forAttribute: "boolean")
        #expect(root[attribute: "boolean"] == "true")

        let integers: [Int] = try root.value(forAttribute: "list")
        #expect(integers == [12, 34, 56])

        root.setValue([12,55,-4], forAttribute: "numbers")
        #expect(root[attribute: "numbers"] == "12 55 -4")
    }

    @Test
    func elementCodable() throws {
        struct Vehicle: XMLElementCodable, Equatable {
            var make: String
            var model: String
            var year: Int?

            init(make: String, model: String, year: Int? = nil) {
                self.make = make
                self.model = model
                self.year = year
            }

            init(from element: Node) throws {
                make = try element.value(forAttribute: "make")
                model = try element.value(forAttribute: "model")
                year = try element.value(forAttribute: ExpandedName(namespaceName: "foo", localName: "year"))
            }

            func encode(to element: Node) {
                element.setValue(make, forAttribute: "make")
                element.setValue(model, forAttribute: "model")
                element.setValue(year, forAttribute: ExpandedName(namespaceName: "foo", localName: "year"))
            }
        }

        struct Person: XMLElementCodable, Equatable {
            var name: String
            var age: Int
            var vehicles: [Vehicle]
            var primaryVehicle: Vehicle?

            init(name: String, age: Int, vehicles: [Vehicle], primaryVehicle: Vehicle? = nil) {
                self.name = name
                self.age = age
                self.vehicles = vehicles
                self.primaryVehicle = primaryVehicle
            }

            init(from element: Node) throws {
                name = try element.value(forAttribute: "name")
                age = try element.value(forAttribute: "age")
                vehicles = try element.decode(elementName: "vehicle", containedIn: "vehicles")
                primaryVehicle = try element.decode(elementName: ExpandedName(namespaceName: "foo", localName: "primary"))
            }

            func encode(to element: Node) {
                element.setValue(name, forAttribute: "name")
                element.setValue(age, forAttribute: "age")
                element.encode(vehicles, elementName: "vehicle", containedIn: "vehicles")
                element.encode(primaryVehicle, elementName: ExpandedName(namespaceName: "foo", localName: "primary"))
            }
        }

        struct Root: XMLElementCodable, Equatable {
            var people: [Person]

            init() {
                people = []
            }

            init(from element: Node) throws {
                people = try element.decode(elementName: "person")
            }

            func encode(to element: Node) {
                element.encode(people, elementName: "person")
            }
        }

        var directory = Root()
        directory.people = [
            .init(
                name: "Steve",
                age: 42,
                vehicles: [
                    .init(make: "Ford", model: "Focus", year: 2001),
                    .init(make: "Volvo", model: "V90", year: 2009)
                ],
                primaryVehicle: .init(make: "Renault", model: "Banana", year: 2019)
            ),
            .init(
                name: "John",
                age: 58,
                vehicles: [
                    .init(make: "Citroen", model: "Saxo", year: 2002)
                ],
                primaryVehicle: .init(make: "Honda", model: "Pilot", year: 2003)
            )
        ]

        let doc = Document()
        let root = doc.makeDocumentElement(name: "directory")
        root.declareNamespace("foo", forPrefix: "f")
        directory.encode(to: root)

        let newDirectory: Root = try doc.node.decode(elementName: "directory")
        #expect(directory == newDirectory)
    }

    // MARK: - URL

    @Test
    func urlCodable() throws {
        let doc = try Document(string: "<root link=\"https://example.com/path?query=1\"/>")
        let root = doc.documentElement!

        let url: URL = try root.value(forAttribute: "link")
        #expect(url.absoluteString == "https://example.com/path?query=1")

        root.setValue(URL(string: "https://test.org")!, forAttribute: "newLink")
        #expect(root[attribute: "newLink"] == "https://test.org")
    }

    @Test
    func urlInvalid() throws {
        // Unclosed bracket causes URL(string:) to return nil
        let doc = try Document(string: "<root link=\"http://[invalid\"/>")
        #expect(throws: XMLValueError.self) {
            let _: URL = try doc.documentElement!.value(forAttribute: "link")
        }
    }

    @Test
    func urlContent() throws {
        let doc = try Document(string: "<link>https://example.com</link>")
        let link = doc.documentElement!

        let url: URL = try link.content()
        #expect(url.absoluteString == "https://example.com")

        link.setContent(URL(string: "https://new.example.com")!)
        #expect(link.textContent == "https://new.example.com")
    }

    // MARK: - Data

    @Test
    func dataCodable() throws {
        let originalData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        let base64 = originalData.base64EncodedString() // "SGVsbG8="

        let doc = try Document(string: "<root data=\"\(base64)\"/>")
        let root = doc.documentElement!

        let decodedData: Data = try root.value(forAttribute: "data")
        #expect(decodedData == originalData)

        let newData = Data([0x57, 0x6F, 0x72, 0x6C, 0x64]) // "World"
        root.setValue(newData, forAttribute: "newData")
        #expect(root[attribute: "newData"] == "V29ybGQ=")
    }

    @Test
    func dataInvalid() throws {
        let doc = try Document(string: "<root data=\"!!invalid!!\"/>")
        #expect(throws: XMLValueError.self) {
            let _: Data = try doc.documentElement!.value(forAttribute: "data")
        }
    }

    @Test
    func dataContent() throws {
        let originalData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        let doc = try Document(string: "<data>SGVsbG8=</data>")

        let decodedData: Data = try doc.documentElement!.content()
        #expect(decodedData == originalData)
    }

    @Test
    func dataHexEncoding() throws {
        let doc = Document()
        doc.dataFormat = .hex
        let root = doc.makeDocumentElement(name: "root")

        let originalData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        root.setValue(originalData, forAttribute: "data")

        #expect(root[attribute: "data"] == "48656c6c6f")

        let decoded: Data = try root.value(forAttribute: "data")
        #expect(decoded == originalData)
    }

    @Test
    func dataHexContent() throws {
        let doc = Document()
        doc.dataFormat = .hex
        let root = doc.makeDocumentElement(name: "data")

        let originalData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        root.setContent(originalData)

        #expect(root.textContent == "48656c6c6f")

        let decoded: Data = try root.content()
        #expect(decoded == originalData)
    }

    @Test
    func dataHexInvalid() throws {
        let doc = try Document(string: "<root data=\"xyz\"/>")
        doc.dataFormat = .hex

        #expect(throws: XMLValueError.self) {
            let _: Data = try doc.documentElement!.value(forAttribute: "data")
        }
    }

    @Test
    func dataHexOddLength() throws {
        let doc = try Document(string: "<root data=\"abc\"/>")
        doc.dataFormat = .hex

        #expect(throws: XMLValueError.self) {
            let _: Data = try doc.documentElement!.value(forAttribute: "data")
        }
    }

    @Test
    func dataCustomFormat() throws {
        let doc = Document()
        doc.dataFormat = .custom(
            encode: { data in data.map { String(format: "%02X", $0) }.joined() },
            decode: { string in
                let hex = string.lowercased()
                guard hex.count % 2 == 0 else {
                    throw XMLValueError.invalidFormat(expected: "uppercase hex", found: string)
                }
                var data = Data(capacity: hex.count / 2)
                var index = hex.startIndex
                while index < hex.endIndex {
                    let nextIndex = hex.index(index, offsetBy: 2)
                    guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                        throw XMLValueError.invalidFormat(expected: "uppercase hex", found: string)
                    }
                    data.append(byte)
                    index = nextIndex
                }
                return data
            }
        )
        let root = doc.makeDocumentElement(name: "root")

        let originalData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        root.setValue(originalData, forAttribute: "data")

        // Custom format uses uppercase
        #expect(root[attribute: "data"] == "48656C6C6F")

        let decoded: Data = try root.value(forAttribute: "data")
        #expect(decoded == originalData)
    }

    @Test
    func dataArray() throws {
        let doc = Document()
        doc.dataFormat = .hex
        let root = doc.makeDocumentElement(name: "root")

        let dataArray = [
            Data([0x01, 0x02]),
            Data([0x03, 0x04]),
            Data([0x05, 0x06])
        ]
        root.setValue(dataArray, forAttribute: "items")

        #expect(root[attribute: "items"] == "0102 0304 0506")

        let decoded: [Data] = try root.value(forAttribute: "items")
        #expect(decoded == dataArray)
    }

    @Test
    func dataArrayContent() throws {
        let doc = Document()
        doc.dataFormat = .hex
        let root = doc.makeDocumentElement(name: "data")

        let dataArray = [
            Data([0xAB, 0xCD]),
            Data([0xEF, 0x12])
        ]
        root.setContent(dataArray)

        #expect(root.textContent == "abcd ef12")

        let decoded: [Data] = try root.content()
        #expect(decoded == dataArray)
    }

    // MARK: - Date

    @Test
    func dateISO8601() throws {
        let doc = Document()
        doc.dateFormat = .iso8601
        let root = doc.makeDocumentElement(name: "root")

        let date = Date(timeIntervalSince1970: 1705312200) // 2024-01-15T10:30:00Z
        root.setValue(date, forAttribute: "timestamp")

        let encoded = root[attribute: "timestamp"]!
        #expect(encoded.contains("2024-01-15"))

        let decoded: Date = try root.value(forAttribute: "timestamp")
        #expect(Swift.abs(decoded.timeIntervalSince1970 - date.timeIntervalSince1970) < 1)
    }

    @Test
    func dateSecondsSince1970() throws {
        let doc = Document()
        doc.dateFormat = .secondsSince1970
        let root = doc.makeDocumentElement(name: "root")

        let date = Date(timeIntervalSince1970: 1705312200.5)
        root.setValue(date, forAttribute: "timestamp")

        #expect(root[attribute: "timestamp"] == "1705312200.5")

        let decoded: Date = try root.value(forAttribute: "timestamp")
        #expect(Swift.abs(decoded.timeIntervalSince1970 - 1705312200.5) < 0.001)
    }

    @Test
    func dateMillisecondsSince1970() throws {
        let doc = Document()
        doc.dateFormat = .millisecondsSince1970
        let root = doc.makeDocumentElement(name: "root")

        let date = Date(timeIntervalSince1970: 1705312200.123)
        root.setValue(date, forAttribute: "timestamp")

        #expect(root[attribute: "timestamp"] == "1705312200123")

        let decoded: Date = try root.value(forAttribute: "timestamp")
        #expect(Swift.abs(decoded.timeIntervalSince1970 - 1705312200.123) < 0.001)
    }

    @Test
    func dateCustomFormatter() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let doc = Document()
        doc.dateFormat = .formatted(formatter)
        let root = doc.makeDocumentElement(name: "root")

        let date = Date(timeIntervalSince1970: 1705312200)
        root.setValue(date, forAttribute: "date")

        #expect(root[attribute: "date"] == "2024-01-15")

        let decoded: Date = try root.value(forAttribute: "date")
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: decoded)
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func dateFormatStyle() throws {
        let doc = Document()
        var style = Date.FormatStyle.dateTime
            .year().month().day().hour().minute().second()
        style.timeZone = TimeZone(identifier: "UTC")!
        doc.dateFormat = .style(style)
        let root = doc.makeDocumentElement(name: "root")

        let date = Date(timeIntervalSince1970: 1705312200) // 2024-01-15T10:30:00Z
        root.setValue(date, forAttribute: "date")

        let encoded = root[attribute: "date"]!
        #expect(encoded.contains("2024"))

        let decoded: Date = try root.value(forAttribute: "date")
        // Allow small difference due to format precision
        #expect(Swift.abs(decoded.timeIntervalSince1970 - date.timeIntervalSince1970) < 1)
    }

    @Test
    func dateCustomClosure() throws {
        let doc = Document()
        doc.dateFormat = .custom(
            encode: { date in String(Int(date.timeIntervalSince1970)) },
            decode: { string in
                guard let seconds = Int(string) else {
                    throw XMLValueError.invalidFormat(expected: "integer timestamp", found: string)
                }
                return Date(timeIntervalSince1970: Double(seconds))
            }
        )
        let root = doc.makeDocumentElement(name: "root")

        let date = Date(timeIntervalSince1970: 1705312200)
        root.setValue(date, forAttribute: "timestamp")

        #expect(root[attribute: "timestamp"] == "1705312200")

        let decoded: Date = try root.value(forAttribute: "timestamp")
        #expect(decoded.timeIntervalSince1970 == 1705312200)
    }

    @Test
    func dateContent() throws {
        let doc = Document()
        doc.dateFormat = .secondsSince1970
        let root = doc.makeDocumentElement(name: "timestamp")

        let date = Date(timeIntervalSince1970: 1705312200)
        root.setContent(date)

        #expect(root.textContent == "1705312200.0")

        let decoded: Date = try root.content()
        #expect(Swift.abs(decoded.timeIntervalSince1970 - 1705312200) < 0.001)
    }

    @Test
    func dateInvalid() throws {
        let doc = try Document(string: "<root timestamp=\"not-a-date\"/>")
        doc.dateFormat = .iso8601

        #expect(throws: XMLValueError.self) {
            let _: Date = try doc.documentElement!.value(forAttribute: "timestamp")
        }
    }

    @Test
    func dateArray() throws {
        let doc = Document()
        doc.dateFormat = .secondsSince1970
        let root = doc.makeDocumentElement(name: "root")

        let dates = [
            Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 2000),
            Date(timeIntervalSince1970: 3000)
        ]
        root.setValue(dates, forAttribute: "timestamps")

        #expect(root[attribute: "timestamps"] == "1000.0 2000.0 3000.0")

        let decoded: [Date] = try root.value(forAttribute: "timestamps")
        #expect(decoded.count == 3)
        #expect(Swift.abs(decoded[0].timeIntervalSince1970 - 1000) < 0.001)
        #expect(Swift.abs(decoded[1].timeIntervalSince1970 - 2000) < 0.001)
        #expect(Swift.abs(decoded[2].timeIntervalSince1970 - 3000) < 0.001)
    }
}
