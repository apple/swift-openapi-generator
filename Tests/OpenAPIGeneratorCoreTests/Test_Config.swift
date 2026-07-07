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

    func testOutputOptionsDefaultToEmpty() {
        let config = Config(mode: .types, access: .public, namingStrategy: .defensive)
        XCTAssertNil(config.output.types)
    }

    func testTypesFileSplittingConfig() {
        let config = Config(
            mode: .types,
            access: .public,
            namingStrategy: .defensive,
            output: .init(types: .init(fileSplitting: .init(strategy: .namespace)))
        )
        XCTAssertEqual(config.output.types?.fileSplitting?.strategy, .namespace)
    }

    func testTypesFileSplittingConfigOptions() {
        let config = TypesFileSplittingConfig(
            strategy: .namespace,
            namespace: .init()
        )

        XCTAssertEqual(config.strategy, .namespace)
        XCTAssertEqual(config.namespace, .init())
    }
}
