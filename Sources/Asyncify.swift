import Foundation

/// `Asyncify` is a utility class designed to convert callback-based asynchronous methods into Swift's `async/await` pattern.
/// This class is useful for adapting existing asynchronous code that uses completion handlers to the newer `async/await` syntax in Swift,
/// simplifying concurrency management in your codebase.
///
/// Usage Example for a Swift Function:
/// Suppose you have a function that performs an asynchronous operation using a completion handler to deliver its result.
/// You can use `Asyncify` to wrap this function and call it using Swift's `async/await` syntax.
///
/// Example:
///
/// ```swift
/// // Example asynchronous function using a completion handler
/// func fetchUserDataWithHandler(completion: @escaping (Result<UserData, Error>) -> Void) {
///     // ... your function implementation
/// }
///
/// // Set up an instance of Asyncify to use in the new async function
/// let asyncify = Asyncify<UserData>()
/// 
/// // Create a new async function using the `asyncify` instance
/// func fetchUserData() async throws -> UserData {
///     try await asyncify.performOperation { completion in
///         fetchUserDataWithHandler(completion: completion)
///     }
/// }
///
/// // Usage of your newly created async function:
/// Task {
///     do {
///         let userData = try await fetchUserData()
///         print("Fetched user data: \(userData)")
///     } catch {
///         print("Failed to fetch user data: \(error)")
///     }
/// }
/// ```
///
/// This example demonstrates how `Asyncify` can be used to adapt a traditional callback-based function (`fetchUserData`)
/// into a modern `async/await` pattern (`getUserDataAsync`), making it easier to use within Swift's concurrency model.
public actor Asyncify<ResultType: Sendable> {
  private var continuation: CheckedContinuation<ResultType, Error>?
  private var subscribers: [(Result<ResultType, Error>) -> Void] = []
  private var isOperationInProgress = false

  public init() {}

  public func performOperation(operation: @Sendable @escaping (@Sendable @escaping (Result<ResultType, Error>) -> Void) -> Void) async throws -> ResultType {
    if isOperationInProgress {
      // Add subscriber and wait for result
      return try await withCheckedThrowingContinuation { continuation in
        addSubscriber { result in
          continuation.resume(with: result)
        }
      }
    } else {
      isOperationInProgress = true
      return try await withCheckedThrowingContinuation { [self] continuation in
        self.continuation = continuation
        operation { result in
          Task { await self.completeOperation(with: result) }
        }
      }
    }
  }

  private func addSubscriber(_ subscriber: @escaping (Result<ResultType, Error>) -> Void) {
    subscribers.append(subscriber)
  }

  private func completeOperation(with result: Result<ResultType, Error>) {
    continuation?.resume(with: result)
    subscribers.forEach { $0(result) }
    reset()
  }

  private func reset() {
    continuation = nil
    subscribers.removeAll()
    isOperationInProgress = false
  }
}
