@testable import Nodal
import Testing

struct MacroTests {
    @XMLCodable
    struct Vehicle {
        let make: String
        let model: String
        @Attribute(ExpandedName(namespaceName: "foo", localName: "year")) let year: Int?
        @TextContent let content: String

        init(make: String, model: String, year: Int?, content: String) {
            self.make = make
            self.model = model
            self.year = year
            self.content = content
        }
    }

    @XMLCodable
    struct Person {
        let name: String
        let age: Int
        @Element("vehicle", containedIn: "vehicles") let vehicles: [Vehicle]
        @Element("primaryvehicle", namespace: "foo") let primaryVehicle: Vehicle?

        init(name: String, vehicles: [Vehicle], age: Int, primaryVehicle: Vehicle?) {
            self.name = name
            self.vehicles = vehicles
            self.age = age
            self.primaryVehicle = primaryVehicle
        }
    }

    @XMLCodable
    struct Root {
        @Element("person") let people: [Person]

        init(people: [Person]) {
            self.people = people
        }
    }

    @Test
    func macros() throws {
        let vehicle1 = Vehicle(
            make: "Toyota",
            model: "Corolla",
            year: 2018,
            content: "Reliable compact sedan"
        )

        let vehicle2 = Vehicle(
            make: "Ford",
            model: "Mustang",
            year: 2020,
            content: "Classic American muscle car"
        )

        let vehicle3 = Vehicle(
            make: "Tesla",
            model: "Model 3",
            year: 2022,
            content: "Electric sedan with autopilot"
        )

        let vehicle4 = Vehicle(
            make: "Honda",
            model: "Civic",
            year: 2019,
            content: "Fuel-efficient everyday car"
        )

        // Person 1 - Has two vehicles but no primary vehicle
        let person1 = Person(
            name: "Alice",
            vehicles: [vehicle1, vehicle2],
            age: 30,
            primaryVehicle: nil
        )

        // Person 2 - Has two vehicles, and one is their primary vehicle
        let person2 = Person(
            name: "Bob",
            vehicles: [vehicle3, vehicle4],
            age: 40,
            primaryVehicle: vehicle3
        )

        // Root containing both people
        let root = Root(people: [person1, person2])

        let doc = Document(root, elementName: "people")
        doc.documentElement?.declareNamespace("foo", forPrefix: "f")
        let xml = try doc.xmlString(options: [.raw, .noDeclaration])

        #expect(xml == """
<people xmlns:f="foo"><person name="Alice" age="30"><vehicles><vehicle make="Toyota" model="Corolla" f:year="2018">Reliable compact sedan</vehicle><vehicle make="Ford" model="Mustang" f:year="2020">Classic American muscle car</vehicle></vehicles></person><person name="Bob" age="40"><vehicles><vehicle make="Tesla" model="Model 3" f:year="2022">Electric sedan with autopilot</vehicle><vehicle make="Honda" model="Civic" f:year="2019">Fuel-efficient everyday car</vehicle></vehicles><f:primaryvehicle make="Tesla" model="Model 3" f:year="2022">Electric sedan with autopilot</f:primaryvehicle></person></people>
""")
    }
}
