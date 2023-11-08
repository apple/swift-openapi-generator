# Converting between data and Swift types

Learn about the type responsible for converting between binary data and Swift types.

## Overview

The [`Converter`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter.swift) type is a structure defined in the runtime library and is used by both the client and server generated code to perform conversions between binary data and Swift types.

> Note: `Converter` is one of the SPI types, not considered part of the public API of the runtime library. However, because generated code relies on it, SPI stability needs to be considered when making changes to it and to the generator.

Most of the functionality of `Converter` is implemented as helper methods in extensions:
- [`Converter+Client.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BClient.swift)
- [`Converter+Server.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BServer.swift)
- [`Converter+Common.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BCommon.swift)

Some helper methods can be reused between client and server code, such as headers, but most can't. It's important that we only generalize (move helper methods into common extensions) if the client and server variants would have been exact copies. However, if there are differences, prefer to keep them separate and optimize each variant (for client or server) separately.

The converter, it contains helper methods for all the supported combinations of an schema location, a "coding strategy" and a Swift type.

### Codable and coders

The project uses multiple encoder and decoder implementations that all utilize the `Codable` conformance of generated and built-in types.

At the time of writing, the list of coders used is as follows.

| Format | Encoder | Decoder | Supported in |
| ------ | ------- | ------- | ----- |
| JSON | `Foundation.JSONEncoder` | `Foundation.JSONDecoder` | Bodies, headers |
| URI (†) | `OpenAPIRuntime.URIEncoder` | `OpenAPIRuntime.URIDecoder` | Path, query, headers |
| Plain text | `OpenAPIRuntime.StringEncoder` | `OpenAPIRuntime.StringDecoder` | Bodies |

> †: Configurable implementation of variable expansion from URI Template (RFC 6570), the `application/x-www-form-urlencoded` serialization from RFC 1866, and OpenAPI 3.0.3. For details of the supported combinations, review <doc:Supported-OpenAPI-features>.

While the generator attempts to catch invalid inputs at generation time, there are still combinations of `Codable` types and locations that aren't compatible, and will only get caught at runtime by the specific coder implementation. For example, one could ask the `StringEncoder` to encode an array, but the encoder will throw an error, as containers are not supported in that encoder.

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
- **Coding strategy** represents the chosen coder to convert between the Swift type and data. Supported options:
    - `JSON`
        - example content type: `application/json` and any with the `+json` suffix
        - `{"color": "red", "power": 24}`
    - `URI`
        - example: query, path, header parameters
        - `color=red&power=24`
    - `urlEncodedForm`
        - example: request body with the `application/x-www-form-urlencoded` content type
        - `greeting=Hello+world`
    - `multipart`
        - example: request body with the `multipart/form-data` content type
        - part 1: `{"color": "red", "power": 24}`, part 2: `greeting=Hello+world`
    - `binary`
        - example: `application/octet-stream`
        - serves as the fallback for content types that don't have more specific handling
        - doesn't transform the binary data, just passes it through
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

| Client/server | Set/get | Schema location | Coding strategy | Optional/required | Method name |
| --------------| ------- | --------------- | --------------- | ------------------| ----------- |
| common | set | header field | URI | both | setHeaderFieldAsURI |
| common | set | header field | JSON | both | setHeaderFieldAsJSON |
| common | get | header field | URI | optional | getOptionalHeaderFieldAsURI |
| common | get | header field | URI | required | getRequiredHeaderFieldAsURI |
| common | get | header field | JSON | optional | getOptionalHeaderFieldAsJSON |
| common | get | header field | JSON | required | getRequiredHeaderFieldAsJSON |
| client | set | request path | URI | required | renderedPath |
| client | set | request query | URI | both | setQueryItemAsURI |
| client | set | request body | JSON | optional | setOptionalRequestBodyAsJSON |
| client | set | request body | JSON | required | setRequiredRequestBodyAsJSON |
| client | set | request body | binary | optional | setOptionalRequestBodyAsBinary |
| client | set | request body | binary | required | setRequiredRequestBodyAsBinary |
| client | set | request body | urlEncodedForm | optional | setOptionalRequestBodyAsURLEncodedForm | 
| client | set | request body | urlEncodedForm | required | setRequiredRequestBodyAsURLEncodedForm | 
| client | set | request body | multipart | required | setRequiredRequestBodyAsMultipart | 
| client | get | response body | JSON | required | getResponseBodyAsJSON |
| client | get | response body | binary | required | getResponseBodyAsBinary |
| client | get | response body | multipart | required | getResponseBodyAsMultipart |
| server | get | request path | URI | required | getPathParameterAsURI |
| server | get | request query | URI | optional | getOptionalQueryItemAsURI |
| server | get | request query | URI | required | getRequiredQueryItemAsURI |
| server | get | request body | JSON | optional | getOptionalRequestBodyAsJSON |
| server | get | request body | JSON | required | getRequiredRequestBodyAsJSON |
| server | get | request body | binary | optional | getOptionalRequestBodyAsBinary |
| server | get | request body | binary | required | getRequiredRequestBodyAsBinary |
| server | get | request body | urlEncodedForm | optional | getOptionalRequestBodyAsURLEncodedForm |
| server | get | request body | urlEncodedForm | required | getRequiredRequestBodyAsURLEncodedForm |
| server | get | request body | multipart | required | getRequiredRequestBodyAsMultipart |
| server | set | response body | JSON | required | setResponseBodyAsJSON |
| server | set | response body | binary | required | setResponseBodyAsBinary |
| server | set | response body | multipart | required | setResponseBodyAsMultipart |
