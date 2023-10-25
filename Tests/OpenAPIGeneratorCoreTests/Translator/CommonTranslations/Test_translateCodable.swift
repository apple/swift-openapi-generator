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
import OpenAPIKit
@testable import _OpenAPIGeneratorCore

final class Test_translateCodable: Test_Core {

    func testDecoder_noPropertiesWithExtraCodeBlocks() throws {
        let members = try _testDecoder(properties: [], trailingCodeBlocks: [.expression(.identifierPattern("foo"))])
        XCTAssertEqual(members, [.init(name: "foo", kind: .expression)])
    }

    func testDecoder_onePropertyWithExtraCodeBlocks() throws {
        let members = try _testDecoder(
            properties: [makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)],
            trailingCodeBlocks: [.expression(.identifierPattern("foo"))]
        )
        XCTAssertEqual(
            members,
            [
                .init(name: "container", kind: .declaration), .init(name: "bar", kind: .expression),
                .init(name: "foo", kind: .expression),
            ]
        )
    }

    func testDecoder_onePropertyNoExtraCodeBlocks() throws {
        let members = try _testDecoder(properties: [
            makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)
        ])
        XCTAssertEqual(members, [.init(name: "container", kind: .declaration), .init(name: "bar", kind: .expression)])
    }

    func _testDecoder(properties: [PropertyBlueprint], trailingCodeBlocks: [CodeBlock] = []) throws -> [CodeBlockInfo] {
        let translator = makeTypesTranslator()
        let decl = translator.translateStructBlueprintCustomDecoder(
            properties: properties,
            trailingCodeBlocks: trailingCodeBlocks
        )
        guard case .function(let funcDecl) = decl else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .function)
        }
        let members = (funcDecl.body ?? []).map(\.item.info)
        return members
    }

    func testEncoder_noPropertiesWithExtraCodeBlocks() throws {
        let members = try _testEncoder(properties: [], trailingCodeBlocks: [.expression(.identifierPattern("foo"))])
        XCTAssertEqual(members, [.init(name: "foo", kind: .expression)])
    }

    func testEncoder_onePropertyWithExtraCodeBlocks() throws {
        let members = try _testEncoder(
            properties: [makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)],
            trailingCodeBlocks: [.expression(.identifierPattern("foo"))]
        )
        XCTAssertEqual(
            members,
            [
                .init(name: "container", kind: .declaration), .init(name: "try", kind: .expression),
                .init(name: "foo", kind: .expression),
            ]
        )
    }

    func testEncoder_onePropertyNoExtraCodeBlocks() throws {
        let members = try _testEncoder(properties: [
            makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)
        ])
        XCTAssertEqual(members, [.init(name: "container", kind: .declaration), .init(name: "try", kind: .expression)])
    }

    func _testEncoder(properties: [PropertyBlueprint], trailingCodeBlocks: [CodeBlock] = []) throws -> [CodeBlockInfo] {
        let translator = makeTypesTranslator()
        let decl = translator.translateStructBlueprintCustomEncoder(
            properties: properties,
            trailingCodeBlocks: trailingCodeBlocks
        )
        guard case .function(let funcDecl) = decl else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .function)
        }
        let members = (funcDecl.body ?? []).map(\.item.info)
        return members
    }
}
