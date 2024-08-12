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
@testable import swift_openapi_generator

final class Test_GenerateOptions: XCTestCase {

    var resourcesDirectory: URL! = nil

    /// Setup method called before the invocation of each test method in the class.
    override func setUpWithError() throws {
        resourcesDirectory = try XCTUnwrap(
            Bundle.module.url(forResource: "Resources", withExtension: nil),
            "Could not find reference test resources directory."
        )
    }

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
}
