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
import _OpenAPIGeneratorCore
import OpenAPIKit
import ArgumentParser

// https://github.com/swiftlang/swift-package-manager/issues/6367
#if !os(Windows)
@testable import swift_openapi_generator
#endif

final class Test_GenerateOptions: XCTestCase {

    var resourcesDirectory: URL! = nil

    /// Setup method called before the invocation of each test method in the class.
    override func setUpWithError() throws {
        resourcesDirectory = try XCTUnwrap(
            Bundle.module.url(forResource: "Resources", withExtension: nil),
            "Could not find reference test resources directory."
        )
    }

    // https://github.com/swiftlang/swift-package-manager/issues/6367
    #if !os(Windows)
    func testRunGeneratorThrowsErrorDiagnostic() async throws {
        let outputDirectory = URL(fileURLWithPath: "/invalid/path")
        let docsDirectory = resourcesDirectory.appendingPathComponent("Docs")
        let docPath = docsDirectory.appendingPathComponent("malformed-openapi.yaml")
        let configPath = docsDirectory.appendingPathComponent("openapi-generator-config.yaml")

        let arguments = [docPath.path, "--config", configPath.path]
        let generator = try _GenerateOptions.parse(arguments)

        do {
            try await generator.runGenerator(outputDirectory: outputDirectory, pluginSource: .build, isDryRun: false)
            XCTFail("Expected to throw an error, but it did not throw")
        } catch let diagnostic as Diagnostic {
            XCTAssertEqual(diagnostic.severity, .error, "Expected diagnostic severity to be `.error`")
        } catch { XCTFail("Expected to throw a Diagnostic `.error`, but threw a different error: \(error)") }
    }

    func testBuildPluginWritesEveryDeclaredOutputForUnrequestedModes() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let documentURL = temporaryDirectory.appendingPathComponent("openapi.yaml")
        try Data(
            """
            openapi: "3.1.0"
            info:
              title: GreetingService
              version: "1.0.0"
            paths: {}
            """
            .utf8
        )
        .write(to: documentURL)

        try await _Tool.runGenerator(
            doc: documentURL,
            configs: [Config(mode: .client, access: .internal, namingStrategy: .defensive)],
            pluginSource: .build,
            outputDirectory: temporaryDirectory,
            isDryRun: false,
            diagnostics: StdErrPrintingDiagnosticCollector()
        )

        for outputFileName in GeneratorMode.allOutputFileNames {
            let outputURL = temporaryDirectory.appendingPathComponent(outputFileName.rawValue)
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Missing \(outputFileName)")
        }
        for outputFileName in GeneratorMode.types.outputFileNames.union(GeneratorMode.server.outputFileNames) {
            let outputURL = temporaryDirectory.appendingPathComponent(outputFileName.rawValue)
            XCTAssertEqual(try Data(contentsOf: outputURL), Data(), "Expected empty \(outputFileName)")
        }
        XCTAssertFalse(try Data(contentsOf: temporaryDirectory.appendingPathComponent("Client.swift")).isEmpty)
    }

    func testRunGeneratorAttachesMacrosFromConfig() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let documentURL = temporaryDirectory.appendingPathComponent("openapi.yaml")
        try Data(
            """
            openapi: "3.1.0"
            info:
              title: PetStore
              version: "1.0.0"
            paths:
              /pets:
                post:
                  operationId: createPet
                  requestBody:
                    $ref: '#/components/requestBodies/PetBody'
                  responses:
                    '200':
                      $ref: '#/components/responses/PetResponse'
                  parameters:
                    - $ref: '#/components/parameters/limit'
            components:
              schemas:
                Pet:
                  type: object
                  properties:
                    name:
                      type: string
              parameters:
                limit:
                  name: limit
                  in: query
                  schema:
                    type: integer
              requestBodies:
                PetBody:
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Pet'
              responses:
                PetResponse:
                  description: A pet.
                  headers:
                    X-Trace:
                      $ref: '#/components/headers/Trace'
              headers:
                Trace:
                  schema:
                    type: string
            """
            .utf8
        )
        .write(to: documentURL)

        let configURL = temporaryDirectory.appendingPathComponent("openapi-generator-config.yaml")
        try Data(
            """
            generate:
              - types
              - client
              - server
            accessModifier: public
            attachedMacros:
              components:
                schemas:
                  - filter: "^Pet$"
                    macros:
                      - name: SchemaMacro
                        arguments:
                          - label: name
                            value: '"Pet"'
                          - label: mode
                            value: .live
                parameters:
                  - filter: "^limit$"
                    macros: [{name: ParameterMacro}]
                requestBodies:
                  - filter: "^PetBody$"
                    macros: [{name: RequestBodyMacro}]
                responses:
                  - filter: "^PetResponse$"
                    macros: [{name: ResponseMacro}]
                headers:
                  - filter: "^Trace$"
                    macros: [{name: HeaderMacro}]
              operations:
                - filter: "^createPet$"
                  operation: [{name: OperationMacro}]
                  input: [{name: InputMacro}]
                  output: [{name: OutputMacro}]
                  clientMethod: [{name: ClientMethodMacro}]
              apiProtocol: [{name: APIProtocolMacro}]
              client: [{name: ClientMacro}]
              server: [{name: ServerMacro}]
            """
            .utf8
        )
        .write(to: configURL)

        let generator = try _GenerateOptions.parse([documentURL.path, "--config", configURL.path])
        try await generator.runGenerator(outputDirectory: temporaryDirectory, pluginSource: nil, isDryRun: false)

        func contents(_ fileName: OutputFileName) throws -> String {
            try String(contentsOf: temporaryDirectory.appendingPathComponent(fileName.rawValue), encoding: .utf8)
        }
        let expectedSnippets: [(OutputFileName, String)] = [
            (.typesComponentsSchemas, "@SchemaMacro(name: \"Pet\", mode: .live)\n        public struct Pet:"),
            (.typesComponentsParameters, "@ParameterMacro\n        public typealias limit ="),
            (.typesComponentsRequestBodies, "@RequestBodyMacro\n        @frozen public enum PetBody:"),
            (.typesComponentsResponses, "@ResponseMacro\n        public struct PetResponse:"),
            (.typesComponentsHeaders, "@HeaderMacro\n        public typealias Trace ="),
            (.typesOperations, "@OperationMacro\n    public enum createPet {"),
            (.typesOperations, "@InputMacro\n        public struct Input:"),
            (.typesOperations, "@OutputMacro\n        @frozen public enum Output:"),
            (.types, "@APIProtocolMacro\npublic protocol APIProtocol:"),
            (.client, "@ClientMacro\npublic struct Client:"),
            (.client, "@ClientMethodMacro\n    public func createPet("),
            (.server, "@ServerMacro\n    public func registerHandlers("),
        ]
        for (fileName, snippet) in expectedSnippets {
            let fileContents = try contents(fileName)
            XCTAssertTrue(fileContents.contains(snippet), "\(fileName.rawValue) doesn't contain:\n\(snippet)")
        }
    }

    func testLoadedConfigRejectsInvalidAttachedMacros() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let configURL = temporaryDirectory.appendingPathComponent("openapi-generator-config.yaml")
        try Data(
            """
            generate:
              - types
            attachedMacros:
              apiProtocol:
                - name: "@Mockable"
            """
            .utf8
        )
        .write(to: configURL)

        let generator = try _GenerateOptions.parse(["openapi.yaml", "--config", configURL.path])
        XCTAssertThrowsError(try generator.loadedConfig()) { error in
            XCTAssertTrue("\(error)".contains("Invalid macro name '@Mockable'"), "\(error)")
        }
    }

    /// Tests that `handleFileOperation` correctly transforms file-not-found errors into user-friendly messages.
    /// This test verifies the error handling works correctly on both macOS and Linux.
    func testHandleFileOperation_FileNotFound() throws {
        let nonExistentFile = URL(fileURLWithPath: "/nonexistent/path/to/file.yaml")

        do {
            _ = try handleFileOperation(at: nonExistentFile, fileDescription: "Configuration file") {
                try Data(contentsOf: nonExistentFile)
            }
            XCTFail("Expected handleFileOperation to throw a ValidationError for missing file")
        } catch let error as ArgumentParser.ValidationError {
            let errorMessage = String(describing: error)
            XCTAssertTrue(
                errorMessage.contains("Configuration file not found at path:"),
                "Expected error message to contain 'Configuration file not found at path:', but got: \(errorMessage)"
            )
            XCTAssertTrue(
                errorMessage.contains(nonExistentFile.path),
                "Expected error message to contain the file path, but got: \(errorMessage)"
            )
            XCTAssertTrue(
                errorMessage.contains("Please ensure the file exists and the path is correct"),
                "Expected error message to contain helpful instructions, but got: \(errorMessage)"
            )
        } catch { XCTFail("Expected ArgumentParser.ValidationError, but got: \(type(of: error)) - \(error)") }
    }

    /// Tests that `handleFileOperation` correctly handles successful file operations.
    func testHandleFileOperation_Success() throws {
        // Create a temporary file for testing
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        let testContent = "test content"
        try testContent.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let data = try handleFileOperation(at: tempFile, fileDescription: "Test file") {
            try Data(contentsOf: tempFile)
        }

        let content = String(data: data, encoding: .utf8)
        XCTAssertEqual(content, testContent, "Expected to read the correct file content")
    }

    /// Tests that `handleFileOperation` correctly wraps non-file-not-found errors.
    func testHandleFileOperation_OtherErrors() throws {
        // Create a file that will cause a different error (e.g., permission denied)
        // On most systems, we can't easily simulate permission errors in tests,
        // so we'll test with a custom error to verify the wrapping behavior
        let testURL = URL(fileURLWithPath: "/some/path")
        let customError = NSError(
            domain: "CustomDomain",
            code: 123,
            userInfo: [NSLocalizedDescriptionKey: "Custom error"]
        )

        do {
            _ = try handleFileOperation(at: testURL, fileDescription: "Test file") { throw customError }
            XCTFail("Expected handleFileOperation to throw an error")
        } catch let error as ArgumentParser.ValidationError {
            let errorMessage = String(describing: error)
            XCTAssertTrue(
                errorMessage.contains("Failed to load test file at path"),
                "Expected error message to contain 'Failed to load test file at path', but got: \(errorMessage)"
            )
            XCTAssertTrue(
                errorMessage.contains(testURL.path),
                "Expected error message to contain the file path, but got: \(errorMessage)"
            )
        } catch { XCTFail("Expected ArgumentParser.ValidationError, but got: \(type(of: error)) - \(error)") }
    }

    /// Tests that `handleFileOperation` works with custom file descriptions.
    func testHandleFileOperation_CustomFileDescription() throws {
        let nonExistentFile = URL(fileURLWithPath: "/nonexistent/path/to/document.yaml")

        do {
            _ = try handleFileOperation(at: nonExistentFile, fileDescription: "OpenAPI document") {
                try Data(contentsOf: nonExistentFile)
            }
            XCTFail("Expected handleFileOperation to throw a ValidationError for missing file")
        } catch let error as ArgumentParser.ValidationError {
            let errorMessage = String(describing: error)
            XCTAssertTrue(
                errorMessage.contains("OpenAPI document not found at path:"),
                "Expected error message to contain 'OpenAPI document not found at path:', but got: \(errorMessage)"
            )
        } catch { XCTFail("Expected ArgumentParser.ValidationError, but got: \(type(of: error)) - \(error)") }
    }

    /// Tests that `resolvedAccessModifier` rejects access modifiers that generated code doesn't compile with.
    func testResolvedAccessModifier() throws {
        let options = try _GenerateOptions.parse(["openapi.yaml"])
        XCTAssertEqual(try options.resolvedAccessModifier(nil), Config.defaultAccessModifier)
        XCTAssertEqual(try options.resolvedAccessModifier(_UserConfig(generate: [], accessModifier: .public)), .public)
        for accessModifier in [AccessModifier.fileprivate, .private] {
            let config = _UserConfig(generate: [], accessModifier: accessModifier)
            XCTAssertThrowsError(try options.resolvedAccessModifier(config)) { error in
                XCTAssertTrue(error is ArgumentParser.ValidationError, "Unexpected error: \(error)")
            }
            let optionsWithFlag = try _GenerateOptions.parse([
                "openapi.yaml", "--access-modifier", accessModifier.rawValue,
            ])
            XCTAssertThrowsError(try optionsWithFlag.resolvedAccessModifier(nil)) { error in
                XCTAssertTrue(error is ArgumentParser.ValidationError, "Unexpected error: \(error)")
            }
        }
    }
    #endif
}
