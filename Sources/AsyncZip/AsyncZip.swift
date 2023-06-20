import Foundation

// FB12383213: SwiftCompile crashes when using parameter packs
func zip<FirstElement, SecondElement, each Element>(
    _ firstOperation: @Sendable @escaping () async throws -> FirstElement,
    _ secondOperation: @Sendable @escaping () async throws -> SecondElement,
    _ operation: repeat @Sendable @escaping () async throws -> (each Element)) async throws -> (FirstElement, SecondElement, repeat each Element)
{
    async let results = (firstOperation(), secondOperation(), repeat (each operation)())
    
    return try await results
}
