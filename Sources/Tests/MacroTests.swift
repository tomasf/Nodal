@testable import Nodal
import Testing

struct MacroTests {
    // These types exist to make sure the macro code compiles

    @XMLCodable
    struct Vehicle {
        let make: String
        @Attribute let model: String
        @Attribute(ExpandedName(namespaceName: "foo", localName: "year")) let year: Int?
        @TextContent let content: String
    }

    @XMLCodable
    struct Person {
        let name: String
        @Element("vehicle", containedIn: "vehicles") let vehicles: [Vehicle]
        let age: Int
        @Element("primaryvehicle", namespace: "sdf") let primaryVehicle: Vehicle?
    }

    @XMLCodable
    struct Root {
        @Element let people: [Person]
    }
}
