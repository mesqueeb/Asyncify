@testable import Asyncify
import XCTest

final class AsyncifyTests: XCTestCase {
  // Test successful async operation
  func testAsyncOperationSuccess() async throws {
    let converter = Asyncify<String>()
    let expectedResult = "Success result"
        
    let result = try await converter.performOperation { completion in
      // Simulate asynchronous operation success
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion(.success(expectedResult))
      }
    }
        
    XCTAssertEqual(result, expectedResult, "The result should be equal to the expected result.")
  }

  // Test failed async operation
  func testAsyncOperationFailure() async {
    let converter = Asyncify<String>()
    let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
        
    do {
      _ = try await converter.performOperation { completion in
        // Simulate asynchronous operation failure
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          completion(.failure(expectedError))
        }
      }
      XCTFail("The operation should have failed.")
    } catch {
      XCTAssertEqual(error as NSError, expectedError, "The error should be equal to the expected error.")
    }
  }

  // Test multiple callers receive the same success result
  func testMultipleCallersSuccess() async throws {
    let converter = Asyncify<String>()
    let expectedResult = "Shared success result"
        
    async let firstCallerResult: String = converter.performOperation { completion in
      // Simulate asynchronous operation success for multiple callers
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion(.success(expectedResult))
      }
    }
        
    async let secondCallerResult: String = converter.performOperation { _ in }
        
    let results = try await [firstCallerResult, secondCallerResult]
    for result in results {
      XCTAssertEqual(result, expectedResult, "Each caller should receive the same success result.")
    }
  }

  // Test multiple callers with one operation failing
  func testMultipleCallersOneFails() async {
    let converter = Asyncify<String>()
    let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
      
    let firstCallerTask = Task { () -> Result<String, Error> in
      do {
        let result = try await converter.performOperation { completion in
          // Simulate operation failure for multiple callers
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(expectedError))
          }
        }
        return .success(result)
      } catch {
        return .failure(error)
      }
    }
      
    let secondCallerTask = Task { () -> Result<String, Error> in
      do {
        let result = try await converter.performOperation { _ in }
        return .success(result)
      } catch {
        return .failure(error)
      }
    }
      
    let firstCallerResult = await firstCallerTask.value
    let secondCallerResult = await secondCallerTask.value
      
    let results = [firstCallerResult, secondCallerResult]
    for result in results {
      switch result {
      case .success:
        XCTFail("The operation should not succeed.")
      case .failure(let receivedError as NSError):
        XCTAssertEqual(receivedError, expectedError, "Each caller should receive the same failure.")
      }
    }
  }
  
  // Test concurrency with multiple simultaneous operations
  func testConcurrencyWithSimultaneousOperations() async throws {
    let converter = Asyncify<Int>()
    let operationCount = 100 // Number of concurrent operations
    let expectedResult = 42 // Arbitrary expected result for this test
        
    // Create an array of tasks, each performing an operation
    let tasks = (1 ... operationCount).map { i in
      Task<Int, Error> {
        try await converter.performOperation { completion in
          // Simulate a slight delay and then complete successfully
          DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(i * 10)) {
            completion(.success(expectedResult))
          }
        }
      }
    }
        
    // Wait for all tasks to complete
    let results = try await withThrowingTaskGroup(of: Int.self) { group in
      for task in tasks {
        group.addTask {
          try await task.value
        }
      }
      return try await group.reduce(into: [Int]()) { $0.append($1) }
    }
        
    // Verify that all results are as expected
    XCTAssertEqual(results.count, operationCount, "All operations should complete.")
    for result in results {
      XCTAssertEqual(result, expectedResult, "Each result should match the expected result.")
    }
  }
}
