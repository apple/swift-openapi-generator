# Useful OpenAPI patterns

Explore OpenAPI patterns for common data representations. 

## Overview

This document lists some common OpenAPI patterns that have been tested to work well with Swift OpenAPI Generator.

### Open enums and oneOfs

While `enum` and `oneOf` are closed by default in OpenAPI, meaning that decoding fails if an unknown value is encountered, it can be a good practice to instead use open enums and oneOfs in your API, as it allows adding new cases over time without having to roll a new API-breaking version.

#### Enums

A simple enum looks like:

```yaml
type: string
enum:
  - foo
  - bar
  - baz
```

To create an open enum, in other words an enum that has a "default" value that doesn't fail during decoding, but instead preserves the unknown value, wrap the enum in an `anyOf` and add a string schema as the second subschema.

```yaml
anyOf:
  - type: string
    enum:
      - foo
      - bar
      - baz
  - type: string
```

When accessing this data on the generated Swift code, first check if the first value (closed enum) is non-nil – if so, one of the known enum values were provided. If the enum value is nil, the second string value will contain the raw value that was provided, which you can log or pass through your program.

#### oneOfs

A simple oneOf looks like:

```yaml
oneOf:
  - #/components/schemas/Foo
  - #/components/schemas/Bar
  - #/components/schemas/Baz
```

To create an open oneOf, wrap it in an `anyOf`, and provide a fragment as the second schema, or a more constrained container if you know that the payload will always follow a certain structure.

```yaml
MyOpenOneOf:
  anyOf:
    - oneOf:
        - #/components/schemas/Foo
        - #/components/schemas/Bar
        - #/components/schemas/Baz
    - {}
```

The above is the most flexible, any JSON payload that doesn't match any of the cases in oneOf will be saved into the second schema.

If you know the payload is, for example, always a JSON object, you can constrain the second schema further, like this:

```
MyOpenOneOf:
  anyOf:
    - oneOf:
        - #/components/schemas/Foo
        - #/components/schemas/Bar
        - #/components/schemas/Baz
    - type: object
```

### Server-sent Events/EventSource

While [Server-sent Events](https://en.wikipedia.org/wiki/Server-sent_events) are not explicitly part of the OpenAPI 3.0 or 3.1 specification, you can document an operation that returns SSE and also the event payloads themselves.

> Important: Until [async bodies](https://github.com/apple/swift-openapi-generator/issues/9) are supported in Swift OpenAPI Generator are supported, SSE are of limited value, as bodies are fully buffered before being returned to the caller.

In the OpenAPI document, an example of an operation that returns SSE could look like:

```yaml
paths:
  /events:
    get:
      operationId: getEvents
      responses:
        '200':
          content:
            text/event-stream:
              schema:
                type: string
                format: binary
components:
  schemas:
    MyEvent:
      type: object
      properties:
        ...
```

The returned binary body contains the raw events, and the stream can be split up into events by using one of the existing Swift implementations of Server-sent Events (sometimes libraries also use the term EventSource for the client of server-sent events).

If the event themselves are documented using one of the JSON schemas from the OpenAPI document (such as `MyEvent` in the example above), you can use the generated Codable type to easily parse the payload.

```swift
guard case .ok(let okPayload) = try await client.getEvents(.init()) else {
    // handle an unexpected HTTP response code
}
guard case .text_event_hyphen_stream(let rawBody) = okPayload.body else {
    // handle an unexpected content type
}
// ... pass rawBody to an SSE library
let streamOfRawEvents: AsyncSequence<Data> = ... // returned by an SSE library
for try await rawEventData in streamOfRawEvents {
    let event = try JSONDecoder().decode(
        Components.Schemas.MyEvent.self
        from: rawEventData
    )
    // Print the type-safe event here
    print(event)
}
```

This way, with a little bit of manual work, you can still get type safety from an SSE operation being documented in an OpenAPI document.
