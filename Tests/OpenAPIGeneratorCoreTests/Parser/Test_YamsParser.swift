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
@testable import _OpenAPIGeneratorCore

final class Test_YamsParser: Test_Core {

    func testVersionValidation() throws {
        XCTAssertNoThrow(try _test("3.0.0"))
        XCTAssertNoThrow(try _test("3.0.1"))
        XCTAssertNoThrow(try _test("3.0.2"))
        XCTAssertNoThrow(try _test("3.0.3"))
        XCTAssertThrowsError(try _test("3.1.0"))
        XCTAssertThrowsError(try _test("2.0"))
    }

    func _test(_ openAPIVersionString: String) throws -> ParsedOpenAPIRepresentation {
        try YamsParser()
            .parseOpenAPI(
                .init(
                    absolutePath: URL(fileURLWithPath: "/foo.yaml"),
                    contents: Data(
                        """
                        openapi: "\(openAPIVersionString)"
                        info:
                          title: "Test"
                          version: "1.0.0"
                        paths: {}
                        """
                        .utf8
                    )
                ),
                config: .init(mode: .types),
                diagnostics: PrintingDiagnosticCollector()
            )
    }
}
