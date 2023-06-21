import Foundation

func zip<FirstElement, SecondElement, each Element>(
    _ firstOperation: @Sendable @escaping () async throws -> FirstElement,
    _ secondOperation: @Sendable @escaping () async throws -> SecondElement,
    _ operation: repeat @Sendable @escaping () async throws -> (each Element)) async throws -> (FirstElement, SecondElement, repeat each Element)
{
    async let firstOperation = try firstOperation()
    async let secondOperation = try secondOperation()
    
    return (
        try await firstOperation,
        try await secondOperation,
        try await repeat task(each operation)
    )
}

protocol ElementIDProtocol {
    associatedtype ID
    associatedtype Value
    
    var id: ID { get }
    var valueType: Value.Type { get }
}

struct ElementID<Value> {
    let id = UUID()
    let valueType: Value.Type
}

private func task<each Element>(
    _ operation: repeat @Sendable @escaping () async throws -> (each Element)) async throws -> (repeat each Element)
{
    var storage: [(() async throws -> Any)] = []
    func makeTask<T>(_ operation: @Sendable @escaping () async throws -> T) {
        let task = Task(operation: operation)
        storage.append({ try await task.value })
    }
    
    _ = (repeat makeTask(each operation))
    
//    print("[task] storage size \(storage.count)") // appears that storage would never be more than 1
//    
//    return try await (repeat unwrapElement(each operation, storage: storage))
    
    let storageTwo = storage
    // seems like Swift compiler does not like this part
    return try await Task { try await (repeat unwrapElement(each operation, storage: storageTwo)) }.value
}

func unwrapElement<each Element>(
    _ operation: repeat @Sendable @escaping () async throws -> (each Element),
    storage: [(() async throws -> Any)]) async throws -> (repeat each Element)
{
    print("[unwrap] storage size: \(storage.count)")
    
    var index: Int = 0
    func unwrap<T>(_ operation: @Sendable @escaping () async throws -> T) async throws -> T {
        print("[unwrap] Index \(index)")
        defer { index += 1 }
        return (try await storage[index]()) as! T
    }
    
    return try await (repeat unwrap(each operation))
}
