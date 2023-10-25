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

final class Test_validateDoc: Test_Core {

    func testSchemaWarningIsNotFatal() throws {
        let schemaWithWarnings = try loadSchemaFromYAML(
            #"""
            type: string
            items:
              type: integer
            """#
        )
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [:],
            components: .init(schemas: ["myImperfectSchema": schemaWithWarnings])
        )
        let diagnostics = try validateDoc(doc, config: .init(mode: .types))
        XCTAssertEqual(diagnostics.count, 1)
    }

    func testStructuralWarningIsFatal() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/foo": .b(
                    .init(
                        get: .init(
                            requestBody: nil,

                            // Fatal error: missing at least one response.
                            responses: [:]
                        )
                    )
                )
            ],
            components: .noComponents
        )
        XCTAssertThrowsError(try validateDoc(doc, config: .init(mode: .types)))
    }

}
