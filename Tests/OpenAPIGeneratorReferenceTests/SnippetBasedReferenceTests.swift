//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import OpenAPIKit
import XCTest
import Yams
@testable import _OpenAPIGeneratorCore

/// Tests that the generator produces Swift code that match a reference.
final class SnippetBasedReferenceTests: XCTestCase {
    func testComponentsHeadersInline() throws {
        try self.assertHeadersTranslation(
            """
            headers:
              MyHeader:
                schema:
                  type: string
            """,
            """
            public enum Headers {
              public typealias MyHeader = Swift.String
            }
            """
        )
    }

    func testComponentsHeadersReference() throws {
        try self.assertHeadersTranslation(
            """
            schemas:
              MySchema:
                type: string
            headers:
              MyHeader:
                schema:
                  $ref: "#/components/schemas/MySchema"
            """,
            """
            public enum Headers {
              public typealias MyHeader = Components.Schemas.MySchema
            }
            """
        )
    }

    func testComponentsParametersInline() throws {
        try self.assertParametersTranslation(
            """
            parameters:
              MyParam:
                in: query
                name: my_param
                schema:
                  type: string
            """,
            """
            public enum Parameters {
              public typealias MyParam = Swift.String
            }
            """
        )
    }

    func testComponentsParametersReference() throws {
        try self.assertParametersTranslation(
            """
            schemas:
              MySchema:
                type: string
            parameters:
              MyParam:
                in: query
                name: my_param
                schema:
                  $ref: "#/components/schemas/MySchema"
            """,
            """
            public enum Parameters {
              public typealias MyParam = Components.Schemas.MySchema
            }
            """
        )
    }

    func testComponentsSchemasString() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyString:
                type: string
            """,
            """
            public enum Schemas {
                public typealias MyString = Swift.String
            }
            """
        )
    }

    func testComponentsSchemasNullableStringProperty() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObj:
                type: object
                properties:
                  fooOptional:
                    type: string
                  fooRequired:
                    type: string
                  fooOptionalNullable:
                    type: [string, null]
                  fooRequiredNullable:
                    type: [string, null]
                required:
                  - fooRequired
                  - fooRequiredNullable
            """,
            """
            public enum Schemas {
                public struct MyObj: Codable, Hashable, Sendable {
                    public var fooOptional: Swift.String?
                    public var fooRequired: Swift.String
                    public var fooOptionalNullable: Swift.String?
                    public var fooRequiredNullable: Swift.String?
                    public init(
                        fooOptional: Swift.String? = nil,
                        fooRequired: Swift.String,
                        fooOptionalNullable: Swift.String? = nil,
                        fooRequiredNullable: Swift.String? = nil
                    ) {
                        self.fooOptional = fooOptional
                        self.fooRequired = fooRequired
                        self.fooOptionalNullable = fooOptionalNullable
                        self.fooRequiredNullable = fooRequiredNullable
                    }
                    public enum CodingKeys: String, CodingKey {
                        case fooOptional
                        case fooRequired
                        case fooOptionalNullable
                        case fooRequiredNullable
                    }
                }
            }
            """
        )
    }

    func testComponentsObjectNoAdditionalProperties() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObject:
                type: object
                properties: {}
                additionalProperties: false
            """,
            """
            public enum Schemas {
                public struct MyObject: Codable, Hashable, Sendable {
                    public init() {}
                    public init(from decoder: any Decoder) throws {
                        try decoder.ensureNoAdditionalProperties(knownKeys: [])
                    }
                }
            }
            """
        )
    }

    func testComponentsObjectExplicitUntypedAdditionalProperties() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObject:
                type: object
                properties: {}
                additionalProperties: true
            """,
            """
            public enum Schemas {
                public struct MyObject: Codable, Hashable, Sendable {
                    public var additionalProperties: OpenAPIRuntime.OpenAPIObjectContainer
                    public init(additionalProperties: OpenAPIRuntime.OpenAPIObjectContainer = .init()) {
                        self.additionalProperties = additionalProperties
                    }
                    public init(from decoder: any Decoder) throws {
                        additionalProperties = try decoder.decodeAdditionalProperties(knownKeys: [])
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try encoder.encodeAdditionalProperties(additionalProperties)
                    }
                }
            }
            """
        )
    }

    func testComponentsObjectExplicitTypedAdditionalProperties() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObject:
                type: object
                properties: {}
                additionalProperties:
                  type: integer
            """,
            """
            public enum Schemas {
                public struct MyObject: Codable, Hashable, Sendable {
                    public var additionalProperties: [String: Swift.Int]
                    public init(additionalProperties: [String: Swift.Int] = .init()) {
                        self.additionalProperties = additionalProperties
                    }
                    public init(from decoder: any Decoder) throws {
                        additionalProperties = try decoder.decodeAdditionalProperties(knownKeys: [])
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try encoder.encodeAdditionalProperties(additionalProperties)
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasObjectWithProperties() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyRequiredString:
                type: string
              MyNullableString:
                type: [string, null]
              MyObject:
                type: object
                properties:
                  id:
                    type: integer
                    format: int64
                  alias:
                    type: string
                  requiredString:
                    $ref: '#/components/schemas/MyRequiredString'
                  nullableString:
                    $ref: '#/components/schemas/MyNullableString'
                required:
                  - id
                  - requiredString
                  - nullableString
            """,
            """
                public enum Schemas {
                  public typealias MyRequiredString = Swift.String
                  public typealias MyNullableString = Swift.String
                  public struct MyObject: Codable, Hashable, Sendable {
                    public var id: Swift.Int64
                    public var alias: Swift.String?
                    public var requiredString: Components.Schemas.MyRequiredString
                    public var nullableString: Components.Schemas.MyNullableString?
                    public init(
                        id: Swift.Int64,
                        alias: Swift.String? = nil,
                        requiredString: Components.Schemas.MyRequiredString,
                        nullableString: Components.Schemas.MyNullableString? = nil
                    ) {
                        self.id = id
                        self.alias = alias
                        self.requiredString = requiredString
                        self.nullableString = nullableString
                    }
                    public enum CodingKeys: String, CodingKey {
                        case id
                        case alias
                        case requiredString
                        case nullableString
                    }
                  }
                }
            """
        )
    }

    func testComponentsSchemasObjectWithPropertiesBinaryIsSkipped() throws {
        try self.assertSchemasTranslation(
            ignoredDiagnosticMessages: [
                "Schema \"string (binary)\" is not supported, reason: \"Binary properties in object schemas.\", skipping"
            ],
            """
            schemas:
              MyObject:
                type: object
                properties:
                  actualString:
                    type: string
                  binaryProperty:
                    type: string
                    format: binary
                required:
                  - actualString
                  - binaryProperty
            """,
            """
                public enum Schemas {
                  public struct MyObject: Codable, Hashable, Sendable {
                    public var actualString: Swift.String
                    public init(actualString: Swift.String) { self.actualString = actualString }
                    public enum CodingKeys: String, CodingKey { case actualString }
                  }
                }
            """
        )
    }

    func testComponentsSchemasAllOf() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A: {}
              B: {}
              MyAllOf:
                allOf:
                  - $ref: '#/components/schemas/A'
                  - $ref: '#/components/schemas/B'
                  - type: string
                  - type: array
                    items:
                      type: integer
            """,
            """
            public enum Schemas {
                public typealias A = OpenAPIRuntime.OpenAPIValueContainer
                public typealias B = OpenAPIRuntime.OpenAPIValueContainer
                public struct MyAllOf: Codable, Hashable, Sendable {
                    public var value1: Components.Schemas.A
                    public var value2: Components.Schemas.B
                    public var value3: Swift.String
                    public var value4: [Swift.Int]
                    public init(
                        value1: Components.Schemas.A,
                        value2: Components.Schemas.B,
                        value3: Swift.String,
                        value4: [Swift.Int]
                    ) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                        self.value4 = value4
                    }
                    public init(from decoder: any Decoder) throws {
                        value1 = try .init(from: decoder)
                        value2 = try .init(from: decoder)
                        value3 = try decoder.decodeFromSingleValueContainer()
                        value4 = try decoder.decodeFromSingleValueContainer()
                    }
                    public func encode(to encoder: any Encoder) throws { try encoder.encodeToSingleValueContainer(value3) }
                }
            }
            """
        )
    }

    func testComponentsSchemasAnyOf() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A: {}
              B: {}
              MyAnyOf:
                anyOf:
                  - $ref: '#/components/schemas/A'
                  - $ref: '#/components/schemas/B'
                  - type: string
                  - type: array
                    items:
                      type: integer
            """,
            """
            public enum Schemas {
                public typealias A = OpenAPIRuntime.OpenAPIValueContainer
                public typealias B = OpenAPIRuntime.OpenAPIValueContainer
                public struct MyAnyOf: Codable, Hashable, Sendable {
                    public var value1: Components.Schemas.A?
                    public var value2: Components.Schemas.B?
                    public var value3: Swift.String?
                    public var value4: [Swift.Int]?
                    public init(
                        value1: Components.Schemas.A? = nil,
                        value2: Components.Schemas.B? = nil,
                        value3: Swift.String? = nil,
                        value4: [Swift.Int]? = nil
                    ) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                        self.value4 = value4
                    }
                    public init(from decoder: any Decoder) throws {
                        value1 = try? .init(from: decoder)
                        value2 = try? .init(from: decoder)
                        value3 = try? decoder.decodeFromSingleValueContainer()
                        value4 = try? decoder.decodeFromSingleValueContainer()
                        try DecodingError.verifyAtLeastOneSchemaIsNotNil(
                            [value1, value2, value3, value4],
                            type: Self.self,
                            codingPath: decoder.codingPath
                        )
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try encoder.encodeFirstNonNilValueToSingleValueContainer([value3, value4])
                        try value1?.encode(to: encoder)
                        try value2?.encode(to: encoder)
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasOneOfWithDiscriminator() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A:
                type: object
                properties:
                  which:
                    type: string
              B:
                type: object
                properties:
                  which:
                    type: string
              MyOneOf:
                oneOf:
                  - $ref: '#/components/schemas/A'
                  - $ref: '#/components/schemas/B'
                  - type: string
                  - type: object
                    properties:
                      p:
                        type: integer
                discriminator:
                  propertyName: which
            """,
            """
            public enum Schemas {
                public struct A: Codable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                public struct B: Codable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                @frozen public enum MyOneOf: Codable, Hashable, Sendable {
                    case A(Components.Schemas.A)
                    case B(Components.Schemas.B)
                    public enum CodingKeys: String, CodingKey { case which }
                    public init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let discriminator = try container.decode(String.self, forKey: .which)
                        switch discriminator {
                        case "A", "#/components/schemas/A": self = .A(try .init(from: decoder))
                        case "B", "#/components/schemas/B": self = .B(try .init(from: decoder))
                        default:
                            throw DecodingError.failedToDecodeOneOfSchema(
                                type: Self.self,
                                codingPath: decoder.codingPath
                            )
                        }
                    }
                    public func encode(to encoder: any Encoder) throws {
                        switch self {
                        case let .A(value): try value.encode(to: encoder)
                        case let .B(value): try value.encode(to: encoder)
                        }
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasOneOfWithDiscriminatorWithMapping() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A:
                type: object
                properties:
                  which:
                    type: string
              B:
                type: object
                properties:
                  which:
                    type: string
              C:
                type: object
                properties:
                  which:
                    type: string
              MyOneOf:
                oneOf:
                  - $ref: '#/components/schemas/A'
                  - $ref: '#/components/schemas/B'
                  - $ref: '#/components/schemas/C'
                discriminator:
                  propertyName: which
                  mapping:
                    a: '#/components/schemas/A'
                    a2: '#/components/schemas/A'
                    b: '#/components/schemas/B'
            """,
            """
            public enum Schemas {
                public struct A: Codable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                public struct B: Codable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                public struct C: Codable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                @frozen public enum MyOneOf: Codable, Hashable, Sendable {
                    case a(Components.Schemas.A)
                    case a2(Components.Schemas.A)
                    case b(Components.Schemas.B)
                    case C(Components.Schemas.C)
                    public enum CodingKeys: String, CodingKey { case which }
                    public init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let discriminator = try container.decode(String.self, forKey: .which)
                        switch discriminator {
                        case "a": self = .a(try .init(from: decoder))
                        case "a2": self = .a2(try .init(from: decoder))
                        case "b": self = .b(try .init(from: decoder))
                        case "C", "#/components/schemas/C": self = .C(try .init(from: decoder))
                        default:
                            throw DecodingError.failedToDecodeOneOfSchema(
                                type: Self.self,
                                codingPath: decoder.codingPath
                            )
                        }
                    }
                    public func encode(to encoder: any Encoder) throws {
                        switch self {
                        case let .a(value): try value.encode(to: encoder)
                        case let .a2(value): try value.encode(to: encoder)
                        case let .b(value): try value.encode(to: encoder)
                        case let .C(value): try value.encode(to: encoder)
                        }
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasOneOf_closed() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A: {}
              MyOneOf:
                oneOf:
                  - type: string
                  - type: integer
                  - $ref: '#/components/schemas/A'
            """,
            """
            public enum Schemas {
                public typealias A = OpenAPIRuntime.OpenAPIValueContainer
                @frozen public enum MyOneOf: Codable, Hashable, Sendable {
                    case case1(Swift.String)
                    case case2(Swift.Int)
                    case A(Components.Schemas.A)
                    public init(from decoder: any Decoder) throws {
                        do {
                            self = .case1(try decoder.decodeFromSingleValueContainer())
                            return
                        } catch {}
                        do {
                            self = .case2(try decoder.decodeFromSingleValueContainer())
                            return
                        } catch {}
                        do {
                            self = .A(try .init(from: decoder))
                            return
                        } catch {}
                        throw DecodingError.failedToDecodeOneOfSchema(
                            type: Self.self,
                            codingPath: decoder.codingPath
                        )
                    }
                    public func encode(to encoder: any Encoder) throws {
                        switch self {
                        case let .case1(value): try encoder.encodeToSingleValueContainer(value)
                        case let .case2(value): try encoder.encodeToSingleValueContainer(value)
                        case let .A(value): try value.encode(to: encoder)
                        }
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasOneOf_open_pattern() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A:
                type: object
                additionalProperties: false
              MyOpenOneOf:
                anyOf:
                  - oneOf:
                    - type: string
                    - type: integer
                    - $ref: '#/components/schemas/A'
                  - {}
            """,
            """
            public enum Schemas {
                public struct A: Codable, Hashable, Sendable {
                    public init() {}
                    public init(from decoder: any Decoder) throws {
                        try decoder.ensureNoAdditionalProperties(knownKeys: [])
                    }
                }
                public struct MyOpenOneOf: Codable, Hashable, Sendable {
                    @frozen public enum Value1Payload: Codable, Hashable, Sendable {
                        case case1(Swift.String)
                        case case2(Swift.Int)
                        case A(Components.Schemas.A)
                        public init(from decoder: any Decoder) throws {
                            do {
                                self = .case1(try decoder.decodeFromSingleValueContainer())
                                return
                            } catch {}
                            do {
                                self = .case2(try decoder.decodeFromSingleValueContainer())
                                return
                            } catch {}
                            do {
                                self = .A(try .init(from: decoder))
                                return
                            } catch {}
                            throw DecodingError.failedToDecodeOneOfSchema(
                                type: Self.self,
                                codingPath: decoder.codingPath
                            )
                        }
                        public func encode(to encoder: any Encoder) throws {
                            switch self {
                            case let .case1(value): try encoder.encodeToSingleValueContainer(value)
                            case let .case2(value): try encoder.encodeToSingleValueContainer(value)
                            case let .A(value): try value.encode(to: encoder)
                            }
                        }
                    }
                    public var value1: Components.Schemas.MyOpenOneOf.Value1Payload?
                    public var value2: OpenAPIRuntime.OpenAPIValueContainer?
                    public init(
                        value1: Components.Schemas.MyOpenOneOf.Value1Payload? = nil,
                        value2: OpenAPIRuntime.OpenAPIValueContainer? = nil
                    ) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                    public init(from decoder: any Decoder) throws {
                        value1 = try? .init(from: decoder)
                        value2 = try? .init(from: decoder)
                        try DecodingError.verifyAtLeastOneSchemaIsNotNil(
                            [value1, value2],
                            type: Self.self,
                            codingPath: decoder.codingPath
                        )
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try value1?.encode(to: encoder)
                        try value2?.encode(to: encoder)
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasAllOfOneStringRef() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A:
                type: string
              MyAllOf:
                allOf:
                  - $ref: '#/components/schemas/A'
            """,
            """
            public enum Schemas {
                public typealias A = Swift.String
                public struct MyAllOf: Codable, Hashable, Sendable {
                    public var value1: Components.Schemas.A
                    public init(value1: Components.Schemas.A) {
                        self.value1 = value1
                    }
                    public init(from decoder: any Decoder) throws { value1 = try decoder.decodeFromSingleValueContainer() }
                    public func encode(to encoder: any Encoder) throws { try encoder.encodeToSingleValueContainer(value1) }
                }
            }
            """
        )
    }

    func testComponentsSchemasObjectWithRequiredAllOfOneStringRefProperty() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A:
                type: string
              B:
                type: object
                required:
                  - c
                properties:
                  c:
                    allOf:
                      - $ref: "#/components/schemas/A"
            """,
            """
            public enum Schemas {
                public typealias A = Swift.String
                public struct B: Codable, Hashable, Sendable {
                    public struct cPayload: Codable, Hashable, Sendable {
                        public var value1: Components.Schemas.A
                        public init(value1: Components.Schemas.A) { self.value1 = value1 }
                        public init(from decoder: any Decoder) throws { value1 = try decoder.decodeFromSingleValueContainer() }
                        public func encode(to encoder: any Encoder) throws { try encoder.encodeToSingleValueContainer(value1) }
                    }
                    public var c: Components.Schemas.B.cPayload
                    public init(c: Components.Schemas.B.cPayload) { self.c = c }
                    public enum CodingKeys: String, CodingKey { case c }
                }
            }
            """
        )
    }

    func testComponentsSchemasObjectWithOptionalAllOfOneStringRefProperty() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              A:
                type: string
              B:
                type: object
                required: []
                properties:
                  c:
                    allOf:
                      - $ref: "#/components/schemas/A"
            """,
            """
            public enum Schemas {
                public typealias A = Swift.String
                public struct B: Codable, Hashable, Sendable {
                    public struct cPayload: Codable, Hashable, Sendable {
                        public var value1: Components.Schemas.A
                        public init(value1: Components.Schemas.A) { self.value1 = value1 }
                        public init(from decoder: any Decoder) throws { value1 = try decoder.decodeFromSingleValueContainer() }
                        public func encode(to encoder: any Encoder) throws { try encoder.encodeToSingleValueContainer(value1) }
                    }
                    public var c: Components.Schemas.B.cPayload?
                    public init(c: Components.Schemas.B.cPayload? = nil) { self.c = c }
                    public enum CodingKeys: String, CodingKey { case c }
                }
            }
            """
        )
    }

    func testComponentsSchemasStringEnum() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyEnum:
                type: string
                enum:
                  - one
                  -
                  - $tart
                  - public
            """,
            """
            public enum Schemas {
                @frozen public enum MyEnum: String, Codable, Hashable, Sendable {
                    case one = "one"
                    case _empty = ""
                    case _dollar_tart = "$tart"
                    case _public = "public"
                }
            }
            """
        )
    }

    func testComponentsSchemasIntEnum() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyEnum:
                type: integer
                enum:
                  - 0
                  - 10
                  - 20
            """,
            """
            public enum Schemas {
                @frozen public enum MyEnum: Int, Codable, Hashable, Sendable {
                    case _0 = 0
                    case _10 = 10
                    case _20 = 20
                }
            }
            """
        )
    }

    func testComponentsSchemasEnum_open_pattern() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyOpenEnum:
                anyOf:
                  - type: string
                    enum:
                      - one
                      - two
                  - type: string
            """,
            """
            public enum Schemas {
                public struct MyOpenEnum: Codable, Hashable, Sendable {
                    @frozen
                    public enum Value1Payload: String, Codable, Hashable, Sendable {
                        case one = "one"
                        case two = "two"
                    }
                    public var value1: Components.Schemas.MyOpenEnum.Value1Payload?
                    public var value2: Swift.String?
                    public init(
                        value1: Components.Schemas.MyOpenEnum.Value1Payload? = nil,
                        value2: Swift.String? = nil
                    ) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                    public init(from decoder: any Decoder) throws {
                        value1 = try? decoder.decodeFromSingleValueContainer()
                        value2 = try? decoder.decodeFromSingleValueContainer()
                        try DecodingError.verifyAtLeastOneSchemaIsNotNil(
                            [value1, value2],
                            type: Self.self,
                            codingPath: decoder.codingPath
                        )
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try encoder.encodeFirstNonNilValueToSingleValueContainer([value1, value2])
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasDeprecatedObject() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObject:
                type: object
                properties: {}
                additionalProperties: false
                deprecated: true
            """,
            """
            public enum Schemas {
                @available(*, deprecated)
                public struct MyObject: Codable, Hashable, Sendable {
                    public init() {}
                    public init(from decoder: any Decoder) throws {
                        try decoder.ensureNoAdditionalProperties(knownKeys: [])
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasObjectWithDeprecatedProperty() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObject:
                type: object
                properties:
                  id:
                    type: string
                    deprecated: true
            """,
            """
            public enum Schemas {
                public struct MyObject: Codable, Hashable, Sendable {
                    @available(*, deprecated)
                    public var id: Swift.String?
                    public init(id: Swift.String? = nil) { self.id = id }
                    public enum CodingKeys: String, CodingKey { case id }
                }
            }
            """
        )
    }

    func testComponentsSchemasDateTime() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyDate:
                type: string
                format: date-time
            """,
            """
            public enum Schemas {
                public typealias MyDate = Foundation.Date
            }
            """
        )
    }

    func testComponentsSchemasBase64() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyData:
                type: string
                format: byte
            """,
            """
            public enum Schemas {
                public typealias MyData = OpenAPIRuntime.Base64EncodedData
            }
            """
        )
    }

    func testComponentsSchemasBase64Object() throws {
        try self.assertSchemasTranslation(
            """
            schemas:
              MyObj:
                type: object
                properties:
                  stuff:
                    type: string
                    format: byte
            """,
            """
            public enum Schemas {
                public struct MyObj: Codable, Hashable, Sendable {
                    public var stuff: OpenAPIRuntime.Base64EncodedData?
                    public init(stuff: OpenAPIRuntime.Base64EncodedData? = nil) {
                      self.stuff = stuff
                    }
                    public enum CodingKeys: String, CodingKey { case stuff }
                }
            }
            """
        )
    }

    func testComponentsResponsesResponseNoBody() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              BadRequest:
                description: Bad request
            """,
            """
            public enum Responses {
                public struct BadRequest: Sendable, Hashable {
                    public init() {}
                }
            }
            """
        )
    }

    func testComponentsResponsesResponseWithBody() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              BadRequest:
                description: Bad request
                content:
                  application/json:
                    schema:
                      type: string
            """,
            """
            public enum Responses {
                public struct BadRequest: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable {
                        case json(Swift.String)
                        public var json: Swift.String {
                            get throws {
                                switch self {
                                case let .json(body): return body
                                }
                            }
                        }
                    }
                    public var body: Components.Responses.BadRequest.Body
                    public init(
                        body: Components.Responses.BadRequest.Body
                    ) {
                        self.body = body
                    }
                }
            }
            """
        )
    }

    func testComponentsResponsesResponseMultipleContentTypes() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              MultipleContentTypes:
                description: Multiple content types
                content:
                  application/json:
                    schema:
                      type: integer
                  application/json; foo=bar:
                    schema:
                      type: integer
                  text/plain: {}
                  application/octet-stream: {}
            """,
            """
            public enum Responses {
                public struct MultipleContentTypes: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable {
                        case json(Swift.Int)
                        public var json: Swift.Int { get throws {
                            switch self {
                            case let .json(body): return body
                            default: try throwUnexpectedResponseBody(expectedContent: "application/json", body: self)
                            }
                        }}
                        case application_json_foo_bar(Swift.Int)
                        public var application_json_foo_bar: Swift.Int { get throws {
                            switch self {
                            case let .application_json_foo_bar(body): return body
                            default: try throwUnexpectedResponseBody(expectedContent: "application/json", body: self)
                            }
                        }}
                        case plainText(OpenAPIRuntime.HTTPBody)
                        public var plainText: OpenAPIRuntime.HTTPBody { get throws {
                            switch self {
                            case let .plainText(body): return body
                            default: try throwUnexpectedResponseBody(expectedContent: "text/plain", body: self)
                            }
                        }}
                        case binary(OpenAPIRuntime.HTTPBody)
                        public var binary: OpenAPIRuntime.HTTPBody { get throws {
                            switch self {
                            case let .binary(body): return body
                            default: try throwUnexpectedResponseBody(expectedContent: "application/octet-stream", body: self)
                            }
                        }}
                    }
                    public var body: Components.Responses.MultipleContentTypes.Body
                    public init(
                        body: Components.Responses.MultipleContentTypes.Body
                    ) {
                        self.body = body
                    }
                }
            }
            """
        )
    }

    func testComponentsResponsesResponseWithHeader() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              BadRequest:
                description: Bad request
                headers:
                  X-Reason:
                    schema:
                      type: string
            """,
            """
            public enum Responses {
                public struct BadRequest: Sendable, Hashable {
                    public struct Headers: Sendable, Hashable {
                        public var X_hyphen_Reason: Swift.String?
                        public init(X_hyphen_Reason: Swift.String? = nil) {
                            self.X_hyphen_Reason = X_hyphen_Reason }
                    }
                    public var headers: Components.Responses.BadRequest.Headers
                    public init(
                        headers: Components.Responses.BadRequest.Headers = .init()
                    ) {
                        self.headers = headers
                    }
                }
            }
            """
        )
    }

    func testComponentsResponsesResponseWithRequiredHeader() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              BadRequest:
                description: Bad request
                headers:
                  X-Reason:
                    schema:
                      type: string
                    required: true
            """,
            """
            public enum Responses {
                public struct BadRequest: Sendable, Hashable {
                    public struct Headers: Sendable, Hashable {
                        public var X_hyphen_Reason: Swift.String
                        public init(X_hyphen_Reason: Swift.String) {
                            self.X_hyphen_Reason = X_hyphen_Reason }
                    }
                    public var headers: Components.Responses.BadRequest.Headers
                    public init(
                        headers: Components.Responses.BadRequest.Headers
                    ) {
                        self.headers = headers
                    }
                }
            }
            """
        )
    }

    func testComponentsRequestBodiesInline() throws {
        try self.assertRequestBodiesTranslation(
            """
            requestBodies:
              MyResponseBody:
                content:
                  application/json:
                    schema:
                      type: string
            """,
            """
            public enum RequestBodies {
                @frozen public enum MyResponseBody: Sendable, Hashable {
                    case json(Swift.String)
                }
            }
            """
        )
    }

    func testComponentsRequestBodiesReference() throws {
        try self.assertRequestBodiesTranslation(
            """
            requestBodies:
              MyResponseBody:
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/MyBody'
            """,
            """
            public enum RequestBodies {
                @frozen public enum MyResponseBody: Sendable, Hashable {
                    case json(Components.Schemas.MyBody)
                }
            }
            """
        )
    }

    func testComponentsRequestBodiesMultipleContentTypes() throws {
        try self.assertRequestBodiesTranslation(
            """
            requestBodies:
              MyResponseBody:
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/MyBody'
                  text/plain: {}
                  application/octet-stream: {}
            """,
            """
            public enum RequestBodies {
                @frozen public enum MyResponseBody: Sendable, Hashable {
                    case json(Components.Schemas.MyBody)
                    case plainText(OpenAPIRuntime.HTTPBody)
                    case binary(OpenAPIRuntime.HTTPBody)
                }
            }
            """
        )
    }

    func testComponentsRequestBodiesInline_urlEncodedForm() throws {
        try self.assertRequestBodiesTranslation(
            """
            requestBodies:
              MyRequestBody:
                content:
                  application/x-www-form-urlencoded:
                    schema:
                      type: object
                      properties:
                        foo:
                          type: string
                      required: [foo]
            """,
            """
            public enum RequestBodies {
                @frozen public enum MyRequestBody: Sendable, Hashable {
                    public struct urlEncodedFormPayload: Codable, Hashable, Sendable {
                        public var foo: Swift.String
                        public init(foo: Swift.String) { self.foo = foo }
                        public enum CodingKeys: String, CodingKey { case foo }
                    }
                    case urlEncodedForm(Components.RequestBodies.MyRequestBody.urlEncodedFormPayload)
                }
            }
            """
        )
    }

    func testPathsSimplestCase() throws {
        try self.assertPathsTranslation(
            """
            /health:
              get:
                operationId: getHealth
                responses:
                  '200':
                    description: A success response with a greeting.
                    content:
                      text/plain:
                        schema:
                          type: string
            """,
            """
            public protocol APIProtocol: Sendable {
                func getHealth(_ input: Operations.getHealth.Input) async throws -> Operations.getHealth.Output
            }
            """
        )
    }

    func testPathsSimplestCaseExtension() throws {
        try self.assertPathsTranslationExtension(
            """
            /health:
              get:
                operationId: getHealth
                responses:
                  '200':
                    description: A success response with a greeting.
                    content:
                      text/plain:
                        schema:
                          type: string
            """,
            """
            extension APIProtocol {
                public func getHealth(headers: Operations.getHealth.Input.Headers = .init()) async throws -> Operations.getHealth.Output {
                    try await getHealth(Operations.getHealth.Input(headers: headers))
                }
            }
            """
        )
    }

    func testServerRegisterHandlers_oneOperation() throws {
        try self.assertServerRegisterHandlers(
            """
            /health:
              get:
                operationId: getHealth
                responses:
                  '200':
                    description: A success response with a greeting.
                    content:
                      text/plain:
                        schema:
                          type: string
            """,
            """
            public func registerHandlers(
                on transport: any ServerTransport,
                serverURL: URL = .defaultOpenAPIServerURL,
                configuration: Configuration = .init(),
                middlewares: [any ServerMiddleware] = []
            ) throws {
                let server = UniversalServer(
                    serverURL: serverURL,
                    handler: self,
                    configuration: configuration,
                    middlewares: middlewares
                )
                try transport.register(
                    { try await server.getHealth(request: $0, body: $1, metadata: $2) },
                    method: .get,
                    path: server.apiPathComponentsWithServerPrefix("/health")
                )
            }
            """
        )
    }

    func testServerRegisterHandlers_noOperation() throws {
        try self.assertServerRegisterHandlers(
            """
            {}
            """,
            """
            public func registerHandlers(
                on transport: any ServerTransport,
                serverURL: URL = .defaultOpenAPIServerURL,
                configuration: Configuration = .init(),
                middlewares: [any ServerMiddleware] = []
            ) throws {
            }
            """
        )
    }

    func testPathWithPathItemReference() throws {
        XCTAssertThrowsError(
            try self.assertPathsTranslation(
                """
                /health:
                  get:
                    operationId: getHealth
                    responses:
                      '200':
                        description: A success response with a greeting.
                        content:
                          text/plain:
                            schema:
                              type: string
                /health2:
                  $ref: "#/paths/~1health"
                """,
                """
                unused: This test throws an error.
                """
            )
        )
    }

    func testResponseWithExampleWithSummaryAndValue() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              MyResponse:
                description: Some response
                content:
                  application/json:
                    schema:
                      type: string
                    examples:
                      application/json:
                        summary: "a hello response"
                        value: "hello"
            """,
            """
            public enum Responses {
                public struct MyResponse: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable {
                        case json(Swift.String)
                        public var json: Swift.String {
                            get throws { switch self { case let .json(body): return body } }
                        }
                    }
                    public var body: Components.Responses.MyResponse.Body
                    public init(
                        body: Components.Responses.MyResponse.Body
                    ) {
                        self.body = body
                    }
                }
            }
            """
        )
    }

    func testResponseWithExampleWithOnlyValue() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              MyResponse:
                description: Some response
                content:
                  application/json:
                    schema:
                      type: string
                    examples:
                      application/json:
                        summary: "a hello response"
            """,
            """
            public enum Responses {
                public struct MyResponse: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable {
                        case json(Swift.String)
                        public var json: Swift.String {
                            get throws { switch self { case let .json(body): return body } }
                        }
                    }
                    public var body: Components.Responses.MyResponse.Body
                    public init(
                        body: Components.Responses.MyResponse.Body
                    ) {
                        self.body = body
                    }
                }
            }
            """
        )
    }

    func testRequestWithQueryItems() throws {
        try self.assertRequestInTypesClientServerTranslation(
            """
            /foo:
              get:
                parameters:
                  - name: single
                    in: query
                    schema:
                      type: string
                  - name: manyExploded
                    in: query
                    explode: true
                    schema:
                      type: array
                      items:
                        type: string
                  - name: manyUnexploded
                    in: query
                    explode: false
                    schema:
                      type: array
                      items:
                        type: string
                responses:
                  default:
                    description: Response
            """,
            types: """
                public struct Input: Sendable, Hashable {
                    public struct Query: Sendable, Hashable {
                        public var single: Swift.String?
                        public var manyExploded: [Swift.String]?
                        public var manyUnexploded: [Swift.String]?
                        public init(
                            single: Swift.String? = nil,
                            manyExploded: [Swift.String]? = nil,
                            manyUnexploded: [Swift.String]? = nil
                        ) {
                            self.single = single
                            self.manyExploded = manyExploded
                            self.manyUnexploded = manyUnexploded
                        }
                    }
                    public var query: Operations.get_sol_foo.Input.Query
                    public init(query: Operations.get_sol_foo.Input.Query = .init()) {
                        self.query = query
                    }
                }
                """,
            client: """
                { input in let path = try converter.renderedPath(template: "/foo", parameters: [])
                    var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .get)
                    suppressMutabilityWarning(&request)
                    try converter.setQueryItemAsURI(
                        in: &request,
                        style: .form,
                        explode: true,
                        name: "single",
                        value: input.query.single
                    )
                    try converter.setQueryItemAsURI(
                        in: &request,
                        style: .form,
                        explode: true,
                        name: "manyExploded",
                        value: input.query.manyExploded
                    )
                    try converter.setQueryItemAsURI(
                        in: &request,
                        style: .form,
                        explode: false,
                        name: "manyUnexploded",
                        value: input.query.manyUnexploded
                    )
                    return (request, nil)
                }
                """,
            server: """
                { request, requestBody, metadata in
                    let query: Operations.get_sol_foo.Input.Query = .init(
                        single: try converter.getOptionalQueryItemAsURI(
                            in: request.soar_query,
                            style: .form,
                            explode: true,
                            name: "single",
                            as: Swift.String.self
                        ),
                        manyExploded: try converter.getOptionalQueryItemAsURI(
                            in: request.soar_query,
                            style: .form,
                            explode: true,
                            name: "manyExploded",
                            as: [Swift.String].self
                        ),
                        manyUnexploded: try converter.getOptionalQueryItemAsURI(
                            in: request.soar_query,
                            style: .form,
                            explode: false,
                            name: "manyUnexploded",
                            as: [Swift.String].self
                        )
                    )
                    return Operations.get_sol_foo.Input(query: query)
                }
                """
        )
    }

    func testRequestRequiredBodyPrimitiveSchema() throws {
        try self.assertRequestInTypesClientServerTranslation(
            """
            /foo:
              get:
                requestBody:
                  required: true
                  content:
                    application/json:
                      schema:
                        type: string
                responses:
                  default:
                    description: Response
            """,
            types: """
                public struct Input: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable { case json(Swift.String) }
                    public var body: Operations.get_sol_foo.Input.Body
                    public init(body: Operations.get_sol_foo.Input.Body) { self.body = body }
                }
                """,
            client: """
                { input in let path = try converter.renderedPath(template: "/foo", parameters: [])
                    var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .get)
                    suppressMutabilityWarning(&request)
                    let body: OpenAPIRuntime.HTTPBody?
                    switch input.body {
                    case let .json(value):
                        body = try converter.setRequiredRequestBodyAsJSON(
                            value,
                            headerFields: &request.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (request, body)
                }
                """,
            server: """
                { request, requestBody, metadata in let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                    let body: Operations.get_sol_foo.Input.Body
                    if try contentType == nil || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                    {
                        body = try await converter.getRequiredRequestBodyAsJSON(
                            Swift.String.self,
                            from: requestBody,
                            transforming: { value in .json(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return Operations.get_sol_foo.Input(body: body)
                }
                """
        )
    }

    func testRequestRequiredBodyNullableSchema() throws {
        try self.assertRequestInTypesClientServerTranslation(
            """
            /foo:
              get:
                requestBody:
                  required: true
                  content:
                    application/json:
                      schema:
                        type: [string, null]
                responses:
                  default:
                    description: Response
            """,
            types: """
                public struct Input: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable { case json(Swift.String) }
                    public var body: Operations.get_sol_foo.Input.Body
                    public init(body: Operations.get_sol_foo.Input.Body) { self.body = body }
                }
                """,
            client: """
                { input in let path = try converter.renderedPath(template: "/foo", parameters: [])
                    var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .get)
                    suppressMutabilityWarning(&request)
                    let body: OpenAPIRuntime.HTTPBody?
                    switch input.body {
                    case let .json(value):
                        body = try converter.setRequiredRequestBodyAsJSON(
                            value,
                            headerFields: &request.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (request, body)
                }
                """,
            server: """
                { request, requestBody, metadata in let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                    let body: Operations.get_sol_foo.Input.Body
                    if try contentType == nil || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                    {
                        body = try await converter.getRequiredRequestBodyAsJSON(
                            Swift.String.self,
                            from: requestBody,
                            transforming: { value in .json(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return Operations.get_sol_foo.Input(body: body)
                }
                """
        )
    }

    func testRequestOptionalBodyPrimitiveSchema() throws {
        try self.assertRequestInTypesClientServerTranslation(
            """
            /foo:
              get:
                requestBody:
                  required: false
                  content:
                    application/json:
                      schema:
                        type: string
                responses:
                  default:
                    description: Response
            """,
            types: """
                public struct Input: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable { case json(Swift.String) }
                    public var body: Operations.get_sol_foo.Input.Body?
                    public init(body: Operations.get_sol_foo.Input.Body? = nil) { self.body = body }
                }
                """,
            client: """
                { input in let path = try converter.renderedPath(template: "/foo", parameters: [])
                    var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .get)
                    suppressMutabilityWarning(&request)
                    let body: OpenAPIRuntime.HTTPBody?
                    switch input.body {
                    case .none: body = nil
                    case let .json(value):
                        body = try converter.setOptionalRequestBodyAsJSON(
                            value,
                            headerFields: &request.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (request, body)
                }
                """,
            server: """
                { request, requestBody, metadata in let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                    let body: Operations.get_sol_foo.Input.Body?
                    if try contentType == nil || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                    {
                        body = try await converter.getOptionalRequestBodyAsJSON(
                            Swift.String.self,
                            from: requestBody,
                            transforming: { value in .json(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return Operations.get_sol_foo.Input(body: body)
                }
                """
        )
    }

    func testRequestOptionalBodyNullableSchema() throws {
        try self.assertRequestInTypesClientServerTranslation(
            """
            /foo:
              get:
                requestBody:
                  required: false
                  content:
                    application/json:
                      schema:
                        type: [string, null]
                responses:
                  default:
                    description: Response
            """,
            types: """
                public struct Input: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable { case json(Swift.String) }
                    public var body: Operations.get_sol_foo.Input.Body?
                    public init(body: Operations.get_sol_foo.Input.Body? = nil) { self.body = body }
                }
                """,
            client: """
                { input in let path = try converter.renderedPath(template: "/foo", parameters: [])
                    var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .get)
                    suppressMutabilityWarning(&request)
                    let body: OpenAPIRuntime.HTTPBody?
                    switch input.body {
                    case .none: body = nil
                    case let .json(value):
                        body = try converter.setOptionalRequestBodyAsJSON(
                            value,
                            headerFields: &request.headerFields,
                            contentType: "application/json; charset=utf-8"
                        )
                    }
                    return (request, body)
                }
                """,
            server: """
                { request, requestBody, metadata in let contentType = converter.extractContentTypeIfPresent(in: request.headerFields)
                    let body: Operations.get_sol_foo.Input.Body?
                    if try contentType == nil || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                    {
                        body = try await converter.getOptionalRequestBodyAsJSON(
                            Swift.String.self,
                            from: requestBody,
                            transforming: { value in .json(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return Operations.get_sol_foo.Input(body: body)
                }
                """
        )
    }

    func testResponseWithExampleWithOnlyValueByte() throws {
        try self.assertResponsesTranslation(
            featureFlags: [.base64DataEncodingDecoding],
            """
            responses:
              MyResponse:
                description: Some response
                content:
                  application/json:
                    schema:
                      type: string
                      format: byte
                    examples:
                      application/json:
                        summary: "a hello response"
            """,
            """
            public enum Responses {
                public struct MyResponse: Sendable, Hashable {
                    @frozen public enum Body: Sendable, Hashable {
                        case json(OpenAPIRuntime.Base64EncodedData)
                        public var json: OpenAPIRuntime.Base64EncodedData {
                            get throws {
                                switch self { case let .json(body): return body }
                            }
                        }
                    }
                    public var body: Components.Responses.MyResponse.Body
                    public init(
                        body: Components.Responses.MyResponse.Body
                    ) {
                        self.body = body
                    }
                }
            }
            """
        )
    }

}

extension SnippetBasedReferenceTests {
    func makeTypesTranslator(openAPIDocumentYAML: String) throws -> TypesFileTranslator {
        let document = try YAMLDecoder().decode(OpenAPI.Document.self, from: openAPIDocumentYAML)
        return TypesFileTranslator(
            config: Config(mode: .types),
            diagnostics: XCTestDiagnosticCollector(test: self),
            components: document.components
        )
    }

    func makeTypesTranslator(
        featureFlags: FeatureFlags = [],
        ignoredDiagnosticMessages: Set<String> = [],
        componentsYAML: String
    ) throws -> TypesFileTranslator {
        let components = try YAMLDecoder().decode(OpenAPI.Components.self, from: componentsYAML)
        return TypesFileTranslator(
            config: Config(mode: .types, featureFlags: featureFlags),
            diagnostics: XCTestDiagnosticCollector(test: self, ignoredDiagnosticMessages: ignoredDiagnosticMessages),
            components: components
        )
    }

    func makeTranslators(
        components: OpenAPI.Components = .noComponents,
        featureFlags: FeatureFlags = [],
        ignoredDiagnosticMessages: Set<String> = []
    ) throws -> (TypesFileTranslator, ClientFileTranslator, ServerFileTranslator) {
        let collector = XCTestDiagnosticCollector(test: self, ignoredDiagnosticMessages: ignoredDiagnosticMessages)
        return (
            TypesFileTranslator(
                config: Config(mode: .types, featureFlags: featureFlags),
                diagnostics: collector,
                components: components
            ),
            ClientFileTranslator(
                config: Config(mode: .client, featureFlags: featureFlags),
                diagnostics: collector,
                components: components
            ),
            ServerFileTranslator(
                config: Config(mode: .server, featureFlags: featureFlags),
                diagnostics: collector,
                components: components
            )
        )
    }

    func assertHeadersTranslation(
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(componentsYAML: componentsYAML)
        let translation = try translator.translateComponentHeaders(translator.components.headers)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertParametersTranslation(
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(componentsYAML: componentsYAML)
        let translation = try translator.translateComponentParameters(translator.components.parameters)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertRequestInTypesClientServerTranslation(
        _ pathsYAML: String,
        _ componentsYAML: String? = nil,
        types expectedTypesSwift: String,
        client expectedClientSwift: String,
        server expectedServerSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        continueAfterFailure = false
        let (types, client, server) = try makeTranslators()
        let components =
            try componentsYAML.flatMap { componentsYAML in
                try YAMLDecoder().decode(OpenAPI.Components.self, from: componentsYAML)
            } ?? OpenAPI.Components.noComponents
        let paths = try YAMLDecoder().decode(OpenAPI.PathItem.Map.self, from: pathsYAML)
        let document = OpenAPI.Document(
            openAPIVersion: .v3_1_0,
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: paths,
            components: components
        )
        let operationDescriptions = try OperationDescription.all(
            from: document.paths,
            in: document.components,
            asSwiftSafeName: types.swiftSafeName
        )
        let operation = try XCTUnwrap(operationDescriptions.first)
        let generatedTypesStructuredSwift = try types.translateOperationInput(operation)
        try XCTAssertSwiftEquivalent(generatedTypesStructuredSwift, expectedTypesSwift, file: file, line: line)

        let generatedClientStructuredSwift = try client.translateClientSerializer(operation)
        try XCTAssertSwiftEquivalent(generatedClientStructuredSwift, expectedClientSwift, file: file, line: line)

        let generatedServerStructuredSwift = try server.translateServerDeserializer(operation)
        try XCTAssertSwiftEquivalent(generatedServerStructuredSwift, expectedServerSwift, file: file, line: line)
    }

    func assertSchemasTranslation(
        featureFlags: FeatureFlags = [],
        ignoredDiagnosticMessages: Set<String> = [],
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(
            featureFlags: featureFlags,
            ignoredDiagnosticMessages: ignoredDiagnosticMessages,
            componentsYAML: componentsYAML
        )
        let translation = try translator.translateSchemas(translator.components.schemas)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertResponsesTranslation(
        featureFlags: FeatureFlags = [],
        ignoredDiagnosticMessages: Set<String> = [],
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(
            featureFlags: featureFlags,
            ignoredDiagnosticMessages: ignoredDiagnosticMessages,
            componentsYAML: componentsYAML
        )
        let translation = try translator.translateComponentResponses(translator.components.responses)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertRequestBodiesTranslation(
        featureFlags: FeatureFlags = [],
        ignoredDiagnosticMessages: Set<String> = [],
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(
            featureFlags: featureFlags,
            ignoredDiagnosticMessages: ignoredDiagnosticMessages,
            componentsYAML: componentsYAML
        )
        let translation = try translator.translateComponentRequestBodies(translator.components.requestBodies)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertPathsTranslation(
        _ pathsYAML: String,
        componentsYAML: String = "{}",
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(componentsYAML: componentsYAML)
        let paths = try YAMLDecoder().decode(OpenAPI.PathItem.Map.self, from: pathsYAML)
        let translation = try translator.translateAPIProtocol(paths)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertPathsTranslationExtension(
        _ pathsYAML: String,
        componentsYAML: String = "{}",
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(componentsYAML: componentsYAML)
        let paths = try YAMLDecoder().decode(OpenAPI.PathItem.Map.self, from: pathsYAML)
        let translation = try translator.translateAPIProtocolExtension(paths)
        try XCTAssertSwiftEquivalent(translation, expectedSwift, file: file, line: line)
    }

    func assertServerRegisterHandlers(
        _ pathsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let (_, _, translator) = try makeTranslators()
        let paths = try YAMLDecoder().decode(OpenAPI.PathItem.Map.self, from: pathsYAML)
        let operations = try OperationDescription.all(
            from: paths,
            in: .noComponents,
            asSwiftSafeName: translator.swiftSafeName
        )
        let (registerHandlersDecl, _) = try translator.translateRegisterHandlers(operations)
        try XCTAssertSwiftEquivalent(registerHandlersDecl, expectedSwift, file: file, line: line)
    }
}

private func XCTAssertEqualWithDiff(
    _ actual: String,
    _ expected: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    if actual == expected { return }
    XCTFail(
        """
        XCTAssertEqualWithDiff failed (click for diff)
        \(try diff(expected: expected, actual: actual))
        """,
        file: file,
        line: line
    )
}

private func XCTAssertSwiftEquivalent(
    _ declaration: Declaration,
    _ expectedSwift: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try XCTAssertEqualWithDiff(
        TextBasedRenderer().renderedDeclaration(declaration.strippingComments).swiftFormatted,
        expectedSwift.swiftFormatted,
        file: file,
        line: line
    )
}

private func XCTAssertSwiftEquivalent(
    _ codeBlock: CodeBlock,
    _ expectedSwift: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try XCTAssertEqualWithDiff(
        TextBasedRenderer().renderedCodeBlock(codeBlock).swiftFormatted,
        expectedSwift.swiftFormatted,
        file: file,
        line: line
    )
}

private func XCTAssertSwiftEquivalent(
    _ expression: Expression,
    _ expectedSwift: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try XCTAssertEqualWithDiff(
        TextBasedRenderer().renderedExpression(expression).swiftFormatted,
        expectedSwift.swiftFormatted,
        file: file,
        line: line
    )
}

private func diff(expected: String, actual: String) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
        "bash", "-c",
        "diff -U5 --label=expected <(echo '\(expected)') --label=actual <(echo '\(actual)')",
    ]
    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    process.waitUntilExit()
    let pipeData = try XCTUnwrap(
        pipe.fileHandleForReading.readToEnd(),
        """
        No output from command:
        \(process.executableURL!.path) \(process.arguments!.joined(separator: " "))
        """
    )
    return String(decoding: pipeData, as: UTF8.self)
}

fileprivate extension Declaration {
    var strippingComments: Self { stripComments(self) }

    func stripComments(_ decl: Declaration) -> Declaration {
        switch decl {
        case let .commentable(_, d):
            return stripComments(d)
        case let .deprecated(a, b):
            return .deprecated(a, stripComments(b))
        case var .protocol(p):
            p.members = p.members.map(stripComments(_:))
            return .protocol(p)
        case var .function(f):
            f.body = f.body?.map(stripComments(_:))
            return .function(f)
        case var .extension(e):
            e.declarations = e.declarations.map(stripComments(_:))
            return .extension(e)
        case var .struct(s):
            s.members = s.members.map(stripComments(_:))
            return .struct(s)
        case var .enum(e):
            e.members = e.members.map(stripComments(_:))
            return .enum(e)
        case var .variable(v):
            v.getter = stripComments(v.getter)
            return .variable(v)
        case let .typealias(t):
            return .typealias(t)
        case let .enumCase(e):
            return .enumCase(e)
        }
    }

    func stripComments(_ body: [CodeBlock]?) -> [CodeBlock]? {
        body.map(stripComments(_:))
    }

    func stripComments(_ body: [CodeBlock]) -> [CodeBlock] {
        body.map(stripComments(_:))
    }

    func stripComments(_ codeBlock: CodeBlock) -> CodeBlock {
        CodeBlock(comment: nil, item: stripComments(codeBlock.item))
    }

    func stripComments(_ codeBlockItem: CodeBlockItem) -> CodeBlockItem {
        switch codeBlockItem {
        case let .declaration(d): return .declaration(stripComments(d))
        case .expression: return codeBlockItem
        }
    }
}
