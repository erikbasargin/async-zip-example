import XCTest
@testable import AsyncZip

struct TestErrorOne: Error {}
struct TestErrorTwo: Error {}

final class AsyncZipTests: XCTestCase {
    
    func testZip() async throws {
        let start = CFAbsoluteTimeGetCurrent()
        
        let result = try await zip(
            Result.resume(with: 1, after: 1),
            Result.resume(with: "2", after: 2),
            Result.resume(with: true, after: 1.5),
            Result.resume(with: false, after: 1),
            Result.resume(with: Int?(nil), after: 1))
        
        // not ideal but can help to verify if tasks are run in parallel
        let time = floor(CFAbsoluteTimeGetCurrent() - start)
        
        XCTAssertEqual(time, 2)
        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, "2")
        XCTAssertEqual(result.2, true)
        XCTAssertEqual(result.3, false)
        XCTAssertEqual(result.4, nil)
    }
    
    func testZipThrowsFirstAppearedErrorAndCancelsRemainingTasks() async throws {
        let remainingTasksCanceled = expectation(description: "Remaining Tasks canceled")
        remainingTasksCanceled.expectedFulfillmentCount = 2
        let tasksNeverCanceled = expectation(description: "Other Tasks never canceled")
        tasksNeverCanceled.isInverted = true
        
        let start = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await zip(
                Result.throwing(TestErrorOne(), after: 1, onCancel: tasksNeverCanceled.fulfill),
                Result.resume(with: "2", after: 2, onCancel: remainingTasksCanceled.fulfill),
                Result.throwing(TestErrorTwo(), after: 1.5, onCancel: remainingTasksCanceled.fulfill),
                Result.resume(with: true, after: 0.5, onCancel: tasksNeverCanceled.fulfill))
        } catch {
            switch error {
            case is TestErrorOne:
                let time = floor(CFAbsoluteTimeGetCurrent() - start)
                XCTAssertEqual(time, 1)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        await fulfillment(of: [remainingTasksCanceled, tasksNeverCanceled], timeout: 1)
    }
}

private extension Result where Failure == Never {
    
    @Sendable
    static func resume(
        with value: Success,
        after seconds: TimeInterval,
        onCancel: (() -> Void)? = nil) -> (@Sendable () async throws -> Success)
    {
        Self.success(value).resumeAfter(seconds, onCancel: onCancel)
    }
}

private extension Result where Success == Never {
    
    @Sendable
    static func throwing(
        _ error: Failure,
        after seconds: TimeInterval,
        onCancel: (() -> Void)? = nil) -> (@Sendable () async throws -> Success)
    {
        Self.failure(error).resumeAfter(seconds, onCancel: onCancel)
    }
}

private extension Result {
    
    @Sendable
    func resumeAfter(_ seconds: TimeInterval, onCancel: (() -> Void)? = nil) -> (@Sendable () async throws -> Success) {
        {
            print("> [\(log: Date())] Task '\(UUID())' is started")
            do {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                try Task.checkCancellation()
                return try get()
            } catch is CancellationError {
                onCancel?()
                throw CancellationError()
            } catch {
                throw error
            }
        }
    }
}

private extension String.StringInterpolation {
    
    mutating func appendInterpolation(log value: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSSSS"
        
        let dateString = formatter.string(from: value)
        appendLiteral(dateString)
    }
}
