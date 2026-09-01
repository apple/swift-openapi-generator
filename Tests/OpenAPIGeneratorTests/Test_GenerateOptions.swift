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

    func testBuildPluginRejectsDynamicDeclarationSplitting() async throws {
        do {
            try await _Tool.runGenerator(
                doc: URL(fileURLWithPath: "/unused/openapi.yaml"),
                configs: [
                    Config(mode: .types, access: .internal, namingStrategy: .defensive, maxDeclarationsPerFile: 100)
                ],
                pluginSource: .build,
                outputDirectory: FileManager.default.temporaryDirectory,
                isDryRun: false,
                diagnostics: StdErrPrintingDiagnosticCollector()
            )
            XCTFail("Expected dynamic declaration splitting to be rejected by the build-tool plugin.")
        } catch let error as ArgumentParser.ValidationError {
            XCTAssertTrue(
                String(describing: error).contains("Dynamic output splitting is not supported by the build-tool plugin")
            )
        }
    }

    func testBuildPluginRejectsDependencyLayers() async throws {
        do {
            try await _Tool.runGenerator(
                doc: URL(fileURLWithPath: "/unused/openapi.yaml"),
                configs: [Config(mode: .types, access: .internal, namingStrategy: .defensive, dependencyLayerCount: 2)],
                pluginSource: .build,
                outputDirectory: FileManager.default.temporaryDirectory,
                isDryRun: false,
                diagnostics: StdErrPrintingDiagnosticCollector()
            )
            XCTFail("Expected dependency layers to be rejected by the build-tool plugin.")
        } catch let error as ArgumentParser.ValidationError {
            XCTAssertTrue(
                String(describing: error).contains("Dynamic output splitting is not supported by the build-tool plugin")
            )
        }
    }

    func testDirectAndCommandPluginGenerationSupportDynamicDeclarationSplitting() async throws {
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
            components:
              schemas:
                First:
                  type: string
                Second:
                  type: string
            """
            .utf8
        )
        .write(to: documentURL)

        let invocations: [(name: String, pluginSource: PluginSource?)] = [("direct", nil), ("command", .command)]
        for (name, pluginSource) in invocations {
            let outputDirectory = temporaryDirectory.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try await _Tool.runGenerator(
                doc: documentURL,
                configs: [
                    Config(mode: .types, access: .internal, namingStrategy: .defensive, maxDeclarationsPerFile: 1)
                ],
                pluginSource: pluginSource,
                outputDirectory: outputDirectory,
                isDryRun: false,
                diagnostics: StdErrPrintingDiagnosticCollector()
            )
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: outputDirectory.appendingPathComponent("Types+Components+Schemas+1.swift").path
                )
            )
        }
    }

    func testDirectAndCommandPluginGenerationSupportDependencyLayers() async throws {
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
            components:
              schemas:
                First:
                  type: string
            """
            .utf8
        )
        .write(to: documentURL)

        let invocations: [(name: String, pluginSource: PluginSource?)] = [("direct", nil), ("command", .command)]
        for (name, pluginSource) in invocations {
            let outputDirectory = temporaryDirectory.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try await _Tool.runGenerator(
                doc: documentURL,
                configs: [Config(mode: .types, access: .internal, namingStrategy: .defensive, dependencyLayerCount: 2)],
                pluginSource: pluginSource,
                outputDirectory: outputDirectory,
                isDryRun: false,
                diagnostics: StdErrPrintingDiagnosticCollector()
            )
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: outputDirectory.appendingPathComponent("Types+Components+Schemas+Layer0.swift").path
                )
            )
        }
    }

    func testLoadsMaximumDeclarationsPerFileFromConfig() throws {
        let configURL = try makeTemporaryConfig(
            """
            generate:
              - types
            output:
              maxDeclarationsPerFile: 100
            """
        )
        defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }

        let options = try _GenerateOptions.parse(["openapi.yaml", "--config", configURL.path])
        let config = try XCTUnwrap(options.loadedConfig())

        XCTAssertEqual(config.output?.maxDeclarationsPerFile, 100)
    }

    func testLoadsComposableDependencyLayerConfiguration() throws {
        let configURL = try makeTemporaryConfig(
            """
            generate:
              - types
            output:
              maxDeclarationsPerFile: 100
              dependencyLayerCount: 4
            """
        )
        defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }

        let options = try _GenerateOptions.parse(["openapi.yaml", "--config", configURL.path])
        let config = try XCTUnwrap(options.loadedConfig())

        XCTAssertEqual(config.output?.maxDeclarationsPerFile, 100)
        XCTAssertEqual(config.output?.dependencyLayerCount, 4)
    }

    func testLoadsDependencyManifestConfiguration() throws {
        let configURL = try makeTemporaryConfig(
            """
            generate:
              - types
            output:
              dependencyLayerCount: 4
              dependencyManifest: OpenAPIDependencyManifest.json
            """
        )
        defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }

        let options = try _GenerateOptions.parse(["openapi.yaml", "--config", configURL.path])
        let config = try XCTUnwrap(options.loadedConfig())

        XCTAssertEqual(config.output?.dependencyManifest, "OpenAPIDependencyManifest.json")
    }

    func testRejectsInvalidDependencyManifestConfiguration() async throws {
        let configurations = [
            ("../manifest.json", "JSON file name without directories"),
            ("manifest.txt", "JSON file name without directories"),
        ]
        for (manifest, expectedMessage) in configurations {
            let configURL = try makeTemporaryConfig(
                """
                generate:
                  - types
                output:
                  dependencyLayerCount: 2
                  dependencyManifest: \(manifest)
                """
            )
            defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }
            let options = try _GenerateOptions.parse(["unused-openapi.yaml", "--config", configURL.path])
            do {
                try await options.runGenerator(
                    outputDirectory: FileManager.default.temporaryDirectory,
                    pluginSource: nil,
                    isDryRun: true
                )
                XCTFail("Expected dependencyManifest=\(manifest) to be rejected.")
            } catch let error as ArgumentParser.ValidationError {
                XCTAssertTrue(String(describing: error).contains(expectedMessage))
            }
        }

        let configURL = try makeTemporaryConfig(
            """
            generate:
              - client
            output:
              dependencyManifest: manifest.json
            """
        )
        defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }
        let options = try _GenerateOptions.parse(["unused-openapi.yaml", "--config", configURL.path])
        do {
            try await options.runGenerator(
                outputDirectory: FileManager.default.temporaryDirectory,
                pluginSource: nil,
                isDryRun: true
            )
            XCTFail("Expected a dependency manifest without layered types generation to be rejected.")
        } catch let error as ArgumentParser.ValidationError {
            XCTAssertTrue(String(describing: error).contains("requires types generation"))
        }
    }

    func testRejectsNonPositiveMaximumDeclarationsPerFileFromConfig() async throws {
        for invalidLimit in [0, -1] {
            let configURL = try makeTemporaryConfig(
                """
                generate:
                  - client
                output:
                  maxDeclarationsPerFile: \(invalidLimit)
                """
            )
            defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }

            let options = try _GenerateOptions.parse(["unused-openapi.yaml", "--config", configURL.path])
            do {
                try await options.runGenerator(
                    outputDirectory: FileManager.default.temporaryDirectory,
                    pluginSource: nil,
                    isDryRun: true
                )
                XCTFail("Expected output.maxDeclarationsPerFile=\(invalidLimit) to be rejected.")
            } catch let error as ArgumentParser.ValidationError {
                XCTAssertTrue(String(describing: error).contains("maxDeclarationsPerFile to be greater than zero"))
            }
        }
    }

    func testRejectsNonPositiveDependencyLayerCountFromConfig() async throws {
        for invalidCount in [0, -1] {
            let configURL = try makeTemporaryConfig(
                """
                generate:
                  - types
                output:
                  dependencyLayerCount: \(invalidCount)
                """
            )
            defer { try? FileManager.default.removeItem(at: configURL.deletingLastPathComponent()) }

            let options = try _GenerateOptions.parse(["unused-openapi.yaml", "--config", configURL.path])
            do {
                try await options.runGenerator(
                    outputDirectory: FileManager.default.temporaryDirectory,
                    pluginSource: nil,
                    isDryRun: true
                )
                XCTFail("Expected output.dependencyLayerCount=\(invalidCount) to be rejected.")
            } catch let error as ArgumentParser.ValidationError {
                XCTAssertTrue(String(describing: error).contains("dependencyLayerCount to be greater than zero"))
            }
        }
    }

    private func makeTemporaryConfig(_ contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let configURL = directory.appendingPathComponent("openapi-generator-config.yaml")
        try Data(contents.utf8).write(to: configURL)
        return configURL
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
    #endif
}
