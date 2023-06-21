import Foundation

func zip<FirstElement, SecondElement, each Element>(
    _ firstOperation: @Sendable @escaping () async throws -> FirstElement,
    _ secondOperation: @Sendable @escaping () async throws -> SecondElement,
    _ operation: repeat @Sendable @escaping () async throws -> (each Element)) async throws -> (FirstElement, SecondElement, repeat each Element)
{
    let taskStorage = TaskStorage()
    
    // Version 1. Swift Compiler crash: 'Stored value type does not match pointer operand type!'
    // Fixed from Xcode 15 beta 4
    func bind<each T>(
        operation: repeat @Sendable @escaping () async throws -> (each T),
        with storage: TaskStorage) async
    {
        _ = (repeat await storage.push(each operation))
    }
    
    await (repeat bind(operation: each operation, with: taskStorage))
    
    // Version 2. Replace lines 11-18 with the following to see another crash.
    // await Task { [taskStorage] in
    //     _ = (repeat await taskStorage.push(each operation))
    // }.value
    
    async let firstOperation = try firstOperation()
    async let secondOperation = try secondOperation()
    
    return (
        try await firstOperation,
        try await secondOperation,
        repeat try await taskStorage.pop((each Element).self)!
    )
}

private actor TaskStorage {
    
    private var storage: [Task<Any, Error>] = []
    
    func push<T>(_ operation: @Sendable @escaping () async throws -> T) {
        let task = Task(operation: operation) as Task<Any, Error>
        storage = [task] + storage
    }
    
    func pop<T>(_ key: T.Type) async throws -> T? {
        guard let task = storage.popLast() else { return nil }
        return try await task.value as? T
    }
}
