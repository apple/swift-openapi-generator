//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest
import Yams
@testable import _OpenAPIGeneratorCore

final class Test_AttachedMacros: Test_Core {

    func testDecodingEmpty() throws {
        XCTAssertEqual(try YAMLDecoder().decode(AttachedMacros.self, from: "{}"), AttachedMacros())
        XCTAssertEqual(
            try YAMLDecoder().decode(AttachedMacros.self, from: "components: {}"),
            AttachedMacros(components: .init())
        )
    }

    func testDecodingAllTargets() throws {
        let attachedMacros = try YAMLDecoder()
            .decode(
                AttachedMacros.self,
                from: """
                    components:
                      schemas:
                        - filter: "^Schema$"
                          macros: [{name: Schema}]
                      parameters:
                        - filter: "^Parameter$"
                          macros: [{name: Parameter}]
                      requestBodies:
                        - filter: "^RequestBody$"
                          macros: [{name: RequestBody}]
                      responses:
                        - filter: "^Response$"
                          macros: [{name: Response}]
                      headers:
                        - filter: "^Header$"
                          macros: [{name: Header}]
                    operations:
                      - filter: "^createPet$"
                        operation: [{name: Operation}]
                        input: [{name: Input}]
                        output: [{name: Output}]
                        clientMethod: [{name: ClientMethod}]
                      - filter: "^listPets$"
                    apiProtocol: [{name: APIProtocol}]
                    client: [{name: Client}]
                    server: [{name: Server}]
                    """
            )
        XCTAssertEqual(
            attachedMacros,
            AttachedMacros(
                components: .init(
                    schemas: [.init(filter: "^Schema$", macros: [.init(name: "Schema")])],
                    parameters: [.init(filter: "^Parameter$", macros: [.init(name: "Parameter")])],
                    requestBodies: [.init(filter: "^RequestBody$", macros: [.init(name: "RequestBody")])],
                    responses: [.init(filter: "^Response$", macros: [.init(name: "Response")])],
                    headers: [.init(filter: "^Header$", macros: [.init(name: "Header")])]
                ),
                operations: [
                    .init(
                        filter: "^createPet$",
                        operation: [.init(name: "Operation")],
                        input: [.init(name: "Input")],
                        output: [.init(name: "Output")],
                        clientMethod: [.init(name: "ClientMethod")]
                    ), .init(filter: "^listPets$"),
                ],
                apiProtocol: [.init(name: "APIProtocol")],
                client: [.init(name: "Client")],
                server: [.init(name: "Server")]
            )
        )
    }

    func testDecodingRulesWithoutFilter() throws {
        let attachedMacros = try YAMLDecoder()
            .decode(
                AttachedMacros.self,
                from: """
                    components:
                      schemas:
                        - macros: [{name: Schema}]
                    operations:
                      - input: [{name: Input}]
                    """
            )
        XCTAssertEqual(
            attachedMacros,
            AttachedMacros(
                components: .init(schemas: [.init(macros: [.init(name: "Schema")])]),
                operations: [.init(input: [.init(name: "Input")])]
            )
        )
    }

    func testDecodingMacros() throws {
        let macros = try YAMLDecoder()
            .decode(
                [AttachedMacro].self,
                from: #"""
                    - name: Mockable
                    - name: Module.Macro
                      arguments: []
                    - name: DependencyClientWrapper
                      arguments:
                        - label: name
                          value: '"PetStoreClient"'
                        - label: mode
                          value: .live
                        - value: Foo.self
                        - value: 42
                        - value: true
                    """#
            )
        XCTAssertEqual(
            macros,
            [
                .init(name: "Mockable"), .init(name: "Module.Macro"),
                .init(
                    name: "DependencyClientWrapper",
                    arguments: [
                        .init(label: "name", value: #""PetStoreClient""#), .init(label: "mode", value: ".live"),
                        .init(value: "Foo.self"), .init(value: "42"), .init(value: "true"),
                    ]
                ),
            ]
        )
    }

    func testDecodingErrors() throws {
        let invalidConfigs = [
            // Unknown keys at every level.
            "clients: [{name: A}]", "components: {examples: []}", "components: {schemas: [{filter: A, macro: [{name: A}]}]}",
            "operations: [{filter: A, ouput: [{name: A}]}]", "apiProtocol: [{name: A, argument: []}]",
            "apiProtocol: [{name: A, arguments: [{lable: x, value: 1}]}]",
            // Missing required keys.
            "components: {schemas: [{filter: A}]}", "apiProtocol: [{arguments: []}]",
            // Invalid regular expressions.
            "components: {schemas: [{filter: '(', macros: [{name: A}]}]}", "operations: [{filter: '[', input: [{name: A}]}]",
            // Invalid macro names.
            "apiProtocol: [{name: '@Mockable'}]", "apiProtocol: [{name: [{name: A}]}]",
            // Macros that aren't objects.
            "apiProtocol: [A]",
            // Arguments without a value, or with an unknown key.
            "apiProtocol: [{name: A, arguments: [{label: x}]}]",
            "apiProtocol: [{name: A, arguments: [{value: '1', expression: '2'}]}]",
            // Wrong types.
            "apiProtocol: A", "operations: {filter: A}",
        ]
        for yaml in invalidConfigs {
            XCTAssertThrowsError(try YAMLDecoder().decode(AttachedMacros.self, from: yaml), yaml)
        }
    }

    func testDecodingErrorMessages() throws {
        func message(_ yaml: String) -> String? {
            do {
                _ = try YAMLDecoder().decode(AttachedMacros.self, from: yaml)
                return nil
            } catch DecodingError.dataCorrupted(let context) { return context.debugDescription } catch {
                return "\(error)"
            }
        }
        XCTAssertEqual(
            message("operations: [{filter: A, ouput: [{name: A}]}]"),
            "Unknown key 'ouput'. Allowed keys: clientMethod, filter, input, operation, output."
        )
        XCTAssertEqual(
            message("apiProtocol: [{name: '@Mockable'}]"),
            "Invalid macro name '@Mockable'. Provide the name without the leading '@', for example 'Mockable'."
        )
        XCTAssertEqual(
            message("components: {schemas: [{filter: '(', macros: [{name: A}]}]}")?.hasPrefix("Invalid regular expression '('"),
            true
        )
    }

    func testEncodingRoundTrip() throws {
        let attachedMacros = AttachedMacros(
            components: .init(schemas: [.init(filter: ".*", macros: [.init(name: "A")])]),
            operations: [.init(filter: "^createPet$", input: [.init(name: "B")])],
            apiProtocol: [
                .init(
                    name: "C",
                    arguments: [.init(label: "name", value: #""x""#), .init(value: ".live")]
                )
            ]
        )
        let encoded = try YAMLEncoder().encode(attachedMacros)
        XCTAssertEqual(try YAMLDecoder().decode(AttachedMacros.self, from: encoded), attachedMacros)
    }

    func testMatching() {
        XCTAssertTrue(AttachedMacros.matches(".*", "Pet"))
        XCTAssertTrue(AttachedMacros.matches(".*", ""))
        XCTAssertTrue(AttachedMacros.matches("Pet", "PetOwner"))
        XCTAssertTrue(AttachedMacros.matches("Owner", "PetOwner"))
        XCTAssertFalse(AttachedMacros.matches("^Pet$", "PetOwner"))
        XCTAssertTrue(AttachedMacros.matches("^Pet$", "Pet"))
        XCTAssertFalse(AttachedMacros.matches("^pet$", "Pet"))
        XCTAssertTrue(AttachedMacros.matches("(?i)^pet$", "Pet"))
        XCTAssertTrue(AttachedMacros.matches("^pet-store$", "pet-store"))
        XCTAssertTrue(AttachedMacros.matches(#"^get/pets/\{petId\}$"#, "get/pets/{petId}"))
        XCTAssertTrue(AttachedMacros.matches("^Pét$", "Pét"))
        XCTAssertFalse(AttachedMacros.matches("(", "("))
        XCTAssertTrue(AttachedMacros.matches(nil, "Pet"))
        XCTAssertTrue(AttachedMacros.matches(nil, ""))
    }

    func testComponentRules() {
        let rules: [AttachedMacros.ComponentRule] = [
            .init(filter: ".*", macros: [.init(name: "A")]), .init(filter: "^Pet$", macros: [.init(name: "B")]),
            .init(filter: "Pet", macros: [.init(name: "A"), .init(name: "C")]), .init(macros: [.init(name: "D")]),
        ]
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Pet").map(\.name), ["A", "B", "A", "C", "D"])
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "PetOwner").map(\.name), ["A", "A", "C", "D"])
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Owner").map(\.name), ["A", "D"])
        XCTAssertEqual(AttachedMacros.macros(in: [], matching: "Pet"), [])
    }

    func testDuplicateMacrosAreKept() {
        let a = AttachedMacro(name: "A")
        let rules: [AttachedMacros.ComponentRule] = [
            .init(filter: ".*", macros: [a, a]), .init(filter: ".*", macros: [a]),
        ]
        XCTAssertEqual(AttachedMacros.macros(in: rules, matching: "Pet"), [a, a, a])
    }

    func testOperationRules() {
        let attachedMacros = AttachedMacros(operations: [
            .init(
                filter: "^create",
                operation: [.init(name: "Operation")],
                input: [.init(name: "Input")],
                output: [.init(name: "Output")],
                clientMethod: [.init(name: "ClientMethod")]
            ), .init(filter: "Pet$", input: [.init(name: "Input"), .init(name: "PetInput")]),
            .init(output: [.init(name: "AllOutput")]),
        ])
        XCTAssertEqual(attachedMacros.macros(for: \.operation, operationID: "createPet").map(\.name), ["Operation"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "createPet").map(\.name), ["Input", "Input", "PetInput"])
        XCTAssertEqual(
            attachedMacros.macros(for: \.output, operationID: "createPet").map(\.name),
            ["Output", "AllOutput"]
        )
        XCTAssertEqual(attachedMacros.macros(for: \.clientMethod, operationID: "createPet").map(\.name), ["ClientMethod"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "getPet").map(\.name), ["Input", "PetInput"])
        XCTAssertEqual(attachedMacros.macros(for: \.output, operationID: "getPet").map(\.name), ["AllOutput"])
        XCTAssertEqual(attachedMacros.macros(for: \.input, operationID: "listPets").map(\.name), [])
    }

    func testAttributeFromMacro() {
        XCTAssertEqual(AttributeDescription(AttachedMacro(name: "Mockable")), .init(name: "Mockable"))
        XCTAssertEqual(
            AttributeDescription(
                AttachedMacro(
                    name: "Foo",
                    arguments: [
                        .init(label: "name", value: #""Pet""#), .init(value: "1"),
                        .init(label: "mode", value: ".live"), .init(value: "Foo.self"),
                    ]
                )
            ),
            .init(name: "Foo", arguments: [#"name: "Pet""#, "1", "mode: .live", "Foo.self"])
        )
    }

    func testAttaching() {
        let declaration = Declaration.struct(.init(name: "Pet"))
        XCTAssertEqual(declaration.attaching([]), declaration)
        XCTAssertEqual(declaration.attaching([.init(name: "A")]), .attributed([.init(name: "A")], declaration))
        XCTAssertEqual(
            Declaration.commentable(.doc("A pet."), declaration).attaching([.init(name: "A"), .init(name: "B")]),
            .commentable(.doc("A pet."), .attributed([.init(name: "A"), .init(name: "B")], declaration))
        )
        XCTAssertEqual(
            Declaration.commentable(.doc("A pet."), .deprecated(.init(), declaration)).attaching([.init(name: "A")]),
            .commentable(.doc("A pet."), .attributed([.init(name: "A")], .deprecated(.init(), declaration)))
        )
    }

    func testAttachingToLast() {
        let inline = Declaration.enum(.init(name: "Inline"))
        let declaration = Declaration.struct(.init(name: "Pet"))
        XCTAssertEqual([Declaration]().attachingToLast([.init(name: "A")]), [])
        XCTAssertEqual([inline, declaration].attachingToLast([]), [inline, declaration])
        XCTAssertEqual(
            [inline, declaration].attachingToLast([.init(name: "A")]),
            [inline, .attributed([.init(name: "A")], declaration)]
        )
    }

    func testAttributedDeclarationPassesThrough() {
        var declaration = Declaration.attributed([.init(name: "A")], .struct(.init(name: "Pet")))
        XCTAssertEqual(declaration.name, "Pet")
        XCTAssertTrue(declaration.isBoxable)
        XCTAssertNil(declaration.accessModifier)
        declaration.accessModifier = .public
        XCTAssertEqual(declaration, .attributed([.init(name: "A")], .struct(.init(accessModifier: .public, name: "Pet"))))
    }
}
