# Converting between data and Swift types

Learn about the type responsible for convertering between raw data and Swift types.

## Overview

The [`Converter`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter.swift) type is a structure defined in the runtime library and is used by both the client and server generated code to perform conversions between raw data and Swift types.

> Note: `Converter` is one of the SPI types, not considered part of the public API of the runtime library. However, because generated code relies on it, SPI stability needs to be considered when making changes to it and to the generator.

Most of the functionality of `Converter` is implemented as helper methods in extensions:
- [`Converter+Client.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BClient.swift)
- [`Converter+Server.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BServer.swift)
- [`Converter+Common.swift`](https://github.com/apple/swift-openapi-runtime/blob/main/Sources/OpenAPIRuntime/Conversion/Converter%2BCommon.swift)

Some helper methods can be reused between client and server code, such as headers, but most can't. It's important that we only generalize (move helper methods into common extensions) if the client and server variants would have been exact copies. However, if there are differences, prefer to keep them separate and optimize each variant (for client or server) separately.

### Generated code and generics interaction

As outlined in <doc:Project-scope-and-goals>, we aim to minimize the complexity of the generator and rely on the Swift compiler to help ensure that if generated code compiles, it's likely to work correctly.

To that end, if the input OpenAPI document contains an input that Swift OpenAPI Generator doesn't support, our first preference is to catch it in the generator and emit a descriptive error. However, there are cases where that is prohibitively complex, and we let the Swift compiler ensure that, for example, an array of strings cannot be used as a path parameter. In this example case, the generator emits code with the path parameter being of Swift type `[String]`, but since there doesn't exist a converter method for it, it will fail to build. This is considered expected behavior.

In the case of the converter, it contains helper methods for all the supported combinations of an HTTP location, a "content type family" and a Swift type.

First, a _schema location_ refers to one of the several places where schemas can be used in OpenAPI documents. For example:
- request path parameters
- request headers
- response bodies
- and more

Second, a _content type family_ can be one of:
- `structured`
    - example: `application/json`
    - uses the type's `Codable` implementation
- `text`
    - example: `text/plain`
    - uses the type's `LosslessStringConvertible` implementation, except for `Foundation.Date`, which uses a system date formatter
- `raw`
    - example: `application/octet-stream`
    - doesn't transform the raw data, just passes it through

The content type family is derived from the `content` map in the OpenAPI document, if provided. If none is provided, such as in case of parameters, `text` is used.

And third, a Swift type is calculated from the JSON schema provided in the OpenAPI document.

For example, a `string` schema is generated as `Swift.String`, an `object` schema is generated as a Swift structure, and an array schema is generated as a `Swift.Array` generic over the element type.

Together, the schema location, the content type family, and the Swift type is enough to unambiguously decide which helper method on the converter should be used.

For example, to use the converter to get a required response header of type `Foundation.Date` using the `text` content type family, look for a method (exact spelling is subject to change) that looks like:

```swift
func headerFieldGetTextRequired( // <<< 1.
    in headerFields: [HeaderField],
    name: String,
    as type: Date.Type // <<< 2.
) throws -> Date
```

In `1.`, notice that the method name contains which schema location, content type family, and optionality; whilie in `2.` it contains the Swift type.

### Helper method variants

In the nested list below, each leaf is one helper method.

"string-convertible" refers to types that conform to `LosslessStringConvertible` (but not `Foundation.Date`, which is handled separately).


#### Required by client code

- request
   - set request path [client-only]
       - text
           - string-convertible
               - optional/required
           - date
               - optional/required
   - set request query [client-only]
       - text
           - string-convertible
               - optional/required
           - array of string-convertibles
               - optional/required
           - date
               - optional/required
           - array of dates
               - optional/required
   - set request headers [common]
       - text
           - string-convertible
               - optional/required
           - array of string-convertibles
               - optional/required
           - date
               - optional/required
           - array of dates
               - optional/required
       - structured
           - codable
               - optional/required
   - set request body [client-only]
       - text
           - string-convertible
               - optional
               - required
           - date
               - optional
               - required
       - structured
           - codable
               - optional
               - required
       - raw
           - data
               - optional
               - required
- response
   - get response headers [common]
       - text
           - string-convertible
               - optional
               - required
           - array of string-convertibles
               - optional
               - required
           - date
               - optional
               - required
           - array of dates
               - optional
               - required
       - structured
           - codable
               - optional
               - required
   - get response body [client-only]
       - text
           - string-convertible
               - required
           - date
               - required
       - structured
           - codable
               - required
       - raw
           - data
               - required

#### Required by server code

- request
   - get request path [server-only]
       - text
           - string-convertible
               - optional
               - required
           - date
               - optional
               - required
   - get request query [server-only]
       - text
           - string-convertible
               - optional
               - required
           - array of string-convertibles
               - optional
               - required
           - date
               - optional
               - required
           - array of dates
               - optional
               - required
   - get request headers [common]
       - text
           - string-convertible
               - optional
               - required
           - array of string-convertibles
               - optional
               - required
           - date
               - optional
               - required
           - array of dates
               - optional
               - required
       - structured
           - codable
               - optional
               - required
   - get request body [server-only]
       - text
           - string-convertible
               - optional
               - required
           - date
               - optional
               - required
       - structured
           - codable
               - optional
               - required
       - raw
           - data
               - optional
               - required
- response
   - set response headers [common]
       - text
           - string-convertible
               - optional/required
           - array of string-convertibles
               - optional/required
           - date
               - optional/required
           - array of dates
               - optional/required
       - structured
           - codable
               - optional/required
   - set response body [server-only]
       - text
           - string-convertible
               - required
           - date
               - required
       - structured
           - codable
               - required
       - raw
           - data
               - required
