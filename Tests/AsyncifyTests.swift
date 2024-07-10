@testable import Asyncify
import Foundation
import Testing

// Test successful async operation
@Test func asyncOperationSuccess() async throws {
  let asyncify = Asyncify<String>()
  let expectedResult = "Success result"
        
  let result = try await asyncify.performOperation { completion in
    // Simulate asynchronous operation success
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      completion(.success(expectedResult))
    }
  }
        
  #expect(result == expectedResult, "The result should be equal to the expected result.")
}

// Test failed async operation
@Test func asyncOperationFailure() async throws {
  let asyncify = Asyncify<String>()
  let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
        
  do {
    _ = try await asyncify.performOperation { completion in
      // Simulate asynchronous operation failure
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion(.failure(expectedError))
      }
    }
    Issue.record("The operation should have failed.")
  } catch {
    #expect(error as NSError == expectedError, "The error should be equal to the expected error.")
  }
}

// Test multiple callers receive the same success result
@Test func multipleCallersSuccess() async throws {
  let asyncify = Asyncify<String>()
  let expectedResult = "Shared success result"
        
  async let firstCallerResult: String = asyncify.performOperation { completion in
    // Simulate asynchronous operation success for multiple callers
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      completion(.success(expectedResult))
    }
  }
        
  async let secondCallerResult: String = asyncify.performOperation { _ in }
        
  let results = try await [firstCallerResult, secondCallerResult]
  for result in results {
    #expect(result == expectedResult, "Each caller should receive the same success result.")
  }
}

// Test multiple callers with one operation failing
@Test func multipleCallersOneFails() async throws {
  let asyncify = Asyncify<String>()
  let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
      
  let firstCallerTask = Task { () -> Result<String, Error> in
    do {
      let result = try await asyncify.performOperation { completion in
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
      let result = try await asyncify.performOperation { _ in }
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
      Issue.record("The operation should not succeed.")
    case .failure(let receivedError as NSError):
      #expect(receivedError == expectedError, "Each caller should receive the same failure.")
    }
  }
}

// Test concurrency with multiple simultaneous operations
@Test func concurrencyWithSimultaneousOperations() async throws {
  let asyncify = Asyncify<Int>()
  let operationCount = 100 // Number of concurrent operations
  let expectedResult = 42 // Arbitrary expected result for this test
        
  // Create an array of tasks, each performing an operation
  let tasks = (1 ... operationCount).map { i in
    Task<Int, Error> {
      try await asyncify.performOperation { completion in
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
  #expect(results.count == operationCount, "All operations should complete.")
  for result in results {
    #expect(result == expectedResult, "Each result should match the expected result.")
  }
}

// Test immediate success operation
@Test func immediateSuccessOperation() async throws {
  let asyncify = Asyncify<String>()
  let expectedResult = "Immediate success result"
      
  let result = try await asyncify.performOperation { completion in
    // Immediately complete the operation
    completion(.success(expectedResult))
  }
      
  #expect(result == expectedResult, "The result should be equal to the expected result.")
}

// Test immediate failure operation
@Test func immediateFailureOperation() async throws {
  let asyncify = Asyncify<String>()
  let expectedError = NSError(domain: "ImmediateTestError", code: 2, userInfo: nil)
      
  do {
    _ = try await asyncify.performOperation { completion in
      // Immediately complete the operation with failure
      completion(.failure(expectedError))
    }
    Issue.record("The operation should have failed.")
  } catch {
    #expect(error as NSError == expectedError, "The error should be equal to the expected error.")
  }
}

// Test re-entrancy
@Test func reentrancyTest() async throws {
  let asyncify = Asyncify<String>()
  let expectedResult = "Re-entrancy result"
      
  let result = try await asyncify.performOperation { completion in
    // Simulate asynchronous operation success
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      completion(.success(expectedResult))
              
      // Call performOperation again within the same operation
      Task {
        do {
          let reentrantResult = try await asyncify.performOperation { reentrantCompletion in
            reentrantCompletion(.success("Re-entrant success"))
          }
          #expect(reentrantResult == "Re-entrant success", "The re-entrant result should be successful.")
        } catch {
          Issue.record("Re-entrant operation should not fail.")
        }
      }
    }
  }
      
  #expect(result == expectedResult, "The result should be equal to the expected result.")
}
