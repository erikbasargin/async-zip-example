import Foundation

func zip<FirstElement, SecondElement, each Element>(
    _ firstOperation: @Sendable @escaping () async throws -> FirstElement,
    _ secondOperation: @Sendable @escaping () async throws -> SecondElement,
    _ operation: repeat @Sendable @escaping () async throws -> (each Element)) async throws -> (FirstElement, SecondElement, repeat each Element)
{
    let group = OperationGroup()
    
    group.addOperation(firstOperation)
    group.addOperation(secondOperation)
    (repeat group.addOperation(each operation))
    
    try await group.perform()
    
    return (
        group.retrieve(FirstElement.self)!,
        group.retrieve(SecondElement.self)!,
        repeat group.retrieve((each Element).self)!
    )
}

private final class OperationGroup {
    
    private typealias AnyOperation = @Sendable () async throws -> Any
    
    private var operations: [AnyOperation] = []
    private var results: [(id: Int, value: Any)] = []
    private var index: Int = 0
    
    func addOperation<T>(_ operation: @Sendable @escaping () async throws -> T) {
        operations.append(operation)
    }
    
    func retrieve<T>(_ resultType: T.Type) -> T? {
        defer { index += 1 }
        return results.first(where: { $0.id == index })?.value as? T
    }
    
    func perform() async throws {
        results = try await withThrowingTaskGroup(of: (id: Int, value: Any).self) { group in
            for (id, operation) in operations.enumerated() {
                group.addTask { try await (id, operation()) }
            }
            
            var results: [(id: Int, value: Any)] = []
            
            do {
                for try await result in group {
                    results.append(result)
                }
            } catch {
                group.cancelAll()
                throw error
            }
            
            return results
        }
    }
}
