# Converting between data and Swift types

Learn about the type responsible for convertering between binary data and Swift types.

## Overview

The [`Converter`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter.swift) type is a structure defined in the runtime library and is used by both the client and server generated code to perform conversions between binary data and Swift types.

> Note: `Converter` is one of the SPI types, not considered part of the public API of the runtime library. However, because generated code relies on it, SPI stability needs to be considered when making changes to it and to the generator.

Most of the functionality of `Converter` is implemented as helper methods in extensions:
- [`Converter+Client.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BClient.swift)
- [`Converter+Server.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BServer.swift)
- [`Converter+Common.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BCommon.swift)

Some helper methods can be reused between client and server code, such as headers, but most can't. It's important that we only generalize (move helper methods into common extensions) if the client and server variants would have been exact copies. However, if there are differences, prefer to keep them separate and optimize each variant (for client or server) separately.

### Generated code and generics interaction

As outlined in <doc:Project-scope-and-goals>, we aim to minimize the complexity of the generator and rely on the Swift compiler to help ensure that if generated code compiles, it's likely to work correctly.

To that end, if the input OpenAPI document contains an input that Swift OpenAPI Generator doesn't support, our first preference is to catch it in the generator and emit a descriptive diagnostic. However, there are cases where that is prohibitively complex, and we let the Swift compiler ensure that, for example, an array of strings cannot be used as a path parameter. In this example case, the generator emits code with the path parameter being of Swift type `[String]`, but since there doesn't exist a converter method for it, it will fail to build. This is considered expected behavior.

In the case of the converter, it contains helper methods for all the supported combinations of an schema location, a "coding strategy" and a Swift type.

### Dimensions of helper methods

Below is a list of the "dimensions" across which the helper methods differ:

- **Client/server** represents whether the code is needed by the client, server, or both ("common").
- **Set/get** represents whether the generated code sets or gets the value.
- **Schema location** refers to one of the several places where schemas can be used in OpenAPI documents. Values:
    - request path parameters
    - request query items
    - request header fields
    - request body
    - response header fields
    - response body
- **Coding strategy** represents the chosen encoder/decoder to convert the Swift type to/from data. Values:
    - `JSON`
        - example: `application/json`
        - uses the type's `Codable` implementation and `JSONEncoder`/`JSONDecoder`
    - `text`
        - example: `text/plain`
        - uses the type's `LosslessStringConvertible` implementation, except for `Foundation.Date`, which uses a system date formatter
    - `binary`
        - example: `application/octet-stream`
        - doesn't transform the binary data, just passes it through
        - serves as the fallback for content types that don't have more specific handling
- **Swift type** represents the generated type in Swift that best represents the JSON schema defined in the OpenAPI document. For example, a `string` schema is generated as `Swift.String`, an `object` schema is generated as a Swift structure, and an `array` schema is generated as a `Swift.Array` generic over the element type. For the helper methods, it's important which protocol they conform to, as those are used for serialization. Values:
    - _string-convertible_ refers to types that conform to `LosslessStringConvertible`
    - _array of string-convertibles_ refers to an array of types that conform to `LosslessStringConvertible`
    - _date-time_ is represented by `Foundation.Date`
    - _array of date-times_ refers to an array of `Foundation.Date`
    - _codable_ refers to types that conform to `Codable`
    - _data_ is represented by `Foundation.Data`
- **Optional/required** represents whether the method works with optional values. Values:
    - _required_ represents a special overload only for required values
    - _optional_ represents a special overload only for optional values
    - _both_ represents a special overload that works for optional values without negatively impacting passed-in required values (for example, setters)

### Helper method variants

Together, the dimensions are enough to deterministically decide which helper method on the converter should be used.

In the list below, each row represents one helper method.

The helper method naming convention can be described as:

```
method name: {set,get}{required/optional/omit if both}{location}As{strategy}
method parameters: value or type of value
```

| Client/server | Set/get | Schema location | Coding strategy | Swift type | Optional/required | Method name |
| --------------| ------- | --------------- | --------------- | ---------- | ------------------| ----------- |
| common | set | header field | text | string-convertible | both | setHeaderFieldAsText |
| common | set | header field | text | array of string-convertibles | both | setHeaderFieldAsText |
| common | set | header field | text | date | both | setHeaderFieldAsText |
| common | set | header field | text | array of dates | both | setHeaderFieldAsText |
| common | set | header field | JSON | codable | both | setHeaderFieldAsJSON |
| common | get | header field | text | string-convertible | optional | getOptionalHeaderFieldAsText |
| common | get | header field | text | string-convertible | required | getRequiredHeaderFieldAsText |
| common | get | header field | text | array of string-convertibles | optional | getOptionalHeaderFieldAsText |
| common | get | header field | text | array of string-convertibles | required | getRequiredHeaderFieldAsText |
| common | get | header field | text | date | optional | getOptionalHeaderFieldAsText |
| common | get | header field | text | date | required | getRequiredHeaderFieldAsText |
| common | get | header field | text | array of dates | optional | getOptionalHeaderFieldAsText |
| common | get | header field | text | array of dates | required | getRequiredHeaderFieldAsText |
| common | get | header field | JSON | codable | optional | getOptionalHeaderFieldAsJSON |
| common | get | header field | JSON | codable | required | getRequiredHeaderFieldAsJSON |
| client | set | request path | text | string-convertible | required | renderedRequestPath |
| client | set | request query | text | string-convertible | both | setQueryItemAsText |
| client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
| client | set | request query | text | date | both | setQueryItemAsText |
| client | set | request query | text | array of dates | both | setQueryItemAsText |
| client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
| client | set | request body | text | string-convertible | required | setRequiredRequestBodyAsText |
| client | set | request body | text | date | optional | setOptionalRequestBodyAsText |
| client | set | request body | text | date | required | setRequiredRequestBodyAsText |
| client | set | request body | JSON | codable | optional | setOptionalRequestBodyAsJSON |
| client | set | request body | JSON | codable | required | setRequiredRequestBodyAsJSON |
| client | set | request body | binary | data | optional | setOptionalRequestBodyAsBinary |
| client | set | request body | binary | data | required | setRequiredRequestBodyAsBinary |
| client | get | response body | text | string-convertible | required | getResponseBodyAsText |
| client | get | response body | text | date | required | getResponseBodyAsText |
| client | get | response body | JSON | codable | required | getResponseBodyAsJSON |
| client | get | response body | binary | data | required | getResponseBodyAsBinary |
| server | get | request path | text | string-convertible | required | getPathParameterAsText |
| server | get | request query | text | string-convertible | optional | getOptionalQueryItemAsText |
| server | get | request query | text | string-convertible | required | getRequiredQueryItemAsText |
| server | get | request query | text | array of string-convertibles | optional | getOptionalQueryItemAsText |
| server | get | request query | text | array of string-convertibles | required | getRequiredQueryItemAsText |
| server | get | request query | text | date | optional | getOptionalQueryItemAsText |
| server | get | request query | text | date | required | getRequiredQueryItemAsText |
| server | get | request query | text | array of dates | optional | getOptionalQueryItemAsText |
| server | get | request query | text | array of dates | required | getRequiredQueryItemAsText |
| server | get | request body | text | string-convertible | optional | getOptionalRequestBodyAsText |
| server | get | request body | text | string-convertible | required | getRequiredRequestBodyAsText |
| server | get | request body | text | date | optional | getOptionalRequestBodyAsText |
| server | get | request body | text | date | required | getRequiredRequestBodyAsText |
| server | get | request body | JSON | codable | optional | getOptionalRequestBodyAsJSON |
| server | get | request body | JSON | codable | required | getRequiredRequestBodyAsJSON |
| server | get | request body | binary | data | optional | getOptionalRequestBodyAsBinary |
| server | get | request body | binary | data | required | getRequiredRequestBodyAsBinary |
| server | set | response body | text | string-convertible | required | setResponseBodyAsText |
| server | set | response body | text | date | required | setResponseBodyAsText |
| server | set | response body | JSON | codable | required | setResponseBodyAsJSON |
| server | set | response body | binary | data | required | setResponseBodyAsBinary |
