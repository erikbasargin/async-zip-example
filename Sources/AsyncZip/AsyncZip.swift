import Foundation

func zip<FirstElement, SecondElement, each Element>(
    _ firstOperation: @Sendable @escaping () async throws -> FirstElement,
    _ secondOperation: @Sendable @escaping () async throws -> SecondElement,
    _ operation: repeat @Sendable @escaping () async throws -> (each Element)) async throws -> (FirstElement, SecondElement, repeat each Element)
{
    let taskStorage = TaskStorage()
    
    taskStorage.push(firstOperation)
    taskStorage.push(secondOperation)
    (repeat taskStorage.push(each operation))
    
    return try await (
        taskStorage.pop(FirstElement.self)!,
        taskStorage.pop(SecondElement.self)!,
        repeat taskStorage.pop((each Element).self)!
    )
}

private final class TaskStorage {
    
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
