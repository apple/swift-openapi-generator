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
import Yams
@testable import _OpenAPIGeneratorCore

class Test_typeOverrides: Test_Core {
    func testSchemas() throws {
        let components = try loadComponentsFromYAML(
            #"""
            schemas:
              User:
                type: object
                properties:
                  id:
                    $ref: '#/components/schemas/UUID'
              UUID:
                type: string
                format: uuid
            """#
        )
        let translator = makeTranslator(
            components: components,
            typeOverrides: ["#/components/schemas/UUID": "Foundation.UUID"]
        )
        let translated = try translator.translateSchemas(components.schemas, multipartSchemaNames: [])
            .strippingTopComment
        guard let enumDecl = translated.enum else { return XCTFail("Expected enum declaration") }
        let typeAliases = enumDecl.members.compactMap(\.strippingTopComment.typealias)
        XCTAssertEqual(
            typeAliases,
            [
                TypealiasDescription(
                    accessModifier: .internal,
                    name: "UUID",
                    existingType: .member(["Foundation", "UUID"])
                )
            ]
        )
    }
    
    func testTypeOverrideWithNameOverride() throws {
        let components = try loadComponentsFromYAML(
            #"""
            schemas:
              User:
                type: object
                properties:
                  id:
                    $ref: '#/components/schemas/UUID'
              UUID:
                type: string
                format: uuid
            """#
        )
        let translator = makeTranslator(
            components: components,
            nameOverrides: ["UUID": "MyUUID"],
            typeOverrides: ["UUID": "Foundation.UUID"]
        )
        let translated = try translator.translateSchemas(components.schemas, multipartSchemaNames: [])
            .strippingTopComment
        guard let enumDecl = translated.enum else { return XCTFail("Expected enum declaration") }
        let typeAliases = enumDecl.members.compactMap(\.strippingTopComment.typealias)
        XCTAssertEqual(
            typeAliases,
            [
                TypealiasDescription(
                    accessModifier: .internal,
                    name: "MyUUID",
                    existingType: .member(["Foundation", "UUID"])
                )
            ]
        )
    }
}
