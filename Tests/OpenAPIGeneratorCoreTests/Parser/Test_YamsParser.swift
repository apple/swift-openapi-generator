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
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.0.0"))
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.0.1"))
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.0.2"))
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.0.3"))
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.0.4"))
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.1.0"))
        XCTAssertNoThrow(try _test(openAPIVersionString: "3.1.1"))

        let expected1 =
            "/foo.yaml: error: Unsupported document version: openapi: 3.2.0. Please provide a document with OpenAPI versions in the 3.0.x or 3.1.x sets."
        assertThrownError(try _test(openAPIVersionString: "3.2.0"), expectedDiagnostic: expected1)

        let expected2 =
            "/foo.yaml: error: Unsupported document version: openapi: 2.0. Please provide a document with OpenAPI versions in the 3.0.x or 3.1.x sets."
        assertThrownError(try _test(openAPIVersionString: "2.0"), expectedDiagnostic: expected2)
    }

    private func _test(openAPIVersionString: String) throws -> ParsedOpenAPIRepresentation {
        try _test(
            """
            openapi: "\(openAPIVersionString)"
            info:
              title: "Test"
              version: "1.0.0"
            paths: {}
            """
        )
    }

    func testMissingOpenAPIVersionError() throws {
        // No `openapi` key in the YAML
        let yaml = """
            info:
              title: "Test"
              version: "1.0.0"
            paths: {}
            """

        let expected =
            "/foo.yaml: error: No key named openapi found. Please provide a valid OpenAPI document with OpenAPI versions in the 3.0.x or 3.1.x sets."
        assertThrownError(try _test(yaml), expectedDiagnostic: expected)
    }

    func testEmitsYamsParsingError() throws {
        // The `title: "Test"` line is indented the wrong amount to make the YAML invalid for the parser
        let yaml = """
            openapi: "3.1.0"
            info:
             title: "Test"
              version: 1.0.0
            paths: {}
            """

        let expected =
            "/foo.yaml:3: error: did not find expected key while parsing a block mapping in line 3, column 2\n"
        assertThrownError(try _test(yaml), expectedDiagnostic: expected)
    }

    func testEmitsYamsScanningError() throws {
        // The `version:"1.0.0"` line is missing a space after the colon to make it invalid YAML for the scanner
        let yaml = """
            openapi: "3.1.0"
            info:
              title: "Test"
              version:"1.0.0"
            paths: {}
            """

        let expected =
            "/foo.yaml:4: error: could not find expected ':' while scanning a simple key in line 4, column 3\n"
        assertThrownError(try _test(yaml), expectedDiagnostic: expected)
    }

    func testEmitsMissingInfoKeyOpenAPIParsingError() throws {
        // The `smurf` line should be `info` in a real OpenAPI document.
        let yaml = """
            openapi: "3.1.0"
            smurf:
              title: "Test"
              version: "1.0.0"
            paths: {}
            """

        let expected = "/foo.yaml: error: Expected to find `info` key in the root Document object but it is missing."
        assertThrownError(try _test(yaml), expectedDiagnostic: expected)
    }

    func testEmitsComplexOpenAPIParsingError() throws {
        // The `resonance` line should be `response` in a real OpenAPI document.
        let yaml = """
            openapi: "3.1.0"
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

        let expected = """
            /foo.yaml: error: Found neither a $ref nor a PathItem in Document.paths['/system']. 

            PathItem could not be decoded because:
            Inconsistency encountered when parsing `Vendor Extension` for the **GET** endpoint under `/system`: Found at least one vendor extension property that does not begin with the required 'x-' prefix. Invalid properties: [ resonance ]..
            """
        assertThrownError(try _test(yaml), expectedDiagnostic: expected)
    }

    func testExtractTopLevelKeysWithValidYAML() {
        let yaml = """
            generate:
              - types
              - server

            featureFlags:
              - nullableSchemas

            additionalImports:
              - Foundation
            """
        let keys = try? YamsParser.extractTopLevelKeys(fromYAMLString: yaml)
        XCTAssertEqual(keys, ["generate", "featureFlags", "additionalImports"])
    }

    func testExtractTopLevelKeysWithInvalidYAML() {
        // `additionalImports` is missing `:` at the end.
        let yaml = """
            generate:
              - types
              - server

            featureFlags:
              - nullableSchemas

            additionalImports
              - Foundation
            """
        XCTAssertThrowsError(try YamsParser.extractTopLevelKeys(fromYAMLString: yaml))
    }

    private func _test(_ yaml: String) throws -> ParsedOpenAPIRepresentation {
        try YamsParser()
            .parseOpenAPI(
                .init(absolutePath: URL(fileURLWithPath: "/foo.yaml"), contents: Data(yaml.utf8)),
                config: .init(mode: .types, access: Config.defaultAccessModifier),
                diagnostics: PrintingDiagnosticCollector()
            )
    }

    private func assertThrownError(
        _ closure: @autoclosure () throws -> ParsedOpenAPIRepresentation,
        expectedDiagnostic: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try closure(), file: file, line: line) { error in
            if let exitError = error as? Diagnostic {
                let actualDiagnostic = exitError.localizedDescription
                XCTAssertEqual(actualDiagnostic, expectedDiagnostic, file: file, line: line)
            } else {
                XCTFail("Thrown error is \(type(of: error)) but should be Diagnostic", file: file, line: line)
            }
        }
    }

}
