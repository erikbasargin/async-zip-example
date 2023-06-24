# Async Zip Example

Implementation of a `zip` function which accept asynchronous functions as variadic parameters (parameter packs).

```swift
// func zip<FirstElement, SecondElement, each Element>(
//     _ firstOperation: @escaping () async throws -> FirstElement,
//     _ secondOperation: @escaping () async throws -> SecondElement,
//     _ operation: repeat @escaping () async throws -> (each Element)
// ) async throws -> (FirstElement, SecondElement, repeat each Element)

let result = try await zip(
    { try await emit((), after: 1) },
    { try await emit("some string value", after: 0.5) },
    { try await emit(1, after: 1.5) })

// result is (Void, String, Int)
// result equal ((), "some string value", 1)

let result = try await zip(
    { try await emit((), after: 1) },
    { try await throwing(TestError(), after: 0.5) },
    { try await emit(1, after: 1.5) })

// throws `TestError` after 0.5s and other tasks are canceled 

// ---

struct TestError: Error {}

@Sendable
func emit<T>(_ value: T, after seconds: TimeInterval) async throws -> T {
    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    return value
}

@Sendable
func throwing(_ error: Error, after seconds: TimeInterval) async throws {
    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    throw error
}
```