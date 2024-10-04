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

```yaml
MyOpenOneOf:
  anyOf:
    - oneOf:
        - #/components/schemas/Foo
        - #/components/schemas/Bar
        - #/components/schemas/Baz
    - type: object
```

### Event streams: JSON Lines, JSON Sequence, and Server-sent Events

While [JSON Lines](https://jsonlines.org), [JSON Sequence](https://datatracker.ietf.org/doc/html/rfc7464), and [Server-sent Events](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events) are not explicitly part of the OpenAPI 3.0 or 3.1 specification, you can document an operation that returns events and also the event payloads themselves.

> Tip: Check out the `event-streams-*` client and server example packages in <doc:Checking-out-an-example-project>.

Each event stream format has one or more commonly associated content types with it:
- JSON Lines: `application/jsonl`, `application/x-ndjson`, others.
- JSON Sequence: `application/json-seq`.
- Server-sent Events: `text/event-stream`.

In the OpenAPI document, an example of an operation that returns JSON Lines could look like (analogous for the other formats):

```yaml
paths:
  /events:
    get:
      operationId: getEvents
      responses:
        '200':
          content:
            application/jsonl: {}
components:
  schemas:
    MyEvent:
      type: object
      properties:
        ...
```

The returned binary body contains the raw events, and the stream can be split up into events by using extensions on `AsyncSequence` of `ArraySlice<UInt8>` elements provided in the runtime library:

- JSON Lines
    - decode: `AsyncSequence<ArraySlice<UInt8>>.asDecodedJSONLines(of:decoder:)`
    - encode: `AsyncSequence<some Encodable>.asEncodedJSONLines(encoder:)`
- JSON Sequence
    - decode: `AsyncSequence<ArraySlice<UInt8>>.asDecodedJSONSequence(of:decoder:)`
    - encode: `AsyncSequence<some Encodable>.asEncodedJSONSequence(encoder:)`
- Server-sent Events
    - decode (if data is JSON): `AsyncSequence<ArraySlice<UInt8>>.asDecodedServerSentEventsWithJSONData(of:decoder:)`
    - decode (if data is JSON with a non-JSON terminating byte sequence): `AsyncSequence<ArraySlice<UInt8>>.asDecodedServerSentEventsWithJSONData(of:decoder:while:)`
    - encode (if data is JSON): `AsyncSequence<some Encodable>.asEncodedServerSentEventsWithJSONData(encoder:)`
    - decode (for other data): `AsyncSequence<ArraySlice<UInt8>>.asDecodedServerSentEvents(while:)`
    - encode (for other data): `AsyncSequence<some Encodable>.asEncodedServerSentEvents()`

See the `event-streams-*` client and server examples in <doc:Checking-out-an-example-project> to learn how to produce and consume these sequences.
