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

@Suite("Translate String Enum Tests")
struct Test_TranslateStringEnum {
    
    func _caseValues(_ schema: JSONSchema) throws -> [String] {
        let translator = TestFixtures.makeTypesTranslator()
        let decls = try translator.translateSchema(
            typeName: .init(swiftKeyPath: ["FooEnum"]),
            schema: schema,
            overrides: .none
        )
        #expect(decls.count == 1)
        let decl = decls[0]
        guard case .enum(let enumDesc) = decl.strippingTopComment else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .enum)
        }
        #expect(enumDesc.name == "FooEnum")
        let names: [String] = enumDesc.members.compactMap { memberDecl in
            guard case .enumCase(let caseDesc) = memberDecl.strippingTopComment else { return nil }
            return caseDesc.name
        }
        return names
    }

    @Test("Case values for string schema")
    func testCaseValues() throws {
        let names = try _caseValues(.string(allowedValues: "a", ""))
        #expect(names == ["a", "_empty"])
    }
    
    @Test("Case values for nullable schema")
    func testCaseValuesForNullableSchema() throws {
        let names = try _caseValues(.string(nullable: true, allowedValues: "a", nil))
        #expect(names == ["a", "_empty"])
    }
    
    @Test("Case values for integer schema")
    func testCaseValuesForIntegerSchema() throws {
        let names = try _caseValues(.integer(allowedValues: -1, 1))
        #expect(names == ["_n1", "_1"])
    }
}
