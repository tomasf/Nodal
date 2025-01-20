import Foundation

// A table with opaque pointers as keys and strong or weakly referenced objects as values
internal class PointerToObjectMap<ObjectType: AnyObject> {
    private let table: NSMapTable<AnyObject, AnyObject>

    init(strength: ReferenceStrength) {
        table = NSMapTable<AnyObject, AnyObject>(
            keyOptions: [.opaqueMemory, .opaquePersonality],
            valueOptions: strength == .weak ? .weakMemory : .strongMemory
        )
    }

    subscript(key: OpaquePointer) -> ObjectType? {
        get {
            guard let pointer = NSMapGet(table, UnsafeRawPointer(key)) else {
                return nil
            }
            return Unmanaged<ObjectType>.fromOpaque(pointer).takeUnretainedValue()
        }
        set {
            if let newValue {
                NSMapInsert(table, UnsafeRawPointer(key), UnsafeRawPointer(Unmanaged.passUnretained(newValue).toOpaque()))
            } else {
                NSMapRemove(table, UnsafeRawPointer(key))
            }
        }
    }

    func removeObjects<S: Sequence>(forKeys keys: S) where S.Element == OpaquePointer {
        for key in keys { self[key] = nil }
    }

    var contents: [(key: OpaquePointer, value: ObjectType)] {
        var enumerator = NSEnumerateMapTable(table)
        var contents: [(OpaquePointer, ObjectType)] = []
        var key: UnsafeMutableRawPointer?
        var value: UnsafeMutableRawPointer?

        while NSNextMapEnumeratorPair(&enumerator, &key, &value) {
            guard let key, let value else { continue }
            let object = Unmanaged<ObjectType>.fromOpaque(value).takeUnretainedValue()
            contents.append((OpaquePointer(key), object))
        }

        return contents
    }

    var count: Int {
        NSCountMapTable(table)
    }

    public enum ReferenceStrength {
        case strong
        case weak
    }
}
