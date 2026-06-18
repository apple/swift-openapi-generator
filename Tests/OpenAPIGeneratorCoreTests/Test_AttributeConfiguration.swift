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
import Yams
@testable import _OpenAPIGeneratorCore

final class Test_AttributeConfiguration: Test_Core {
    func testAttributeConfigurationDecoding() throws {
        let yaml = """
            protocol:
              - MainActor
            methods:
              - MainActor
            """
        let decoded = try YAMLDecoder().decode(AttributeConfiguration.self, from: yaml)
        XCTAssertEqual(decoded.protocolAttributes, ["MainActor"])
        XCTAssertEqual(decoded.methodAttributes, ["MainActor"])
    }

    func testAttributeConfigurationDecodingWithQuotedArguments() throws {
        let yaml = """
            methods:
              - "Mockable(visibility: .public)"
            """
        let decoded = try YAMLDecoder().decode(AttributeConfiguration.self, from: yaml)
        XCTAssertEqual(decoded.methodAttributes, ["Mockable(visibility: .public)"])
    }
}
