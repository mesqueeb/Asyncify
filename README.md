# Asyncify 🔄

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FAsyncify%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mesqueeb/Asyncify)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FAsyncify%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mesqueeb/Asyncify)

```
.package(url: "https://github.com/mesqueeb/Asyncify", from: "0.0.9")
```

`Asyncify` is a utility class designed to convert callback-based asynchronous methods into Swift's `async/await` pattern.

This class is useful for adapting existing asynchronous code that uses callback functions / completion handlers to the newer `async/await` syntax in Swift, simplifying concurrency management in your codebase.

## Usage

Suppose you have a function that performs an asynchronous operation using a completion handler to deliver its result.
You can use `Asyncify` to wrap this function and call it using Swift's `async/await` syntax.

Example:

```swift
// Example asynchronous function using a completion handler
func fetchUserDataWithHandler(completion: @escaping (Result<UserData, Error>) -> Void) {
    // ... your function implementation
}

// Set up an instance of Asyncify to use in the new async function
let asyncify = Asyncify<UserData>()

// Create a new async function using the `asyncify` instance
func fetchUserData() async throws -> UserData {
    try await asyncify.performOperation { completion in
        fetchUserDataWithHandler(completion: completion)
    }
}

// Usage
Task {
    do {
        let userData = try await fetchUserData()
        print("Fetched user data: \(userData)")
    } catch {
        print("Failed to fetch user data: \(error)")
    }
}
```

This example demonstrates how `Asyncify` can be used to adapt a traditional callback-based function (`fetchUserData`)
into a modern `async/await` pattern (`getUserDataAsync`), making it easier to use within Swift's concurrency model.

## Documentation

See the [documentation](https://swiftpackageindex.com/mesqueeb/asyncify/main/documentation/asyncify/asyncify) for more info.
