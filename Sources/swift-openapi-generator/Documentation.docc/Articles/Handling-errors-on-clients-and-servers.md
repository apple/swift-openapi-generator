# Handling errors on clients and servers

Learn about the default error-handling behavior and how to customize it.

## Overview

Generated clients and servers have a default error-handling behavior, which you can change using several customization points.

### Understand the default error-handling behavior

Generated **`Client`** structs throw an error from any of the generated operation methods when:
- the request fails to serialize
- any middleware throws an error
- the transport throws an error
- the response fails to deserialize

The thrown error type is always an instance of [`ClientError`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clienterror), which holds additional context about the request, useful for debugging. The error also contains the properties [`causeDescription`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clienterror/causedescription), providing a human-readable high level category of the error, and [`underlyingError`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clienterror/underlyingError), the original error. If an error is thrown in a middleware or the transport, it gets provided in the `underlyingError` property.

> Tip: The extra context provided by `ClientError` helps with debugging a failed request, especially when the error is caught higher up the stack after multiple calls to `Client` occurred in the same scope.

Similarly on the server, the **`registerHandlers`** method throws an error up to the middleware/transport chain when:
- the request fails to deserialize
- any middleware throws an error
- the user handler throws an error
- the response fails to serialize

The thrown error type is always an instance of [`ServerError`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/servererror), which holds additional context about the request, useful for debugging. The error also contains the properties [`causeDescription`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/servererror/causedescription), providing a human-readable high level category of the error, and [`underlyingError`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/servererror/underlyingError), the original error. If an error is thrown in a middleware or the handler, it gets provided in the `underlyingError` property.

### Customize the thrown error using an error mapper

In situations when your existing code inspects the thrown error beyond just logging it, you might need to customize the thrown error, or completely discard the `ClientError`/`ServerError` context, and only propagate the original `underlyingError`.

To customize the client error-throwing behavior, provide the `clientErrorMapper` closure when instantiating your `Configuration`:

```swift
let client = Client(
    serverURL: try Servers.server1.url(),
    configuration: .init(clientErrorMapper: { clientError in
        // Always throw the underlying error, discard the extra context
        clientError.underlyingError
    }),
    transport: transport
)

do {
    let response = try await client.greet() // throws an error
} catch {
    print(error) // this error is now the underlyingError, rather than ClientError
}
```

On the server, provide the customized `Configuration` to the `registerHandlers` call:

```swift
try myHandler.registerHandlers(
    on: transport,
    configuration: .init(
        serverErrorMapper: { serverError in
            // Always throw the underlying error, discard the extra context
            serverError.underlyingError
        }
    )
)
```

This error customization point can also be used for collecting telemetry about the types of errors thrown, by emitting the metric and returning the unmodified error from the closure.

### Convert errors into specific HTTP response status codes

When implementing a server, it can be useful to reuse the same utility code from multiple type-safe handler methods, and map certain errors to specific HTTP response status codes.

> Warning: Use this customization point with care by ensuring that you only map errors to the HTTP response status codes allowed by your OpenAPI document.

Consider an example where your server calls an upstream service that has limited capacity, and some of those calls fail when the service is overloaded. Your service would want to return the HTTP status code 429 to instruct the client to retry later.

Define an error type that represents such an error:

```swift
struct UpstreamServiceOverloaded: Error {}
```

And conform it to the [`HTTPResponseConvertible`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/httpresponseconvertible) protocol, by returning the `.tooManyRequests` (429) status and a `retry-after` HTTP header field asking the client to try again in 15 seconds.

```swift
extension UpstreamServiceOverloaded: HTTPResponseConvertible {
    var httpStatus: HTTPResponse.Status {
        .tooManyRequests
    }

    var httpHeaderFields: HTTPTypes.HTTPFields {
        [.retryAfter: "15"]
    }
}
```

Finally, for this error to get converted into an HTTP response whenever it's thrown in any user handler or middleware, add the [`ErrorHandlingMiddleware`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/errorhandlingmiddleware) to the middlewares array when calling `registerHandlers`:

```swift
try myHandler.registerHandlers(
    on: transport,
    middlewares: [
        ErrorHandlingMiddleware()
    ]
)
```

> Note: When the response (for example, the 429 from above) is documented in the OpenAPI document, it is still preferable to return it explicitly from your type-safe handler, making it easier to ensure you only return documented responses. However, this customization point exists for cases where propagating the error through the handler is impractical or overly repetitive.
