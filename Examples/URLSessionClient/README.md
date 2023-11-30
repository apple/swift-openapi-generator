# URLSession Client

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Overview

A command-line tool that uses a generated client with the [URLSession transport](https://github.com/apple/swift-openapi-urlsession) make requests to the Greeting Service running on `http://localhost:8080`. 

The CLI makes two requests to the Greeting Service, printing the returned greetings.

## Usage

Build and run the CLI using:

```
swift run
```

## Testing

Run tests using:

```
swift test
```

The testing strategy is to implement a mock service called `MockGreetingService`, which returns a greeting with the prefix `(mock)`.

Then the `MockGreetingService` can be injected into your business logic that expects a real client, conforming to `APIProtocol`.

To allow injecting a custom client, make sure your business logic expects an `any APIProtocol` or `some APIProtocol` rather than the concrete type `Client`.

For example, write your business logic like this:

✅
```swift
func processGreeting(client: some APIProtocol) async throws {
    // ...
}
```

instead of this:

❌
```swift
func processGreeting(client: Client) async throws {
    // ...
}
```

As the first variant allows injecting a mock client, but the second doesn't.
