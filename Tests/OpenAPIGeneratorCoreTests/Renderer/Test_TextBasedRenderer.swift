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
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_TextBasedRenderer: XCTestCase {

    var renderer = TextBasedRenderer()

    func testComment() throws {
        try _test(
            .inline(
                #"""
                Generated by foo

                Also, bar
                """#
            ),
            renderedBy: renderer.renderedComment,
            rendersAs:
                #"""
                // Generated by foo
                //
                // Also, bar
                """#
        )
        try _test(
            .doc(
                #"""
                Generated by foo

                Also, bar
                """#
            ),
            renderedBy: renderer.renderedComment,
            rendersAs:
                #"""
                /// Generated by foo
                ///
                /// Also, bar
                """#
        )
        try _test(
            .mark("Lorem ipsum", sectionBreak: false),
            renderedBy: renderer.renderedComment,
            rendersAs:
                #"""
                // MARK: Lorem ipsum
                """#
        )
        try _test(
            .mark("Lorem ipsum", sectionBreak: true),
            renderedBy: renderer.renderedComment,
            rendersAs:
                #"""
                // MARK: - Lorem ipsum
                """#
        )
        try _test(
            .inline(
                """
                Generated by foo\r\nAlso, bar
                """
            ),
            renderedBy: renderer.renderedComment,
            rendersAs:
                #"""
                // Generated by foo
                //
                // Also, bar
                """#
        )
    }

    func testImports() throws {
        try _test(
            nil,
            renderedBy: renderer.renderedImports,
            rendersAs:
                ""
        )
        try _test(
            [
                ImportDescription(moduleName: "Foo"),
                ImportDescription(moduleName: "Bar"),
            ],
            renderedBy: renderer.renderedImports,
            rendersAs:
                #"""
                import Foo
                import Bar
                """#
        )
        try _test(
            [
                ImportDescription(moduleName: "Foo", spi: "Secret")
            ],
            renderedBy: renderer.renderedImports,
            rendersAs:
                #"""
                @_spi(Secret) import Foo
                """#
        )
        try _test(
            [
                ImportDescription(moduleName: "Foo", preconcurrency: .onOS(["Bar", "Baz"]))
            ],
            renderedBy: renderer.renderedImports,
            rendersAs:
                #"""
                #if os(Bar) || os(Baz)
                @preconcurrency import Foo
                #else
                import Foo
                #endif
                """#
        )
        try _test(
            [
                ImportDescription(moduleName: "Foo", preconcurrency: .always),
                ImportDescription(moduleName: "Bar", spi: "Secret", preconcurrency: .always),
            ],
            renderedBy: renderer.renderedImports,
            rendersAs:
                #"""
                @preconcurrency import Foo
                @preconcurrency @_spi(Secret) import Bar
                """#
        )
    }

    func testAccessModifiers() throws {
        try _test(
            .public,
            renderedBy: renderer.renderedAccessModifier,
            rendersAs:
                #"""
                public
                """#,
            normalizing: false
        )
        try _test(
            .internal,
            renderedBy: renderer.renderedAccessModifier,
            rendersAs:
                #"""
                internal
                """#,
            normalizing: false
        )
        try _test(
            .fileprivate,
            renderedBy: renderer.renderedAccessModifier,
            rendersAs:
                #"""
                fileprivate
                """#,
            normalizing: false
        )
        try _test(
            .private,
            renderedBy: renderer.renderedAccessModifier,
            rendersAs:
                #"""
                private
                """#,
            normalizing: false
        )
    }

    func testLiterals() throws {
        try _test(
            .string("hi"),
            renderedBy: renderer.renderedLiteral,
            rendersAs:
                #"""
                "hi"
                """#
        )
        try _test(
            .nil,
            renderedBy: renderer.renderedLiteral,
            rendersAs:
                #"""
                nil
                """#
        )
        try _test(
            .array([]),
            renderedBy: renderer.renderedLiteral,
            rendersAs:
                #"""
                []
                """#
        )
        try _test(
            .array([
                .literal(.nil)
            ]),
            renderedBy: renderer.renderedLiteral,
            rendersAs:
                #"""
                [nil]
                """#
        )
        try _test(
            .array([
                .literal(.nil),
                .literal(.nil),
            ]),
            renderedBy: renderer.renderedLiteral,
            rendersAs:
                #"""
                [nil, nil]
                """#
        )
    }

    func testExpression() throws {
        try _test(
            .literal(.nil),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                nil
                """#
        )
        try _test(
            .identifier("foo"),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                foo
                """#
        )
        try _test(
            .memberAccess(
                .init(
                    left: .identifier("foo"),
                    right: "bar"
                )
            ),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                foo.bar
                """#
        )
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifier("callee"),
                    arguments: [
                        .init(
                            label: nil,
                            expression: .identifier("foo")
                        )
                    ]
                )
            ),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                callee(foo)
                """#
        )
    }

    func testDeclaration() throws {
        try _test(
            .variable(.init(kind: .let, left: "foo")),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                let foo
                """#
        )
        try _test(
            .extension(
                .init(
                    onType: "String",
                    declarations: []
                )
            ),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                extension String {
                }
                """#
        )
        try _test(
            .struct(.init(name: "Foo")),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                struct Foo { }
                """#
        )
        try _test(
            .protocol(.init(name: "Foo")),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                protocol Foo { }
                """#
        )
        try _test(
            .enum(.init(name: "Foo")),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                enum Foo {}
                """#
        )
        try _test(
            .typealias(.init(name: "foo", existingType: "bar")),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                typealias foo = bar
                """#
        )
        try _test(
            .function(
                FunctionDescription.init(
                    kind: .function(name: "foo"),
                    body: []
                )
            ),
            renderedBy: renderer.renderedDeclaration,
            rendersAs:
                #"""
                func foo() {}
                """#
        )
    }

    func testFunctionKind() throws {
        try _test(
            .initializer,
            renderedBy: renderer.renderedFunctionKind,
            rendersAs:
                #"""
                init
                """#,
            normalizing: false
        )
        try _test(
            .function(name: "funky"),
            renderedBy: renderer.renderedFunctionKind,
            rendersAs:
                #"""
                func funky
                """#,
            normalizing: false
        )
        try _test(
            .function(name: "funky", isStatic: true),
            renderedBy: renderer.renderedFunctionKind,
            rendersAs:
                #"""
                static func funky
                """#,
            normalizing: false
        )
    }

    func testFunctionKeyword() throws {
        try _test(
            .throws,
            renderedBy: renderer.renderedFunctionKeyword,
            rendersAs:
                #"""
                throws
                """#,
            normalizing: false
        )
        try _test(
            .async,
            renderedBy: renderer.renderedFunctionKeyword,
            rendersAs:
                #"""
                async
                """#,
            normalizing: false
        )
    }

    func testParameter() throws {
        try _test(
            .init(
                label: "l",
                name: "n",
                type: "T",
                defaultValue: .literal(.nil)
            ),
            renderedBy: renderer.renderedParameter,
            rendersAs:
                #"""
                l n : T = nil
                """#,
            normalizing: false
        )
        try _test(
            .init(
                label: nil,
                name: "n",
                type: "T",
                defaultValue: .literal(.nil)
            ),
            renderedBy: renderer.renderedParameter,
            rendersAs:
                #"""
                _ n : T = nil
                """#,
            normalizing: false
        )
        try _test(
            .init(
                label: "l",
                name: nil,
                type: "T",
                defaultValue: .literal(.nil)
            ),
            renderedBy: renderer.renderedParameter,
            rendersAs:
                #"""
                l : T = nil
                """#,
            normalizing: false
        )
        try _test(
            .init(
                label: nil,
                name: nil,
                type: "T",
                defaultValue: .literal(.nil)
            ),
            renderedBy: renderer.renderedParameter,
            rendersAs:
                #"""
                _ : T = nil
                """#,
            normalizing: false
        )
        try _test(
            .init(
                label: nil,
                name: nil,
                type: "T",
                defaultValue: nil
            ),
            renderedBy: renderer.renderedParameter,
            rendersAs:
                #"""
                _ : T
                """#,
            normalizing: false
        )
    }

    func testFunction() throws {
        try _test(
            .init(
                accessModifier: .public,
                kind: .function(name: "f"),
                parameters: [],
                body: []
            ),
            renderedBy: renderer.renderedFunction,
            rendersAs:
                #"""
                public func f() { }
                """#
        )
        try _test(
            .init(
                accessModifier: .public,
                kind: .function(name: "f"),
                parameters: [
                    .init(
                        label: "a",
                        name: "b",
                        type: "C",
                        defaultValue: nil
                    )
                ],
                body: []
            ),
            renderedBy: renderer.renderedFunction,
            rendersAs:
                #"""
                public func f(a b: C) { }
                """#
        )
        try _test(
            .init(
                accessModifier: .public,
                kind: .function(name: "f"),
                parameters: [
                    .init(
                        label: "a",
                        name: "b",
                        type: "C",
                        defaultValue: nil
                    ),
                    .init(
                        label: nil,
                        name: "d",
                        type: "E",
                        defaultValue: .literal(.string("f"))
                    ),
                ],
                body: []
            ),
            renderedBy: renderer.renderedFunction,
            rendersAs:
                #"""
                public func f(a b: C, _ d: E = "f") { }
                """#
        )
        try _test(
            .init(
                kind: .function(name: "f"),
                parameters: [],
                keywords: [.async, .throws],
                returnType: "String"
            ),
            renderedBy: renderer.renderedFunction,
            rendersAs:
                #"""
                func f() async throws -> String
                """#
        )
    }

    func testIdentifiers() throws {
        try _test(
            .init(name: "foo"),
            renderedBy: renderer.renderedIdentifier,
            rendersAs:
                #"""
                foo
                """#
        )
    }

    func testMemberAccess() throws {
        try _test(
            .init(left: .identifier("foo"), right: "bar"),
            renderedBy: renderer.renderedMemberAccess,
            rendersAs:
                #"""
                foo.bar
                """#
        )
        try _test(
            .init(left: nil, right: "bar"),
            renderedBy: renderer.renderedMemberAccess,
            rendersAs:
                #"""
                .bar
                """#
        )
    }

    func testFunctionCallArgument() throws {
        try _test(
            .init(
                label: "foo",
                expression: .identifier("bar")
            ),
            renderedBy: renderer.renderedFunctionCallArgument,
            rendersAs:
                #"""
                foo: bar
                """#,
            normalizing: false
        )
        try _test(
            .init(
                label: nil,
                expression: .identifier("bar")
            ),
            renderedBy: renderer.renderedFunctionCallArgument,
            rendersAs:
                #"""
                bar
                """#
        )
    }

    func testFunctionCall() throws {
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifier("callee")
                )
            ),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                callee()
                """#
        )
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifier("callee"),
                    arguments: [
                        .init(
                            label: "foo",
                            expression: .identifier("bar")
                        )
                    ]
                )
            ),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                callee(foo: bar)
                """#
        )
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifier("callee"),
                    arguments: [
                        .init(
                            label: "foo",
                            expression: .identifier("bar")
                        ),
                        .init(
                            label: "baz",
                            expression: .identifier("boo")
                        ),
                    ]
                )
            ),
            renderedBy: renderer.renderedExpression,
            rendersAs:
                #"""
                callee(foo: bar, baz: boo)
                """#
        )
    }

    func testExtension() throws {
        try _test(
            .init(
                accessModifier: .public,
                onType: "Info",
                declarations: [
                    .variable(
                        .init(kind: .let, left: "foo", type: "Int")
                    )
                ]
            ),
            renderedBy: renderer.renderedExtension,
            rendersAs:
                #"""
                public extension Info {
                let foo: Int
                }
                """#
        )
    }

    func testDeprecation() throws {
        try _test(
            .init(),
            renderedBy: renderer.renderedDeprecation,
            rendersAs:
                #"""
                @available(*, deprecated)
                """#,
            normalizing: false
        )
        try _test(
            .init(message: "some message"),
            renderedBy: renderer.renderedDeprecation,
            rendersAs:
                #"""
                @available(*, deprecated, message: "some message")
                """#,
            normalizing: false
        )
        try _test(
            .init(renamed: "newSymbol(param:)"),
            renderedBy: renderer.renderedDeprecation,
            rendersAs:
                #"""
                @available(*, deprecated, renamed: "newSymbol(param:)")
                """#,
            normalizing: false
        )
        try _test(
            .init(message: "some message", renamed: "newSymbol(param:)"),
            renderedBy: renderer.renderedDeprecation,
            rendersAs:
                #"""
                @available(*, deprecated, message: "some message", renamed: "newSymbol(param:)")
                """#,
            normalizing: false
        )
    }

    func testBindingKind() throws {
        try _test(
            .var,
            renderedBy: renderer.renderedBindingKind,
            rendersAs:
                #"""
                var
                """#,
            normalizing: false
        )
        try _test(
            .let,
            renderedBy: renderer.renderedBindingKind,
            rendersAs:
                #"""
                let
                """#,
            normalizing: false
        )
    }

    func testVariable() throws {
        try _test(
            .init(
                accessModifier: .public,
                isStatic: true,
                kind: .let,
                left: "foo",
                type: "String",
                right: .literal(.string("bar"))
            ),
            renderedBy: renderer.renderedVariable,
            rendersAs:
                #"""
                public static let foo: String = "bar"
                """#,
            normalizing: false
        )
        try _test(
            .init(
                accessModifier: .internal,
                isStatic: false,
                kind: .var,
                left: "foo",
                type: nil,
                right: nil
            ),
            renderedBy: renderer.renderedVariable,
            rendersAs:
                #"""
                internal var foo
                """#,
            normalizing: false
        )
    }

    func testStruct() throws {
        try _test(
            .init(
                name: "Structy"
            ),
            renderedBy: renderer.renderedStruct,
            rendersAs:
                #"""
                struct Structy {
                }
                """#
        )
    }

    func testProtocol() throws {
        try _test(
            .init(
                name: "Protocoly"
            ),
            renderedBy: renderer.renderedProtocol,
            rendersAs:
                #"""
                protocol Protocoly {
                }
                """#
        )
    }

    func testEnum() throws {
        try _test(
            .init(
                name: "Enumy"
            ),
            renderedBy: renderer.renderedEnum,
            rendersAs:
                #"""
                enum Enumy {}
                """#
        )
    }

    func testCodeBlockItem() throws {
        try _test(
            .declaration(
                .variable(
                    .init(
                        kind: .let,
                        left: "foo"
                    )
                )
            ),
            renderedBy: renderer.renderedCodeBlockItem,
            rendersAs:
                #"""
                let foo
                """#
        )
        try _test(
            .expression(.literal(.nil)),
            renderedBy: renderer.renderedCodeBlockItem,
            rendersAs:
                #"""
                nil
                """#
        )
    }

    func testCodeBlock() throws {
        try _test(
            .init(
                comment: .inline("- MARK: Section"),
                item: .declaration(
                    .variable(
                        .init(
                            kind: .let,
                            left: "foo"
                        )
                    )
                )
            ),
            renderedBy: renderer.renderedCodeBlock,
            rendersAs:
                #"""
                // - MARK: Section
                let foo
                """#
        )
        try _test(
            .init(
                comment: nil,
                item: .declaration(
                    .variable(
                        .init(
                            kind: .let,
                            left: "foo"
                        )
                    )
                )
            ),
            renderedBy: renderer.renderedCodeBlock,
            rendersAs:
                #"""
                let foo
                """#
        )
    }

    func testTypealias() throws {
        try _test(
            .init(
                name: "inty",
                existingType: "Int"
            ),
            renderedBy: renderer.renderedTypealias,
            rendersAs:
                #"""
                typealias inty = Int
                """#
        )
        try _test(
            .init(
                accessModifier: .private,
                name: "inty",
                existingType: "Int"
            ),
            renderedBy: renderer.renderedTypealias,
            rendersAs:
                #"""
                private typealias inty = Int
                """#
        )
    }

    func testFile() throws {
        try _test(
            .init(
                topComment: .inline("hi"),
                imports: [
                    .init(moduleName: "Foo")
                ],
                codeBlocks: [
                    .init(
                        comment: nil,
                        item: .expression(
                            .literal(.nil)
                        )
                    )
                ]
            ),
            renderedBy: renderer.renderedFile,
            rendersAs:
                #"""
                // hi
                import Foo
                nil
                """#
        )
    }
}

extension Test_TextBasedRenderer {
    func _test<Input>(
        _ input: Input,
        renderedBy renderer: (Input) -> String,
        rendersAs output: String,
        normalizing: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        if normalizing {
            XCTAssertEqual(
                try renderer(input).swiftFormatted,
                try output.swiftFormatted,
                file: file,
                line: line
            )
        } else {
            XCTAssertEqual(
                renderer(input),
                output,
                file: file,
                line: line
            )
        }
    }
}
