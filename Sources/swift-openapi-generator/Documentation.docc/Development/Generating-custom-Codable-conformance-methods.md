# Generating custom Codable implementations

Learn about when and how the generator emits a custom Codable implementation.

## Overview

As much as possible, the generator tries to rely on the [compiler-synthesized](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types#2904055) implementation of Codable requirements:
- [`init(from: Decoder) throws`](https://developer.apple.com/documentation/swift/decodable/init(from:)-8ezpn)
- [`func encode(to: Encoder) throws`](https://developer.apple.com/documentation/swift/encodable/encode(to:)-7ibwv)

The synthesized implementation is used as-is for:
- primitive types, such as `String`, `Int`, `Double`, and `Bool`
- string and integer-backed enums
- arrays of other Codable types
- structs generated for `object` schemas with no `additionalProperties` customization

However, a custom Codable implementation is emitted for the following types:
- structs generated for `object` schemas with `additionalProperties` customized
- structs generated for `allOf` and `anyOf` schemas
- enums with associated values generated for `oneOf` schemas

This document goes into detail about each of these types, explains why a custom Codable implementation is needed, and how it works.

> Tip: To check out a concrete example of generated Codable conformances, inspect the file-based reference tests, which contain realistic examples of generated code for various schemas. 

### Object structs with additional properties

An [`object` schema](https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00#section-4.2.1) can have the [`additionalProperties`](https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00#section-10.3.2.3) key, which documents how any properties _not_ documented in the `properties` key should be handled.

1. When the `additionalProperties` key is unspecified in an object schema, no custom Codable implementation is emitted and the generator lets the Swift compiler synthesize one based on the stored properties.
    - Custom decoder: no
    - Custom encoder: no
2. When `additionalProperties: false`, any additional properties are forbidden.
    - Custom decoder: yes, it decodes documented properties and then throws an error if any unknown properties are detected.
    - Custom encoder: no, since there is no storage to put them, so the user could not have accidentally created such an value of the struct, and there is no need to perform additional validation on encoding.
3. When `additionalProperties: true`, an extra property called `additionalProperties` of type `OpenAPIRuntime.OpenAPIObjectContainer` is generated on the struct, in addition to any documented stored properties.
    - Custom decoder: yes, it decodes documented properties and then collects all unknown properties into the `additionalProperties` property, which is a key-value dictionary with untyped values.
    - Custom encoder: yes, it encodes all documented and additional properties.
4. When `additionalProperties: {type: ...}`, for example `{type: integer}`, all unknown properties must have an integer value. An extra property called `additionalProperties` of type (for example) `[String: Int]` is generated on the struct, in addition to any documented stored properties.
    - Custom decoder: yes, similar to 3., with the difference that values are validated to be of the specified type (for example, `Int`).
    - Custom encoder, yes, same as 3.

### Structs for allOf and anyOf

The [`allOf`](https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00#section-10.2.1.1) and [`anyOf`](https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00#section-10.2.1.2) schemas include one or more subschemas that all (for `allOf`) or at least one (for `anyOf`) need to be decodable from the underlying value.

These schemas are generated as a struct where each property maps to one subschema.

For `allOf`, all properties are required, and for `anyOf`, all properties are optional.

Since the subschemas are all using the same top level container for coding, the synthesized Codable implementation cannot be used and the generator always emits custom methods for coding.

An important concept referenced below is of a "key-value pair schema". A key-value pair schema is defined as one of:
- `object`
- `allOf` where all subschemas are also key-value pair schemas
- `anyOf` or `oneOf` where at least one subschema is also a key-value pair schema

The reason we make the distinction between key-value pair schemas and other schemas is because key-value pair schemas can be safely combined (you can merge two dictionaries), but other schemas cannot be safely combined (there's no way to combine two strings, or an integer and an array, and so on). Common Swift coders, such as JSONEncoder and JSONDecoder require that we use the right methods, as you, for example, cannot encode into a single value container more than once.

The custom Codable implementations work as follows:

- `allOf`:
    - Custom decoder: yes, for key-value pair schemas uses `init(from:)` of the type directly, for others decodes from a single value container.
    - Custom encoder: yes, only encodes the first non-key-value pair schema using a single value container (reason: encoding any additional one would overwrite the first value, and the different values should persist to the same exact bytes on the wire, so only encoding the first one is safe). If no non-key-value pair subschemas are present, encodes all the key-value pair subschemas using their `encoder(to:)` method directly. (Note that an `allOf` that has both non-key-value pair and key-value pair subschemas are not valid, as it's not possible, for example, for something to be _both_ a string and a dictionary.)
- `anyOf`:
    - Custom decoder: yes, for key-value pair schemas uses `init(from:)` of the type directly, for others decodes from a single value container. The decoding is graceful, in other words any failure is turned into a nil result. But, to ensure a valid `anyOf`, at the end it validates that at least one subschema decoded successfully, otherwise throws an error.
    - Custom encoder: yes, only encodes the first _non-nil_ non-key-value pair schema using a single value container (similar to the `allOf` encoder above), then it encodes all the key-value pair subschemas using their `encoder(to:)` method directly. Note that only if all of the non-key-value pair schemas were nil will it actually encode the key-value pairs, again because an `anyOf` cannot be simultaneously a single value schema (for example, a string) and a key-value pair schema (for example, a dictionary). 

### Enums for oneOf

A [`oneOf`](https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00#section-10.2.1.3) schema represents a payload that matches exactly one subschema (but not more).

In Swift, the generator emits an enum with associated values, which matches the JSON Schema semantics.

There are two groups of oneOf schemas, which require different handling - based on whether a _discriminator_ is present.

A [discriminator](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#discriminator-object) is one value in the payload that encodes the name of the schema that should be used to encode and decode the payload. While normally JSON payloads are _not_ self-describing (in other words, the code needs to know which type-safe object to decode the value into upfront), including a discriminator allows for heterogeneous collections and decoding based on this dynamic value - making the payload self-describing.

Including a discriminator restricts the subschemas to be object-ish (objects and allOf/anyOf/oneOf of object-ish subschemas) schemas, as no other schemas can have properties, and a discriminator is always a property. However, it allows direct decoding, so instead of trying to decode the payload using each subschema, one by one, until one succeeds, the discriminator tells the decoder which type to use for decoding.

| Has discriminator | Allowed subschemas | Decoding |
| ----------------- | ------------------ | -------- |
| Yes | Only object-ish | Direct |
| No | All | Try one-by-one |

The rule of thumb is roughly as follows:
- If needing to include non-object-ish schemas in a oneOf, don't use a discriminator.
- If only including object-ish schemas, use a discriminator
    - while not required, it is recommended for better performance and debugging.
    - it also allows having multiple schemas that would successfully validate from the payload, but without a discriminator would fail to be a valid oneOf, where exactly one schema must validate (but not more).

#### oneOf without a discriminator

- Custom decoder: yes, tries to decode each subschema one-by-one, and stops when one validates correctly. For decoding the subschemas, it uses the same rules as allOf/anyOf, where key-value pair schemas are decoded directly using `init(from:)`, and other schemas are decoded from a single value container.
- Custom encoder: yes, a switch statement over the schema and only encodes the value matching the case of the enum, again, using the direct `encode(to:)` method for key-value pair schemas, and a single value container for all other schemas.

#### oneOf with a discriminator

- Custom decoder: yes, performs decoding in two stages. First, decodes the discriminator property value to identify the Swift type to decode the full payload into. Then switches over the discriminator value and decodes the full payload using the chosen type. Since oneOf enums with a discriminator always contain object-ish schemas, which are key-value pair schemas, uses the direct `init(from:)` decoding initializer.
- Custom encoder: yes, same as oneOf without a discriminator, but always uses `encode(to:)` because only key-value pair schemas are ever used here.

### A note on Foundation.Date

While `Foundation.Date` technically conforms to `Codable`, it's not really codable on its own, as the method for coding is customizable by JSONEncoder/JSONDecoder (and other coders) using `dateEncodingStrategy`.

This means that you cannot use Date's `init(from:)` and `encode(to:)` methods directly, otherwise you always get the default date encoding, which uses a `Double` - not what you usually want (ISO 8601 is more widely used).

Having to go through the container, which goes through the coder's customized Date coding strategy is part of the reason behind some of the complexity above and why we need to make the distinction between "key-value pair schemas" and others.
