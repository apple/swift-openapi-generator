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

    func testComponentsSchemasObject() throws {
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
                    public init(from decoder: Decoder) throws {
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

    func makeTypesTranslator(componentsYAML: String) throws -> TypesFileTranslator {
        let components = try YAMLDecoder().decode(OpenAPI.Components.self, from: componentsYAML)
        return TypesFileTranslator(
            config: Config(mode: .types),
            diagnostics: XCTestDiagnosticCollector(test: self),
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
