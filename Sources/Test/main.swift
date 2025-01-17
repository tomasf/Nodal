import DOM
import Foundation

let document = Document()

let root = document.makeRootElement(name: "rolf", defaultNamespace: "hajjjj")
root[attribute: "haj"] = "korv"
root.declareNamespace("tjosan", for: "tj")
let bubb = root.appendElement("bubb", uri: "tjosan")
root.appendElement("bubb", uri: "tjosan")

bubb[attribute: "flork"] = "fleerp"
bubb[attribute: "halp", uri: "tjosan"] = "okej"
bubb.appendElement("glork")

root.appendElement("enkel")
root.appendElement("benkel")

let o1 = root[element: "enkel"]
let o2 = root[element: "enkel"]
let o3 = root[element: "benkel"]

print("o1 == o2: ", o1 === o2)
print("o1 == o3: ", o1 === o3)
print("o2 == o3: ", o2 === o3)

root.appendComment("haha naajes")
bubb.document.rootElement?[attribute: "add"] = "added!"
print("Whole document: ", document.xmlString())

print("Match ", root[elements: "bubb", uri: "tjosan"])

print("Bubb: ", bubb.xmlString())

DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
    print("Hello World!")
}

while true {
    autoreleasepool {
        print("pool")
        RunLoop.main.run()
    }
}
