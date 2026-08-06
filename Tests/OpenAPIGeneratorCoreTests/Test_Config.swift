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

    func testGeneratorModeOutputFileNameHelper() {
        XCTAssertEqual(GeneratorMode.outputFileName("Types"), "Types.swift")
        XCTAssertEqual(GeneratorMode.outputFileName("Types.swift", "Components"), "Types+Components.swift")
        XCTAssertEqual(GeneratorMode.outputFileName("Types.swift", "Operations.swift"), "Types+Operations.swift")
    }

    func testGeneratorModeOutputFileNames() {
        XCTAssertEqual(
            GeneratorMode.types.outputFileNames,
            [
                "Types.swift",
                "Types+Components.swift",
                "Types+Operations.swift",
                "Types+Components+Schemas.swift",
                "Types+Components+Parameters.swift",
                "Types+Components+RequestBodies.swift",
                "Types+Components+Responses.swift",
                "Types+Components+Headers.swift",
            ]
        )
        XCTAssertEqual(GeneratorMode.client.outputFileNames, ["Client.swift"])
        XCTAssertEqual(GeneratorMode.server.outputFileNames, ["Server.swift"])
        XCTAssertEqual(GeneratorMode.allOutputFileNames, GeneratorMode.allCases.flatMap(\.outputFileNames))
    }
}
