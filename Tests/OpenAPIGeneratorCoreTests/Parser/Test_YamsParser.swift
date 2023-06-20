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
import ArgumentParser

final class Test_YamsParser: Test_Core {

    func testVersionValidation() throws {
        XCTAssertNoThrow(try _test("3.0.0"))
        XCTAssertNoThrow(try _test("3.0.1"))
        XCTAssertNoThrow(try _test("3.0.2"))
        XCTAssertNoThrow(try _test("3.0.3"))
        XCTAssertThrowsError(try _test("3.1.0"))
        XCTAssertThrowsError(try _test("2.0"))
    }

    private func _test(_ openAPIVersionString: String) throws -> ParsedOpenAPIRepresentation {
        try _test(
            """
            openapi: "\(openAPIVersionString)"
            info:
              title: "Test"
              version: "1.0.0"
            paths: {}
            """,
            diagnostics: PrintingDiagnosticCollector()
        )
    }

    func testEmitsYamsParsingError() throws {
        let collector = TestingDiagnosticsCollector()
        // The `title: "Test"` line is indented the wrong amount to make the YAML invalid for the parser
        let yaml = """
            openapi: "3.0.0"
            info:
             title: "Test"
              version: 1.0.0
            paths: {}
            """

        XCTAssertThrowsError(try _test(yaml, diagnostics: collector)) { error in
            if let exitError = error as? ExitCode {
                XCTAssertEqual(exitError, ExitCode.failure)
            } else {
                XCTFail("Thrown error is \(type(of: error)) but should be ExitCode.failure")
            }

            XCTAssertEqual(collector.allOutput.count, 1)
            if let actualDiagnostic = collector.allOutput.first {
                let expectedDiagnostic =
                    "/foo.yaml:3: error: did not find expected key while parsing a block mapping in line 3, column 2\n"
                XCTAssertEqual(actualDiagnostic, expectedDiagnostic)
            }
        }
    }

    func testEmitsYamsScanningError() throws {
        let collector = TestingDiagnosticsCollector()
        // The `version:"1.0.0"` line is missing a space after the colon to make it invalid YAML for the scanner
        let yaml = """
            openapi: "3.0.0"
            info:
              title: "Test"
              version:"1.0.0"
            paths: {}
            """

        XCTAssertThrowsError(try _test(yaml, diagnostics: collector)) { error in
            if let exitError = error as? ExitCode {
                XCTAssertEqual(exitError, ExitCode.failure)
            } else {
                XCTFail("Thrown error is \(type(of: error)) but should be ExitCode.failure")
            }

            XCTAssertEqual(collector.allOutput.count, 1)
            if let actualDiagnostic = collector.allOutput.first {
                let expectedDiagnostic =
                    "/foo.yaml:4: error: could not find expected ':' while scanning a simple key in line 4, column 3\n"
                XCTAssertEqual(actualDiagnostic, expectedDiagnostic)
            }
        }
    }

    func testEmitsMissingInfoKeyOpenAPIParsingError() throws {
        let collector = TestingDiagnosticsCollector()
        // The `smurf` line should be `info` in a real OpenAPI document.
        let yaml = """
            openapi: "3.0.0"
            smurf:
              title: "Test"
              version: "1.0.0"
            paths: {}
            """

        XCTAssertThrowsError(try _test(yaml, diagnostics: collector)) { error in
            if let exitError = error as? ExitCode {
                XCTAssertEqual(exitError, ExitCode.failure)
            } else {
                XCTFail("Thrown error is \(type(of: error)) but should be ExitCode.failure")
            }

            XCTAssertEqual(collector.allOutput.count, 1)
            if let actualDiagnostic = collector.allOutput.first {
                let expectedDiagnostic =
                    "/foo.yaml: error: Expected to find `info` key in the root Document object but it is missing."
                XCTAssertEqual(actualDiagnostic, expectedDiagnostic)
            }
        }
    }

    func testEmitsComplexOpenAPIParsingError() throws {
        let collector = TestingDiagnosticsCollector()
        // The `resonance` line should be `response` in a real OpenAPI document.
        let yaml = """
            openapi: "3.0.0"
            info:
              title: "Test"
              version: "1.0.0"
            paths:
              /system:
                get:
                  description: This is a unit test.
                  resonance:
                    '200':
                      description: Success
            """

        XCTAssertThrowsError(try _test(yaml, diagnostics: collector)) { error in
            if let exitError = error as? ExitCode {
                XCTAssertEqual(exitError, ExitCode.failure)
            } else {
                XCTFail("Thrown error is \(type(of: error)) but should be ExitCode.failure")
            }

            XCTAssertEqual(collector.allOutput.count, 1)
            if let actualDiagnostic = collector.allOutput.first {
                let expectedDiagnostic =
                    "/foo.yaml: error: Expected to find `responses` key for the **GET** endpoint under `/system` but it is missing."
                XCTAssertEqual(actualDiagnostic, expectedDiagnostic)
            }
        }
    }

    private func _test(_ yaml: String, diagnostics: DiagnosticCollector) throws -> ParsedOpenAPIRepresentation {
        try YamsParser()
            .parseOpenAPI(
                .init(
                    absolutePath: URL(fileURLWithPath: "/foo.yaml"),
                    contents: Data(yaml.utf8)
                ),
                config: .init(mode: .types),
                diagnostics: diagnostics
            )
    }
}

/// Collect all of the diagnostic descriptions for later assertion checks.
class TestingDiagnosticsCollector: DiagnosticCollector {
    var allOutput: [String] = []

    func emit(_ diagnostic: Diagnostic) {
        allOutput.append(diagnostic.description)
    }
}
