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
