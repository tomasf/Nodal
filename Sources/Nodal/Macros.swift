import Foundation

/// Automatically provides `XMLElementCodable` conformance to a type.
///
/// This macro generates both an initializer (`init(from element: Node)`) and an encoding method (`encode(to element: Node)`)
/// to allow seamless conversion between Swift types and XML elements.
///
/// ## Example Usage
/// ```swift
/// @XMLCodable
/// struct Person {
///     @Attribute var name: String
///     @Attribute var age: Int
///     @Element var address: Address
/// }
/// ```
/// This expands to:
/// ```swift
/// struct Person: XMLElementCodable {
///     let name: String
///     let age: Int
///     let address: Address
///
///     init(from element: Node) throws { ... }
///     func encode(to element: Node) { ... }
/// }
/// ```
///
/// - SeeAlso: `@XMLEncodable`, `@XMLDecodable`
@attached(member, names: named(init), named(encode))
@attached(extension, conformances: XMLElementCodable)
public macro XMLCodable() = #externalMacro(module: "NodalMacros", type: "XMLCodableMacro")

/// Automatically provides `XMLElementEncodable` conformance to a type.
///
/// This macro generates an `encode(to element: Node)` method, allowing the type to be serialized into XML.
///
/// ## Example Usage
/// ```swift
/// @XMLEncodable
/// struct Animal {
///     @Attribute var species: String
///     @Element var habitat: Habitat
/// }
/// ```
/// This expands to:
/// ```swift
/// struct Animal: XMLElementEncodable {
///     let species: String
///     let habitat: Habitat
///
///     func encode(to element: Node) { ... }
/// }
/// ```
///
/// - SeeAlso: `@XMLDecodable`, `@XMLCodable`
@attached(member, names: named(init), named(encode))
@attached(extension, conformances: XMLElementEncodable)
public macro XMLEncodable() = #externalMacro(module: "NodalMacros", type: "XMLEncodableMacro")

/// Automatically provides `XMLElementDecodable` conformance to a type.
///
/// This macro generates an `init(from element: Node)` initializer, allowing the type to be constructed from XML.
///
/// ## Example Usage
/// ```swift
/// @XMLDecodable
/// struct Animal {
///     @Attribute var species: String
///     @Element var habitat: Habitat
/// }
/// ```
/// This expands to:
/// ```swift
/// struct Animal: XMLElementDecodable {
///     let species: String
///     let habitat: Habitat
///
///     init(from element: Node) throws { ... }
/// }
/// ```
///
/// - SeeAlso: `@XMLEncodable`, `@XMLCodable`
@attached(member, names: named(init), named(encode))
@attached(extension, conformances: XMLElementDecodable)
public macro XMLDecodable() = #externalMacro(module: "NodalMacros", type: "XMLDecodableMacro")


/// Marks a property as an XML attribute.
///
/// Any property not marked as `@Element` or `@TextContent` is *automatically assumed* to be an attribute.
/// However, this macro can be used to explicitly define an attribute, rename it, or specify a namespace.
///
/// ## Example Usage
///
/// **Basic Attribute**
/// ```swift
/// @Attribute var animalName: String
/// ```
/// Expands to:
/// ```xml
/// <Animal animalName="Lion" />
/// ```
///
/// **Custom Attribute Name**
/// ```swift
/// @Attribute("animal") var animalName: String
/// ```
/// Expands to:
/// ```xml
/// <Animal animal="Lion" />
/// ```
///
/// **Namespaced Attribute**
/// ```swift
/// @Attribute("animal", namespace: "http://example.com") var animalName: String
/// ```
/// Expands to (assuming the namespace is bound to the "ex" prefix):
/// ```xml
/// <Animal ex:animal="Lion" />
/// ```
///
/// - SeeAlso: `@Element`, `@TextContent`
@attached(peer)
public macro Attribute() = #externalMacro(module: "NodalMacros", type: "MarkerMacro")

@attached(peer)
public macro Attribute(
    _ name: any AttributeName
) = #externalMacro(module: "NodalMacros", type: "MarkerMacro")

@attached(peer)
public macro Attribute(
    _ localName: String,
    namespace: String?
) = #externalMacro(module: "NodalMacros", type: "MarkerMacro")


/// Marks a property as an XML element.
///
/// Properties marked with `@Element` are serialized as *child elements* of the XML node.
/// These properties are of a type that conforms to `XMLElementCodable`.
///
/// ## Example Usage
///
/// **Single Nested Element**
/// ```swift
/// struct Habitat: XMLElementCodable {
///     @Attribute var climate: String
/// }
///
/// struct Animal: XMLElementCodable {
///     @Element var habitat: Habitat
/// }
/// ```
/// Expands to:
/// ```xml
/// <Animal>
///     <habitat climate="tropical" />
/// </Animal>
/// ```
///
/// **Custom Element Name**
/// ```swift
/// struct Animal: XMLElementCodable {
///     @Element("home") var habitat: Habitat
/// }
/// ```
/// Expands to:
/// ```xml
/// <Animal>
///     <home climate="tropical" />
/// </Animal>
/// ```
///
/// **Namespaced Element**
/// ```swift
/// struct Animal: XMLElementCodable {
///     @Element("habitat", namespace: "http://example.com") var habitat: Habitat
/// }
/// ```
/// Expands to (assuming the namespace is bound to the "ex" prefix):
/// ```xml
/// <Animal>
///     <ex:habitat climate="tropical" />
/// </Animal>
/// ```
///
/// **Array of Nested Elements (Flat Structure)**
/// ```swift
/// struct Zoo: XMLElementCodable {
///     @Element var animals: [Animal]
/// }
/// ```
/// Expands to:
/// ```xml
/// <Zoo>
///     <Animal>
///         <habitat climate="tropical" />
///     </Animal>
///     <Animal>
///         <habitat climate="temperate" />
///     </Animal>
/// </Zoo>
/// ```
///
/// **Using `containedIn` for Arrays (Wrapper Element)**
/// ```swift
/// struct Zoo: XMLElementCodable {
///     @Element("animal", containedIn: "animals") var animals: [Animal]
/// }
/// ```
/// Expands to:
/// ```xml
/// <Zoo>
///     <animals>
///         <animal>
///             <habitat climate="tropical" />
///         </animal>
///         <animal>
///             <habitat climate="temperate" />
///         </animal>
///     </animals>
/// </Zoo>
/// ```
///
/// **Important Notes:**
/// - **Element properties should conform to `XMLElementCodable`.**
/// - **Use `containedIn` for arrays if you need a wrapper element.**
///
/// - SeeAlso: `@Attribute`, `@TextContent`
@attached(peer)
public macro Element(
    _ name: (any ElementName)? = nil,
    namespace: String? = nil,
    containedIn: (any ElementName)? = nil
) = #externalMacro(module: "NodalMacros", type: "MarkerMacro")

/// Marks a property as the *text content* of an XML element.
///
/// A property marked with `@TextContent` is serialized as **the text inside the element**, rather than an attribute or child element.
/// A struct *can only have one* `@TextContent` property, and can not co-exist with `@Element` properties.
///
/// ## Example Usage
///
/// **Basic Text Content**
/// ```swift
/// @TextContent var content: String
/// ```
/// Expands to:
/// ```xml
/// <Message>Hello, World!</Message>
/// ```
///
/// **With Attributes**
/// ```swift
/// struct Message {
///     @Attribute var sender: String
///     @TextContent var content: String
/// }
/// ```
/// Expands to:
/// ```xml
/// <Message sender="Alice">Hello, Bob!</Message>
/// ```
///
/// **Invalid Usage: Multiple `@TextContent`**
/// ```swift
/// struct Invalid {
///     @TextContent var text1: String
///     @TextContent var text2: String // ❌ Error: Only one `@TextContent` is allowed.
/// }
/// ```
///
/// - SeeAlso: `@Element`, `@Attribute`
/// 
@attached(peer)
public macro TextContent() = #externalMacro(module: "NodalMacros", type: "MarkerMacro")
