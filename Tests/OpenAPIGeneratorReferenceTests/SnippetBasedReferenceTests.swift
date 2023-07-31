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
            """,
            """
            public enum Schemas {
                public typealias A = OpenAPIRuntime.OpenAPIValueContainer
                public typealias B = OpenAPIRuntime.OpenAPIValueContainer
                public struct MyAllOf: Codable, Equatable, Hashable, Sendable {
                    public var value1: Components.Schemas.A
                    public var value2: Components.Schemas.B
                    public init(
                        value1: Components.Schemas.A,
                        value2: Components.Schemas.B
                    ) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                    public init(from decoder: any Decoder) throws {
                        value1 = try .init(from: decoder)
                        value2 = try .init(from: decoder)
                    }
                    public func encode(to encoder: any Encoder) throws {
                        try value1.encode(to: encoder)
                        try value2.encode(to: encoder)
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
            """,
            """
            public enum Schemas {
                public typealias A = OpenAPIRuntime.OpenAPIValueContainer
                public typealias B = OpenAPIRuntime.OpenAPIValueContainer
                public struct MyAnyOf: Codable, Equatable, Hashable, Sendable {
                    public var value1: Components.Schemas.A?
                    public var value2: Components.Schemas.B?
                    public init(
                        value1: Components.Schemas.A? = nil,
                        value2: Components.Schemas.B? = nil
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

    func assertSchemasTranslation(
        _ componentsYAML: String,
        _ expectedSwift: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let translator = try makeTypesTranslator(componentsYAML: componentsYAML)
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
