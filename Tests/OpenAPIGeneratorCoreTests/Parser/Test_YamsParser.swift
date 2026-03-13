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
import Foundation
import Testing
@testable import _OpenAPIGeneratorCore


@Suite("Yams Parser Tests")
struct YamsParserTests {
    
    private func _test(
        openAPIVersionString: String
    ) throws -> ParsedOpenAPIRepresentation {
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
    
    private func _test(
        _ yaml: String
    ) throws -> ParsedOpenAPIRepresentation {
        try YamsParser()
            .parseOpenAPI(
                .init(absolutePath: URL(fileURLWithPath: "/foo.yaml"), contents: Data(yaml.utf8)),
                config: .init(
                    mode: .types,
                    access: Config.defaultAccessModifier,
                    namingStrategy: Config.defaultNamingStrategy
                ),
                diagnostics: PrintingDiagnosticCollector()
            )
    }
        
    private func assertThrownError(
        _ closure: @autoclosure () throws -> ParsedOpenAPIRepresentation,
        expectedDiagnostic: String
    ) {
        do {
            let _ = try closure()
            #expect(Bool(false), "Expected Diagnostic error to be thrown")
        } catch let error as Diagnostic {
            #expect(error.localizedDescription == expectedDiagnostic)
        } catch {
            #expect(Bool(false), "Thrown error is \(type(of: error)) but should be Diagnostic")
        }
    }
    
    @Test("Validates OpenAPI version strings")
    func testVersionValidation() throws {
        let _ = try _test(openAPIVersionString: "3.0.0")
        let _ = try _test(openAPIVersionString: "3.0.1")
        let _ = try _test(openAPIVersionString: "3.0.2")
        let _ = try _test(openAPIVersionString: "3.0.3")
        let _ = try _test(openAPIVersionString: "3.0.4")
        let _ = try _test(openAPIVersionString: "3.1.0")
        let _ = try _test(openAPIVersionString: "3.1.1")
        let _ = try _test(openAPIVersionString: "3.1.2")
        let _ = try _test(openAPIVersionString: "3.2.0")

        let expected1 =
            "/foo.yaml: error: Unsupported document version: openapi: 3.3.0. Please provide a document with OpenAPI versions in the 3.0.x, 3.1.x, or 3.2.x sets."
        assertThrownError(try _test(openAPIVersionString: "3.3.0"), expectedDiagnostic: expected1)

        let expected2 =
            "/foo.yaml: error: Unsupported document version: openapi: 2.0. Please provide a document with OpenAPI versions in the 3.0.x, 3.1.x, or 3.2.x sets."
        assertThrownError(try _test(openAPIVersionString: "2.0"), expectedDiagnostic: expected2)
    }

    
    @Test("Emits OpenAPI parsing error for missing openapi key")
    func testMissingOpenAPIVersionError() throws {
        let yaml = """
            info:
              title: "Test"
              version: "1.0.0"
            paths: {}
            """

        let expected =
            "/foo.yaml: error: No key named openapi found. Please provide a valid OpenAPI document with OpenAPI versions in the 3.0.x, 3.1.x, or 3.2.x sets."
        assertThrownError(try _test(yaml), expectedDiagnostic: expected)
    }

    
    @Test("Emits Yams parsing error for invalid YAML")
    func testEmitsYamsParsingError() throws {
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

    
    @Test("Emits Yams scanning error for invalid YAML")
    func testEmitsYamsScanningError() throws {
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

 
    @Test("Emits OpenAPI parsing error for missing info key")
    func testEmitsMissingInfoKeyOpenAPIParsingError() throws {
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

    
    @Test("Emits complex OpenAPI parsing errors")
    func testEmitsComplexOpenAPIParsingError() throws {
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

    
    @Test("Extracts top-level keys from valid YAML")
    func extractTopLevelKeysWithValidYAML() async throws {
        let yaml = """
            generate:
              - types
              - server

            featureFlags:
              - nullableSchemas

            additionalImports:
              - Foundation
            """
        
        let keys = try YamsParser.extractTopLevelKeys(fromYAMLString: yaml)
        #expect(keys == ["generate", "featureFlags", "additionalImports"])
    }
    
    
    @Test("Extracts top-level keys from invalid YAML")
    func testExtractTopLevelKeysWithInvalidYAML() throws {
        let yaml = """
            generate:
              - types
              - server

            featureFlags:
              - nullableSchemas

            additionalImports
              - Foundation
            """
        
        #expect(throws: (any Error).self) {
            try YamsParser.extractTopLevelKeys(fromYAMLString: yaml)
        }
    }
}
