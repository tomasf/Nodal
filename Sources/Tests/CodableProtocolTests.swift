@testable import Nodal
import Testing

struct CodableProtocolTests {
    @Test
    func valueCodable() throws {
        let doc = try Document(string: "<root value=\"12345 \" list=\"12 \t34   56 \"/>")
        let root = doc.documentElement!
        let intValue: Int = try root.value(forAttribute: "value")
        #expect(intValue == 12345)

        let doubleValue: Double = try root.value(forAttribute: "value")
        #expect(abs(doubleValue - 12345.0) < .ulpOfOne)

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
            var year: Int

            init(make: String, model: String, year: Int) {
                self.make = make
                self.model = model
                self.year = year
            }

            init(from element: Node) throws {
                make = try element.value(forAttribute: "make")
                model = try element.value(forAttribute: "model")
                year = try element.value(forAttribute: "year")
            }

            func encode(to element: Node) {
                element.setValue(make, forAttribute: "make")
                element.setValue(model, forAttribute: "model")
                element.setValue(year, forAttribute: "year")
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
                primaryVehicle = try element.decode(elementName: "primaryvehicle")
            }

            func encode(to element: Node) {
                element.setValue(name, forAttribute: "name")
                element.setValue(age, forAttribute: "age")
                element.encode(vehicles, elementName: "vehicle", containedIn: "vehicles")
                element.encode(primaryVehicle, elementName: "primaryvehicle")
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
        directory.encode(to: root)
        print(try doc.xmlString())

        let newDirectory: Root = try doc.node.decode(elementName: "directory")

        #expect(directory == newDirectory)
    }
}
