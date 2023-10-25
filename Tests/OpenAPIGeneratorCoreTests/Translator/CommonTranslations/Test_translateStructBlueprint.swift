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

final class Test_translateStructBlueprint: Test_Core {

    func testSinglePropertyStruct() throws {
        let members = try _testStruct(
            .init(
                typeName: Self.testTypeName,
                shouldGenerateCodingKeys: true,
                properties: [makeProperty(originalName: "bar", typeUsage: TypeName.int.asUsage)]
            )
        )
        XCTAssertEqual(
            members,
            [
                .init(name: "bar", kind: .variable), .init(name: "init", kind: .function),
                .init(name: "CodingKeys", kind: .enum),
            ]
        )
    }

    func testEmptyStruct() throws {
        let members = try _testStruct(
            .init(typeName: Self.testTypeName, shouldGenerateCodingKeys: true, properties: [])
        )
        XCTAssertEqual(members, [.init(name: "init", kind: .function)])
    }

    func testDeprecatedStruct() throws {
        let blueprint = StructBlueprint(isDeprecated: true, typeName: Self.testTypeName, properties: [])
        let decl = makeTypesTranslator().translateStructBlueprint(blueprint)
        XCTAssertEqual(decl.strippingTopComment.info.kind, .deprecated)
    }

    func _testStruct(_ blueprint: StructBlueprint) throws -> [DeclInfo] {
        let translator = makeTypesTranslator()
        let decl = translator.translateStructBlueprint(blueprint)
        guard case .struct(let structDecl) = decl.strippingTopComment else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .struct)
        }
        XCTAssertEqual(structDecl.name, "Foo")
        let members = structDecl.members.map(\.info)
        return members
    }
}
