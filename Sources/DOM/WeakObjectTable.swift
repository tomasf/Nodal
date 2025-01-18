import Foundation

// A table with opaque pointers as keys and weakly referenced objects as values
internal class WeakObjectTable<ObjectType: AnyObject> {
    private var table = NSMapTable<AnyObject, AnyObject>(
        keyOptions: [.opaqueMemory, .opaquePersonality], valueOptions: .weakMemory
    )

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
}
