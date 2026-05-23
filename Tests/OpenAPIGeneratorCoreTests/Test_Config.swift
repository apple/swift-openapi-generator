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

final class Test_Config: Test_Core {
    func testDefaultAccessModifier() { XCTAssertEqual(Config.defaultAccessModifier, .internal) }
    func testAdditionalFileComments() {
        let config = Config(
            mode: .types,
            access: .public,
            additionalFileComments: ["swift-format-ignore-file", "swiftlint:disable all"],
            namingStrategy: .defensive
        )
        XCTAssertEqual(config.additionalFileComments, ["swift-format-ignore-file", "swiftlint:disable all"])
    }
    func testEmptyAdditionalFileComments() {
        let config = Config(mode: .types, access: .public, namingStrategy: .defensive)
        XCTAssertEqual(config.additionalFileComments, [])
    }

    // MARK: - MacroConfiguration

    func testMacroConfigurationDefault() {
        let config = MacroConfiguration.default
        XCTAssertEqual(config.schemas, [:])
        XCTAssertEqual(config.client, [])
    }

    func testMacroConfigurationAttributesForSchema_noRules() {
        let config = MacroConfiguration()
        XCTAssertEqual(config.attributes(forSchema: "Pet"), [])
    }

    func testMacroConfigurationAttributesForSchema_wildcardOnly() {
        let config = MacroConfiguration(schemas: ["*": ["@Observable"]])
        XCTAssertEqual(config.attributes(forSchema: "Pet"), ["@Observable"])
        XCTAssertEqual(config.attributes(forSchema: "Error"), ["@Observable"])
    }

    func testMacroConfigurationAttributesForSchema_exactOnly() {
        let config = MacroConfiguration(schemas: ["Pet": ["@PetMacro"]])
        XCTAssertEqual(config.attributes(forSchema: "Pet"), ["@PetMacro"])
        XCTAssertEqual(config.attributes(forSchema: "Error"), [])
    }

    func testMacroConfigurationAttributesForSchema_wildcardAndExact() {
        let config = MacroConfiguration(schemas: ["*": ["@Observable"], "Pet": ["@PetMacro"]])
        // Wildcard first, then exact
        XCTAssertEqual(config.attributes(forSchema: "Pet"), ["@Observable", "@PetMacro"])
        XCTAssertEqual(config.attributes(forSchema: "Error"), ["@Observable"])
    }

    func testAnnotateWithHelperOnDeclaration_empty() {
        let decl = Declaration.struct(.init(name: "Foo"))
        let annotated = decl.annotate(with: [])
        XCTAssertEqual(annotated, decl)
    }

    func testAnnotateWithHelperOnDeclaration_nonEmpty() {
        // A plain (uncommented) declaration → wraps with .annotated.
        let decl = Declaration.struct(.init(name: "Foo"))
        let attrs = [AttributeDescription(text: "@MyMacro")]
        let annotated = decl.annotate(with: attrs)
        XCTAssertEqual(annotated, .annotated(attrs, decl))
    }

    func testAnnotateWithHelperOnDeclaration_commentable_drillsThrough() {
        // A commented declaration → annotation is placed inside .commentable so
        // it renders between the /// lines and the type keyword, not before them.
        let inner = Declaration.struct(.init(name: "Foo"))
        let comment = Comment.doc("A documented type.")
        let commented = Declaration.commentable(comment, inner)
        let attrs = [AttributeDescription(text: "@MyMacro")]
        let annotated = commented.annotate(with: attrs)
        XCTAssertEqual(annotated, .commentable(comment, .annotated(attrs, inner)))
    }
}
