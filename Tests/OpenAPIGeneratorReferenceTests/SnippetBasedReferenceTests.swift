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
import OpenAPIKit30
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
                public struct MyObject: Codable, Equatable, Hashable, Sendable {
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
                public struct MyObject: Codable, Equatable, Hashable, Sendable {
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
                public struct MyObject: Codable, Equatable, Hashable, Sendable {
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
              MyObject:
                type: object
                properties:
                  id:
                    type: integer
                    format: int64
                  alias:
                    type: string
                required:
                  - id
            """,
            """
                public enum Schemas {
                  public struct MyObject: Codable, Equatable, Hashable, Sendable {
                    public var id: Swift.Int64
                    public var alias: Swift.String?
                    public init(id: Swift.Int64, alias: Swift.String? = nil) {
                        self.id = id
                        self.alias = alias
                    }
                    public enum CodingKeys: String, CodingKey {
                        case id
                        case alias
                    }
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
                public struct MyAllOf: Codable, Equatable, Hashable, Sendable {
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
                        value3 = try .init(from: decoder)
                        value4 = try .init(from: decoder)
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try value1.encode(to: encoder)
                        try value2.encode(to: encoder)
                        try value3.encode(to: encoder)
                        try value4.encode(to: encoder)
                    }
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
                public struct MyAnyOf: Codable, Equatable, Hashable, Sendable {
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
                        value3 = try? .init(from: decoder)
                        value4 = try? .init(from: decoder)
                        try DecodingError.verifyAtLeastOneSchemaIsNotNil(
                            [value1, value2, value3, value4],
                            type: Self.self,
                            codingPath: decoder.codingPath
                        )
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try value1?.encode(to: encoder)
                        try value2?.encode(to: encoder)
                        try value3?.encode(to: encoder)
                        try value4?.encode(to: encoder)
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasOneOf() throws {
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
                @frozen public enum MyOneOf: Codable, Equatable, Hashable, Sendable {
                    case case1(Swift.String)
                    case case2(Swift.Int)
                    case A(Components.Schemas.A)
                    case undocumented(OpenAPIRuntime.OpenAPIValueContainer)
                    public init(from decoder: any Decoder) throws {
                        do {
                            self = .case1(try .init(from: decoder))
                            return
                        } catch {}
                        do {
                            self = .case2(try .init(from: decoder))
                            return
                        } catch {}
                        do {
                            self = .A(try .init(from: decoder))
                            return
                        } catch {}
                        let container = try decoder.singleValueContainer()
                        let value = try container.decode(OpenAPIRuntime.OpenAPIValueContainer.self)
                        self = .undocumented(value)
                    }
                    public func encode(to encoder: any Encoder) throws {
                        switch self {
                        case let .case1(value): try value.encode(to: encoder)
                        case let .case2(value): try value.encode(to: encoder)
                        case let .A(value): try value.encode(to: encoder)
                        case let .undocumented(value): try value.encode(to: encoder)
                        }
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
                  mapping:
                    a: '#/components/schemas/A'
                    b: '#/components/schemas/B'
            """,
            """
            public enum Schemas {
                public struct A: Codable, Equatable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                public struct B: Codable, Equatable, Hashable, Sendable {
                    public var which: Swift.String?
                    public init(which: Swift.String? = nil) { self.which = which }
                    public enum CodingKeys: String, CodingKey { case which }
                }
                @frozen public enum MyOneOf: Codable, Equatable, Hashable, Sendable {
                    case A(Components.Schemas.A)
                    case B(Components.Schemas.B)
                    case undocumented(OpenAPIRuntime.OpenAPIObjectContainer)
                    public enum CodingKeys: String, CodingKey { case which }
                    public init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let discriminator = try container.decode(String.self, forKey: .which)
                        switch discriminator {
                        case "a": self = .A(try .init(from: decoder))
                        case "b": self = .B(try .init(from: decoder))
                        default:
                            let container = try decoder.singleValueContainer()
                            let value = try container.decode(OpenAPIRuntime.OpenAPIObjectContainer.self)
                            self = .undocumented(value)
                        }
                    }
                    public func encode(to encoder: any Encoder) throws {
                        switch self {
                        case let .A(value): try value.encode(to: encoder)
                        case let .B(value): try value.encode(to: encoder)
                        case let .undocumented(value): try value.encode(to: encoder)
                        }
                    }
                }
            }
            """
        )
    }

    func testComponentsSchemasOneOf_closed() throws {
        try self.assertSchemasTranslation(
            featureFlags: [.closedEnumsAndOneOfs],
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
                @frozen public enum MyOneOf: Codable, Equatable, Hashable, Sendable {
                    case case1(Swift.String)
                    case case2(Swift.Int)
                    case A(Components.Schemas.A)
                    public init(from decoder: any Decoder) throws {
                        do {
                            self = .case1(try .init(from: decoder))
                            return
                        } catch {}
                        do {
                            self = .case2(try .init(from: decoder))
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
                        case let .case1(value): try value.encode(to: encoder)
                        case let .case2(value): try value.encode(to: encoder)
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
            featureFlags: [.closedEnumsAndOneOfs],
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
                public struct A: Codable, Equatable, Hashable, Sendable {
                    public init() {}
                    public init(from decoder: any Decoder) throws {
                        try decoder.ensureNoAdditionalProperties(knownKeys: [])
                    }
                }
                public struct MyOpenOneOf: Codable, Equatable, Hashable, Sendable {
                    @frozen public enum Value1Payload: Codable, Equatable, Hashable, Sendable {
                        case case1(Swift.String)
                        case case2(Swift.Int)
                        case A(Components.Schemas.A)
                        public init(from decoder: any Decoder) throws {
                            do {
                                self = .case1(try .init(from: decoder))
                                return
                            } catch {}
                            do {
                                self = .case2(try .init(from: decoder))
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
                            case let .case1(value): try value.encode(to: encoder)
                            case let .case2(value): try value.encode(to: encoder)
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
                public struct MyAllOf: Codable, Equatable, Hashable, Sendable {
                    public var value1: Components.Schemas.A
                    public init(value1: Components.Schemas.A) {
                        self.value1 = value1
                    }
                    public init(from decoder: any Decoder) throws {
                        value1 = try .init(from: decoder)
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try value1.encode(to: encoder)
                    }
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
                public struct B: Codable, Equatable, Hashable, Sendable {
                    public struct cPayload: Codable, Equatable, Hashable, Sendable {
                        public var value1: Components.Schemas.A
                        public init(value1: Components.Schemas.A) { self.value1 = value1 }
                        public init(from decoder: any Decoder) throws { value1 = try .init(from: decoder) }
                        public func encode(to encoder: any Encoder) throws { try value1.encode(to: encoder) }
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
                public struct B: Codable, Equatable, Hashable, Sendable {
                    public struct cPayload: Codable, Equatable, Hashable, Sendable {
                        public var value1: Components.Schemas.A
                        public init(value1: Components.Schemas.A) { self.value1 = value1 }
                        public init(from decoder: any Decoder) throws { value1 = try .init(from: decoder) }
                        public func encode(to encoder: any Encoder) throws { try value1.encode(to: encoder) }
                    }
                    public var c: Components.Schemas.B.cPayload?
                    public init(c: Components.Schemas.B.cPayload? = nil) { self.c = c }
                    public enum CodingKeys: String, CodingKey { case c }
                }
            }
            """
        )
    }

    func testComponentsSchemasEnum() throws {
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
                @frozen
                public enum MyEnum: RawRepresentable, Codable, Equatable, Hashable, Sendable,
                    _AutoLosslessStringConvertible, CaseIterable
                {
                    case one
                    case _empty
                    case _tart
                    case _public
                    case undocumented(String)
                    public init?(rawValue: String) {
                        switch rawValue {
                            case "one": self = .one
                            case "": self = ._empty
                            case "$tart": self = ._tart
                            case "public": self = ._public
                            default: self = .undocumented(rawValue)
                        }
                    }
                    public var rawValue: String {
                        switch self {
                            case let .undocumented(string): return string
                            case .one: return "one"
                            case ._empty: return ""
                            case ._tart: return "$tart"
                            case ._public: return "public"
                        }
                    }
                    public static var allCases: [MyEnum] { [.one, ._empty, ._tart, ._public] }
                }
            }
            """
        )
    }

    func testComponentsSchemasEnum_closed() throws {
        try self.assertSchemasTranslation(
            featureFlags: [.closedEnumsAndOneOfs],
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
                @frozen
                public enum MyEnum: String, Codable, Equatable, Hashable, Sendable,
                    _AutoLosslessStringConvertible, CaseIterable
                {
                    case one = "one"
                    case _empty = ""
                    case _tart = "$tart"
                    case _public = "public"
                }
            }
            """
        )
    }

    func testComponentsSchemasEnum_open_pattern() throws {
        try self.assertSchemasTranslation(
            featureFlags: [.closedEnumsAndOneOfs],
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
                public struct MyOpenEnum: Codable, Equatable, Hashable, Sendable {
                    @frozen
                    public enum Value1Payload: String, Codable, Equatable, Hashable, Sendable,
                        _AutoLosslessStringConvertible, CaseIterable
                    {
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
                public struct MyObject: Codable, Equatable, Hashable, Sendable {
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
                public struct MyObject: Codable, Equatable, Hashable, Sendable {
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

    func testComponentsResponsesResponseNoBody() throws {
        try self.assertResponsesTranslation(
            """
            responses:
              BadRequest:
                description: Bad request
            """,
            """
            public enum Responses {
                public struct BadRequest: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                    public var headers: Components.Responses.BadRequest.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {}
                    public var body: Components.Responses.BadRequest.Body?
                    public init(
                        headers: Components.Responses.BadRequest.Headers = .init(),
                        body: Components.Responses.BadRequest.Body? = nil
                    ) {
                        self.headers = headers
                        self.body = body
                    }
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
                public struct BadRequest: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                    public var headers: Components.Responses.BadRequest.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {
                        case json(Swift.String)
                    }
                    public var body: Components.Responses.BadRequest.Body
                    public init(
                        headers: Components.Responses.BadRequest.Headers = .init(),
                        body: Components.Responses.BadRequest.Body
                    ) {
                        self.headers = headers
                        self.body = body
                    }
                }
            }
            """
        )
    }

    func testComponentsResponsesResponseMultipleContentTypes() throws {
        try self.assertResponsesTranslation(
            featureFlags: [],
            ignoredDiagnosticMessages: [#"Feature "Multiple content types" is not supported, skipping"#],
            """
            responses:
              MultipleContentTypes:
                description: Multiple content types
                content:
                  application/json:
                    schema:
                      type: integer
                  text/plain: {}
                  application/octet-stream: {}
            """,
            """
            public enum Responses {
                public struct MultipleContentTypes: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                    public var headers: Components.Responses.MultipleContentTypes.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {
                        case json(Swift.Int)
                    }
                    public var body: Components.Responses.MultipleContentTypes.Body
                    public init(
                        headers: Components.Responses.MultipleContentTypes.Headers = .init(),
                        body: Components.Responses.MultipleContentTypes.Body
                    ) {
                        self.headers = headers
                        self.body = body
                    }
                }
            }
            """
        )
        try self.assertResponsesTranslation(
            featureFlags: [
                .multipleContentTypes,
                .proposal0001,
            ],
            """
            responses:
              MultipleContentTypes:
                description: Multiple content types
                content:
                  application/json:
                    schema:
                      type: integer
                  text/plain: {}
                  application/octet-stream: {}
            """,
            """
            public enum Responses {
                public struct MultipleContentTypes: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                    public var headers: Components.Responses.MultipleContentTypes.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {
                        case json(Swift.Int)
                        case plainText(Swift.String)
                        case binary(Foundation.Data)
                    }
                    public var body: Components.Responses.MultipleContentTypes.Body
                    public init(
                        headers: Components.Responses.MultipleContentTypes.Headers = .init(),
                        body: Components.Responses.MultipleContentTypes.Body
                    ) {
                        self.headers = headers
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
                public struct BadRequest: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable {
                        public var X_Reason: Swift.String?
                        public init(X_Reason: Swift.String? = nil) {
                            self.X_Reason = X_Reason }
                    }
                    public var headers: Components.Responses.BadRequest.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {}
                    public var body: Components.Responses.BadRequest.Body?
                    public init(
                        headers: Components.Responses.BadRequest.Headers = .init(),
                        body: Components.Responses.BadRequest.Body? = nil
                    ) {
                        self.headers = headers
                        self.body = body
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
                public struct BadRequest: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable {
                        public var X_Reason: Swift.String
                        public init(X_Reason: Swift.String) {
                            self.X_Reason = X_Reason }
                    }
                    public var headers: Components.Responses.BadRequest.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {}
                    public var body: Components.Responses.BadRequest.Body?
                    public init(
                        headers: Components.Responses.BadRequest.Headers,
                        body: Components.Responses.BadRequest.Body? = nil
                    ) {
                        self.headers = headers
                        self.body = body
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
                @frozen public enum MyResponseBody: Sendable, Equatable, Hashable {
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
                @frozen public enum MyResponseBody: Sendable, Equatable, Hashable {
                    case json(Components.Schemas.MyBody)
                }
            }
            """
        )
    }

    func testComponentsRequestBodiesMultipleContentTypes() throws {
        try self.assertRequestBodiesTranslation(
            featureFlags: [],
            ignoredDiagnosticMessages: [#"Feature "Multiple content types" is not supported, skipping"#],
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
                @frozen public enum MyResponseBody: Sendable, Equatable, Hashable {
                    case json(Components.Schemas.MyBody)
                }
            }
            """
        )
        try self.assertRequestBodiesTranslation(
            featureFlags: [
                .multipleContentTypes,
                .proposal0001,
            ],
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
                @frozen public enum MyResponseBody: Sendable, Equatable, Hashable {
                    case json(Components.Schemas.MyBody)
                    case plainText(Swift.String)
                    case binary(Foundation.Data)
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
                    { try await server.getHealth(request: $0, metadata: $1) },
                    method: .get,
                    path: server.apiPathComponentsWithServerPrefix(["health"]),
                    queryItemNames: []
                )
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
                public struct MyResponse: Sendable, Equatable, Hashable {
                    public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                    public var headers: Components.Responses.MyResponse.Headers
                    @frozen public enum Body: Sendable, Equatable, Hashable {
                        case json(Swift.String)
                    }
                    public var body: Components.Responses.MyResponse.Body
                    public init(
                        headers: Components.Responses.MyResponse.Headers = .init(),
                        body: Components.Responses.MyResponse.Body
                    ) {
                        self.headers = headers
                        self.body = body
                    }
                }
            }
            """
        )
    }

    func testResponseWithExampleWithOnlyValue() throws {
        // This test currently throws because the parsing of ExampleObject is too strict:
        // https://github.com/mattpolzin/OpenAPIKit/issues/286.
        XCTAssertThrowsError(
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
                    public struct MyResponse: Sendable, Equatable, Hashable {
                        public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                        public var headers: Components.Responses.MyResponse.Headers
                        @frozen public enum Body: Sendable, Equatable, Hashable {
                            case json(Swift.String)
                        }
                        public var body: Components.Responses.MyResponse.Body
                        public init(
                            headers: Components.Responses.MyResponse.Headers = .init(),
                            body: Components.Responses.MyResponse.Body
                        ) {
                            self.headers = headers
                            self.body = body
                        }
                    }
                }
                """
            )
        ) { error in
            XCTAssert(error is DecodingError)
        }
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
                public struct Input: Sendable, Equatable, Hashable {
                    public struct Path: Sendable, Equatable, Hashable { public init() {} }
                    public var path: Operations.get_foo.Input.Path
                    public struct Query: Sendable, Equatable, Hashable {
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
                    public var query: Operations.get_foo.Input.Query
                    public struct Headers: Sendable, Equatable, Hashable { public init() {} }
                    public var headers: Operations.get_foo.Input.Headers
                    public struct Cookies: Sendable, Equatable, Hashable { public init() {} }
                    public var cookies: Operations.get_foo.Input.Cookies
                    @frozen public enum Body: Sendable, Equatable, Hashable {}
                    public var body: Operations.get_foo.Input.Body?
                    public init(
                        path: Operations.get_foo.Input.Path = .init(),
                        query: Operations.get_foo.Input.Query = .init(),
                        headers: Operations.get_foo.Input.Headers = .init(),
                        cookies: Operations.get_foo.Input.Cookies = .init(),
                        body: Operations.get_foo.Input.Body? = nil
                    ) {
                        self.path = path
                        self.query = query
                        self.headers = headers
                        self.cookies = cookies
                        self.body = body
                    }
                }
                """,
            client: """
                { input in let path = try converter.renderedRequestPath(template: "/foo", parameters: [])
                    var request: OpenAPIRuntime.Request = .init(path: path, method: .get)
                    suppressMutabilityWarning(&request)
                    try converter.setQueryItemAsText(
                        in: &request,
                        style: .form,
                        explode: true,
                        name: "single",
                        value: input.query.single
                    )
                    try converter.setQueryItemAsText(
                        in: &request,
                        style: .form,
                        explode: true,
                        name: "manyExploded",
                        value: input.query.manyExploded
                    )
                    try converter.setQueryItemAsText(
                        in: &request,
                        style: .form,
                        explode: false,
                        name: "manyUnexploded",
                        value: input.query.manyUnexploded
                    )
                    return request
                }
                """,
            server: """
                { request, metadata in let path: Operations.get_foo.Input.Path = .init()
                    let query: Operations.get_foo.Input.Query = .init(
                        single: try converter.getOptionalQueryItemAsText(
                            in: metadata.queryParameters,
                            style: .form,
                            explode: true,
                            name: "single",
                            as: Swift.String.self
                        ),
                        manyExploded: try converter.getOptionalQueryItemAsText(
                            in: metadata.queryParameters,
                            style: .form,
                            explode: true,
                            name: "manyExploded",
                            as: [Swift.String].self
                        ),
                        manyUnexploded: try converter.getOptionalQueryItemAsText(
                            in: metadata.queryParameters,
                            style: .form,
                            explode: false,
                            name: "manyUnexploded",
                            as: [Swift.String].self
                        )
                    )
                    let headers: Operations.get_foo.Input.Headers = .init()
                    let cookies: Operations.get_foo.Input.Cookies = .init()
                    return Operations.get_foo.Input(
                        path: path,
                        query: query,
                        headers: headers,
                        cookies: cookies,
                        body: nil
                    )
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
            openAPIVersion: .v3_0_3,
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
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(
            featureFlags: featureFlags,
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
            v.body = stripComments(v.body)
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
