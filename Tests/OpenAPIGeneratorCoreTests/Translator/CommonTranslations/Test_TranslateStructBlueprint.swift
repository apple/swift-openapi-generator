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
import Testing
@testable import _OpenAPIGeneratorCore

@Suite("Translate Struct Blueprint Tests")
struct Test_TranslateStructBlueprint {
    
    private func testStruct(_ blueprint: StructBlueprint) throws -> [DeclInfo] {
        let translator = TestFixtures.makeTypesTranslator()
        let decl = translator.translateStructBlueprint(blueprint)
        
        guard case .struct(let structDecl) = decl.strippingTopComment else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .struct)
        }
        
        #expect(structDecl.name == "Foo")
        let members = structDecl.members.map { $0.info }
        return members
    }
    
    @Test("Single property struct generates expected members")
    func testSinglePropertyStruct() throws {
        let members = try testStruct(
            StructBlueprint.init(
                typeName: TestFixtures.testTypeName,
                shouldGenerateCodingKeys: true,
                properties: [TestFixtures.makeProperty(originalName: "bar", typeUsage: TypeName.int.asUsage)]
            )
        )
        
        #expect(members == [
            DeclInfo.init(name: "bar", kind: .variable),
            DeclInfo.init(name: "init", kind: .function),
            DeclInfo.init(name: "CodingKeys", kind: .enum),
        ])
    }
    
    @Test("Empty struct generates default initializer")
    func testEmptyStruct() throws {
        let members = try testStruct(
            StructBlueprint.init(
                typeName: TestFixtures.testTypeName,
                shouldGenerateCodingKeys: true,
                properties: []
            )
        )
        
        #expect(members == [DeclInfo.init(name: "init", kind: .function)])
    }
    
    @Test("Deprecated struct kind is deprecated")
    func testDeprecatedStruct() throws {
        let blueprint = StructBlueprint(
            isDeprecated: true,
            typeName: TestFixtures.testTypeName,
            properties: []
        )
        
        let decl = TestFixtures.makeTypesTranslator().translateStructBlueprint(blueprint)
        #expect(decl.strippingTopComment.info.kind == .deprecated)
    }
}
