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

final class Test_translateStringEnum: Test_Core {

    func testCaseValues() throws {
        let names = try _caseValues(.string(allowedValues: "a", ""))
        XCTAssertEqual(names, ["a", "_empty"])
    }

    func testCaseValuesForNullableSchema() throws {
        let names = try _caseValues(.string(nullable: true, allowedValues: "a", nil))
        XCTAssertEqual(names, ["a", "_empty"])
    }

    func testCaseValuesForIntegerSchema() throws {
        let names = try _caseValues(.integer(allowedValues: -1, 1))
        XCTAssertEqual(names, ["_n1", "_1"])
    }

    func _caseValues(_ schema: JSONSchema) throws -> [String] {
        self.continueAfterFailure = false
        let translator = makeTypesTranslator()
        let decls = try translator.translateSchema(
            typeName: .init(swiftKeyPath: ["FooEnum"]),
            schema: schema,
            overrides: .none
        )
        XCTAssertEqual(decls.count, 1)
        let decl = decls[0]
        guard case .enum(let enumDesc) = decl.strippingTopComment else {
            throw UnexpectedDeclError(actual: decl.info.kind, expected: .enum)
        }
        XCTAssertEqual(enumDesc.name, "FooEnum")
        let names: [String] = enumDesc.members.compactMap { memberDecl in
            guard case .enumCase(let caseDesc) = memberDecl.strippingTopComment else { return nil }
            return caseDesc.name
        }
        return names
    }
}
