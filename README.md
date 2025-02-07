# Nodal

Nodal is a Swift library for working with XML documents using DOM-like trees. It provides tools for parsing XML into a tree structure, manipulating the tree, and generating XML from the tree. The library is lightweight, efficient, and compatible with Linux, Windows and all Apple platforms.

Nodal is based on [pugixml](https://github.com/zeux/pugixml) and adds a convenient Swift layer as well as support for XML namespaces. The entire public API has DocC documentation.

[![Swift](https://github.com/tomasf/Nodal/actions/workflows/swift.yml/badge.svg)](https://github.com/tomasf/Nodal/actions/workflows/swift.yml) ![Platforms](https://img.shields.io/badge/Platforms-macOS_%7C_iOS_%7C_tvOS_%7C_watchOS_%7C_visionOS_%7C_Linux_%7C_Windows-47D?logo=swift&logoColor=white)

## Installation

Add Nodal as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tomasf/Nodal.git", .upToNextMinor(from: "0.2.0"))
]
```

Then, include Nodal in the target dependencies and make sure to enable C++ interoperability:

```swift
.target(
    name: "YourTargetName",
    dependencies: ["Nodal"],
    swiftSettings: [.interoperabilityMode(.Cxx)] // Nodal requires C++ interop
)
```

## Usage

```swift
let document = Document()
let root = document.makeDocumentElement(name: "content", defaultNamespace: "http://tomasf.se/xml/example")
let entry = root.addElement("entry")
entry[attribute: "key"] = "price"
entry.appendText("499")
let output = try document.xmlData()
```

## Nodes

Nodal represents an XML document as a DOM (Document Object Model), which is a tree of nodes. Each node in the tree represents an element, text, comment, or other structural component of the XML document.

Nodes are tightly bound to the tree they belong to. Nodes cannot exist outside of a document; you cannot create a freestanding node and later add it. Instead, you create new nodes directly as children of an existing parent node.  When a node is removed, it is immediately invalidated and cannot be reused or re-added elsewhere. Nodes can, however, be moved to a new position within the same document.

Unlike elements, attributes in Nodal are not represented as nodes. Instead, attributes are accessed and manipulated directly on elements. You retrieve and set the value of attributes by their names (qualified or expanded).

## Namespaces

Nodal has support for namespaces for elements and attributes. This means you can assign expanded names (namespace URI + local name) to them and the corresponding qualified name will be set for you.

```swift
element.addElement("weight", namespace: "http://tomasf.se/xml/example")
```

This presumes the namespace has been declared and assigned a prefix in that element or one of its ancestors. If not, Nodal will use a temporary qualified name and fill the final one in once you’ve declared the namespace. Attempting to generate XML for a document with unresolved namespaces throws an error.

```swift
root.declareNamespace("http://tomasf.se/xml/example", forPrefix: "ex")
```

If you prefer to work without namespaces, that will work just fine, too.

## XPath

XPath is a language for querying and selecting nodes from an XML document. It allows you to write expressions to locate elements and attributes efficiently.

### Example Usage
```swift
let document = try Document(string: """
<catalog>
  <book id="bk101">
    <title>XML Developer's Guide</title>
  </book>
  <book id="bk102">
    <title>Midnight Rain</title>
  </book>
</catalog>
""")

if let name = query.firstNodeResult(with: document)?.node?.textContent {
    print("Book name:", name) // Outputs "XML Developer's Guide"
}
```

While Nodal supports XML namespaces when working with the DOM, its XPath implementation does not support namespaces. This limitation arises from pugixml. To work with elements and attributes in documents that use namespaces, you must use their qualified names in your XPath expressions.

## Contributions

Contributions are welcome! If you have ideas, suggestions, or improvements, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License, and so is pugixml. See the respective LICENSE files for details.
