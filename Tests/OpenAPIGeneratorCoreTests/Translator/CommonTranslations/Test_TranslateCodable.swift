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


@Suite("Translate Codable Tests")
struct Test_TranslateCodable {
    
    private func _testDecoder(properties: [PropertyBlueprint], trailingCodeBlocks: [CodeBlock] = []) throws -> [CodeBlockInfo] {
        let translator = TestFixtures.makeTypesTranslator()
        
        let decl = translator.translateStructBlueprintCustomDecoder(
            properties: properties,
            trailingCodeBlocks: trailingCodeBlocks
        )
        
        guard case .function(let funcDecl) = decl else {
            #expect(Bool(false), "Expected function declaration, got (decl.info.kind)")
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .function)
        }
        
        let members = (funcDecl.body ?? []).map { $0.item.info }
        return members
    }
    
    private func _testEncoder(properties: [PropertyBlueprint], trailingCodeBlocks: [CodeBlock] = []) throws -> [CodeBlockInfo] {
        let translator = TestFixtures.makeTypesTranslator()
        
        let decl = translator.translateStructBlueprintCustomEncoder(
            properties: properties,
            trailingCodeBlocks: trailingCodeBlocks
        )
        
        guard case .function(let funcDecl) = decl else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .function)
        }
        
        let members = (funcDecl.body ?? []).map { $0.item.info }
        return members
    }
    
    @Test("Decoder handles no properties with extra code blocks")
    func testDecoder_noPropertiesWithExtraCodeBlocks() throws {
        let members = try _testDecoder(properties: [], trailingCodeBlocks: [.expression(.identifierPattern("foo"))])
        #expect(members == [CodeBlockInfo.init(name: "foo", kind: .expression)])
    }
    
    @Test("Decoder handles one property with extra code blocks")
    func testDecoder_onePropertyWithExtraCodeBlocks() throws {
        let members = try _testDecoder(
            properties: [TestFixtures.makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)],
            trailingCodeBlocks: [.expression(.identifierPattern("foo"))]
        )
        #expect(
            members == [
                CodeBlockInfo.init(name: "container", kind: .declaration),
                CodeBlockInfo.init(name: "bar", kind: .expression),
                CodeBlockInfo.init(name: "foo", kind: .expression)
            ]
        )
    }
    
    @Test("Decoder handles single property without extra code blocks")
    func testDecoder_onePropertyNoExtraCodeBlocks() throws {
        let members = try _testDecoder(
            properties: [TestFixtures.makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)]
        )
        
        #expect(members == [
            CodeBlockInfo.init(name: "container", kind: .declaration),
            CodeBlockInfo.init(name: "bar", kind: .expression)
        ])
    }
    
    @Test("Encoder handles extra code blocks without properties")
    func testEncoder_noPropertiesWithExtraCodeBlocks() throws {
        let members = try _testEncoder(
            properties: [], trailingCodeBlocks: [.expression(.identifierPattern("foo"))]
        )
        
        #expect(members == [
            CodeBlockInfo.init(name: "foo", kind: .expression)
        ])
    }

    @Test("Encoder handles one property with extra code blocks")
    func testEncoder_onePropertyWithExtraCodeBlocks() throws {
        let members = try _testEncoder(
            properties: [TestFixtures.makeProperty(originalName: "bar", typeUsage: TypeName.string.asUsage)],
            trailingCodeBlocks: [.expression(.identifierPattern("foo"))]
        )
        
        #expect(members == [
            CodeBlockInfo.init(name: "container", kind: .declaration), .init(name: "try", kind: .expression),
            CodeBlockInfo.init(name: "foo", kind: .expression),
        ])
    }
}
