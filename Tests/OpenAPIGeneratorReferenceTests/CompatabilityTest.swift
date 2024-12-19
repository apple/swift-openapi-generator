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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenAPIKit
import OpenAPIKit30
import OpenAPIKitCompat
import XCTest
import Yams
@testable import _OpenAPIGeneratorCore

final class CompatibilityTest: XCTestCase {
    let compatibilityTestEnabled = getBoolEnv("SWIFT_OPENAPI_COMPATIBILITY_TEST_ENABLE") ?? false
    let compatibilityTestSkipBuild = getBoolEnv("SWIFT_OPENAPI_COMPATIBILITY_TEST_SKIP_BUILD") ?? false
    let compatibilityTestParallelCodegen = getBoolEnv("SWIFT_OPENAPI_COMPATIBILITY_TEST_PARALLEL_CODEGEN") ?? false
    let compatibilityTestNumBuildJobs = getIntEnv("SWIFT_OPENAPI_COMPATIBILITY_TEST_NUM_BUILD_JOBS")

    /// Setup method called before the invocation of each test method in the class.
    override func setUp() async throws {
        continueAfterFailure = false
        try XCTSkipUnless(compatibilityTestEnabled)
        if _isDebugAssertConfiguration() { log("Warning: Compatility test running in debug mode") }
    }

    func testAWSLambdaRuntime() async throws {
        try await _test(
            "https://raw.githubusercontent.com/aws/aws-lambda-dotnet/7a516b80d83a5c5f5d951158b16b8f76120035cc/Libraries/src/Amazon.Lambda.RuntimeSupport/Client/runtime-api.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testAzureIOTIdentityService() async throws {
        try await _test(
            "https://raw.githubusercontent.com/Azure/iot-identity-service/6404c3bebcc03f12c441c5b018803256bfe1fffe/key/aziot-keyd/openapi/2021-05-01.yaml",
            license: .mit,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testBox() async throws {
        try await _test(
            "https://raw.githubusercontent.com/box/box-openapi/98f51911398fb3f997b2ce0666f11f37065fc4c9/openapi.json",
            license: .apache,
            expectedDiagnostics: [
                "Multipart request bodies must always be required, but found an optional one - skipping. Mark as `required: true` to get this body generated.",
                "A property name only appears in the required list, but not in the properties map - this is likely a typo; skipping this property.",
            ],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testCiscoMindmeld() async throws {
        try await _test(
            "https://raw.githubusercontent.com/cisco/mindmeld/bd3547d5c1bd092dbd4a64a90528dfc2e2b3844a/mindmeld/openapi/custom_action.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testCloudHypervisor() async throws {
        try await _test(
            "https://raw.githubusercontent.com/cloud-hypervisor/cloud-hypervisor/2b457584e06fb72c0256433141731750c58eb6b5/vmm/src/api/openapi/cloud-hypervisor.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testDiscourse() async throws {
        try await _test(
            "https://raw.githubusercontent.com/discourse/discourse_api_docs/8182f1b21ca62cc9ac85fd3a82cae8304033a672/openapi.yml",
            license: .apache,
            expectedDiagnostics: [
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found nothing but unsupported attributes..",
                "Multipart request bodies must always be required, but found an optional one - skipping. Mark as `required: true` to get this body generated.",
            ],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testGithub() async throws {
        try await _test(
            "https://raw.githubusercontent.com/github/rest-api-description/322663c9c909974af16363b4dc0873c428bdbe34/descriptions-next/api.github.com/api.github.com.yaml",
            license: .mit,
            expectedDiagnostics: [
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: array. Specifically, attributes for these other types: [\"object\"].",
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"object\"].",
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found nothing but unsupported attributes..",
                "Schema warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"].",
                "Validation warning: Inconsistency encountered when parsing `Schema`: A schema contains properties for multiple types of schemas, namely: [\"array\", \"object\"]..",
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"].",
                "A property name only appears in the required list, but not in the properties map - this is likely a typo; skipping this property.",
                "Schema warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: array. Specifically, attributes for these other types: [\"object\"].",
                "Schema warning: Inconsistency encountered when parsing `Schema`: A schema contains properties for multiple types of schemas, namely: [\"array\", \"object\"]..",
                "Schema \"null\" is not supported, reason: \"schema type\", skipping",
            ],
            skipBuild: true
        )
    }

    func testGithubEnterprise() async throws {
        try await _test(
            "https://raw.githubusercontent.com/github/rest-api-description/322663c9c909974af16363b4dc0873c428bdbe34/descriptions-next/ghes-3.7/ghes-3.7.yaml",
            license: .mit,
            expectedDiagnostics: [
                "Multipart request bodies must always be required, but found an optional one - skipping. Mark as `required: true` to get this body generated.",
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found nothing but unsupported attributes..",
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"].",
                "A property name only appears in the required list, but not in the properties map - this is likely a typo; skipping this property.",
                "Validation warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"object\"].",
                "Schema warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"].",
                "Schema \"null\" is not supported, reason: \"schema type\", skipping",
            ],
            skipBuild: true
        )
    }

    func testKubernetes() async throws {
        try await _test(
            "https://raw.githubusercontent.com/kubernetes/kubernetes/599fdb7adde5658dadb6a149c40624b4342fc909/api/openapi-spec/v3/api__v1_openapi.json",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testNetflixConsoleMe() async throws {
        try await _test(
            "https://raw.githubusercontent.com/Netflix/consoleme/774420462b0190b1bfa78aa73d39e20044f52db9/swagger.yaml",
            license: .apache,
            expectedDiagnostics: [
                "A property name only appears in the required list, but not in the properties map - this is likely a typo; skipping this property."
            ],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testOpenAI() async throws {
        try await _test(
            "https://raw.githubusercontent.com/openai/openai-openapi/75eebb4477355ddb3abe18615108e02cf6fdca42/openapi.yaml",
            license: .mit,
            expectedDiagnostics: [
                "A property name only appears in the required list, but not in the properties map - this is likely a typo; skipping this property."
            ],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testOpenAPIExamplesPetstore() async throws {
        try await _test(
            "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/9dff244e5708fbe16e768738f4f17cf3fddf4066/examples/v3.0/petstore.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testOpenAPIExamplesPetstoreExpanded() async throws {
        try await _test(
            "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/9dff244e5708fbe16e768738f4f17cf3fddf4066/examples/v3.0/petstore-expanded.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testOpenAPIExamplesAPIWithExamples() async throws {
        try await _test(
            "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/9dff244e5708fbe16e768738f4f17cf3fddf4066/examples/v3.0/api-with-examples.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testOpenAPIExamplesCallbackExample() async throws {
        try await _test(
            "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/9dff244e5708fbe16e768738f4f17cf3fddf4066/examples/v3.0/callback-example.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testOpenAPIExamplesLinkExample() async throws {
        try await _test(
            "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/9dff244e5708fbe16e768738f4f17cf3fddf4066/examples/v3.0/link-example.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }

    func testSwiftPackageRegistry() async throws {
        try await _test(
            "https://raw.githubusercontent.com/apple/swift-package-manager/ce0ff6f223122c88cbf24a0eca8424664e2fb1f1/Documentation/PackageRegistry/registry.openapi.yaml",
            license: .apache,
            expectedDiagnostics: [],
            skipBuild: compatibilityTestSkipBuild
        )
    }
}

fileprivate extension CompatibilityTest {
    /// Run the compatiblity test harness for a given OpenAPI document URL.
    ///
    /// This function will perform the following steps:
    ///
    /// 1. Download the OpenAPI document.
    /// 2. (Optional) Parse and validate the OpenAPI document using OpenAPIKit.
    /// 3. Run the generator pipeline in all modes.
    /// 4. (Optional) Create and build a Swift package with the generated code from (3).
    ///
    /// - Parameters:
    ///   - documentURL: The URL to the OpenAPI document.
    ///   - license: The license of the OpenAPI document itself. Note, this is not necessarily the license of the code for the service API itself.
    ///   - expectedDiagnostics: A set of diagnostics that should _not_ result in a test failure.
    ///   - skipBuild: A boolean value that indicates whether to skip the Swift package creation and build step.
    /// - Throws: An error of if any step in the compatibility test harness fails.
    func _test(_ documentURL: String, license: License, expectedDiagnostics: Set<String> = [], skipBuild: Bool = false)
        async throws
    {
        let diagnosticsCollector = RecordingDiagnosticCollector()

        // Download the OpenAPI document.
        log("Downloading OpenAPI document: \(documentURL)")
        let documentURL = try XCTUnwrap(URL(string: documentURL))
        let documentData = try await URLSession.shared.data(from: documentURL).0
        let documentSize = ByteCountFormatter.string(fromByteCount: Int64(documentData.count), countStyle: .file)

        // Run the generator.
        log("Generating Swift code (document size: \(documentSize))")
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: documentData)
        let outputs: [GeneratorPipeline.RenderedOutput]
        if compatibilityTestParallelCodegen {
            outputs = try await withThrowingTaskGroup(of: GeneratorPipeline.RenderedOutput.self) { group in
                for mode in GeneratorMode.allCases {
                    group.addTask {
                        let generator = makeGeneratorPipeline(
                            config: Config(mode: mode, access: .public),
                            diagnostics: diagnosticsCollector
                        )
                        return try assertNoThrowWithValue(generator.run(input))
                    }
                }
                return try await group.reduce(into: []) { $0.append($1) }
            }
        } else {
            outputs = try GeneratorMode.allCases.map { mode in
                let generator = makeGeneratorPipeline(
                    config: Config(mode: mode, access: .public),
                    diagnostics: diagnosticsCollector
                )
                return try assertNoThrowWithValue(generator.run(input))
            }
        }
        XCTAssertEqual(Set(diagnosticsCollector.diagnostics.map(\.message)), expectedDiagnostics)
        XCTAssertEqual(outputs.count, 3)

        if !skipBuild {
            // Create Swift package test harness.
            let packageName = "swift-openapi-compatibility-test-\(testCaseName)"
            let packageDir = FileManager.default.temporaryDirectory.appendingPathComponent(
                "\(packageName)-\(UUID().uuidString.prefix(8))",
                isDirectory: true
            )
            defer { try? FileManager.default.removeItem(at: packageDir) }

            log("Creating Swift package: \(packageDir.path)")
            XCTAssertNoThrow(try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true))
            let packageSwiftPath = packageDir.appendingPathComponent("Package.swift", isDirectory: false)
            let packageSwiftContents = """
                // swift-tools-version:5.9
                import PackageDescription
                let package = Package(
                    name: "\(packageName)",
                    platforms: [.macOS(.v13)],
                    dependencies: [.package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0")],
                    targets: [.target(name: "Harness", dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")])]
                )
                """
            XCTAssert(
                FileManager.default.createFile(atPath: packageSwiftPath.path, contents: Data(packageSwiftContents.utf8))
            )

            let targetSourceDirectory = packageDir.appendingPathComponent("Sources", isDirectory: false)
                .appendingPathComponent("Harness", isDirectory: true)
            XCTAssertNoThrow(
                try FileManager.default.createDirectory(at: targetSourceDirectory, withIntermediateDirectories: true)
            )

            // Write the generated source files to the target source directory.
            for output in outputs {
                let outputPath = targetSourceDirectory.appendingPathComponent(output.baseName, isDirectory: false)
                XCTAssert(FileManager.default.createFile(atPath: outputPath.path, contents: output.contents))
            }

            // Build the package.
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [
                "swift", "build", "--package-path", packageDir.path, "-Xswiftc", "-Xllvm", "-Xswiftc",
                "-vectorize-slp=false",
            ]
            if let numBuildJobs = compatibilityTestNumBuildJobs {
                process.arguments!.append(contentsOf: ["-j", String(numBuildJobs)])
            }
            log("Building Swift package: \(process.arguments!)")
            let (stdout, stderr) = (Pipe(), Pipe())
            process.standardOutput = stdout
            process.standardError = stderr
            try process.run()
            process.waitUntilExit()
            XCTAssertEqual(
                process.terminationStatus,
                EXIT_SUCCESS,
                """
                Command failed
                -- command line --
                \(process.executableURL!.path) \(process.arguments!.joined(separator: " "))
                -- sdtout --
                \(String(decoding: try! stdout.fileHandleForReading.readToEnd()!, as: UTF8.self))
                -- stderr --
                \(String(decoding: try! stderr.fileHandleForReading.readToEnd()!, as: UTF8.self))
                --
                """
            )
        }

        log("Finished compatibility test")
    }

    /// A license under which the OpenAPI document can be used for testing.
    enum License {
        case apache  // Apache-2.0
        case mit  // MIT
        case bsd  // BSD-3
    }

    /// Prints a message with the current test name prepended (useful in parallel CI logs).
    func log(_ message: String) { print("\(name) \(message)") }

    var testCaseName: String {
        /// The `name` property is `<test-suite-name>.<test-case-name>` on Linux,
        /// and `-[<test-suite-name> <test-case-name>]` on macOS.
        #if canImport(Darwin)
        return String(name.split(separator: " ", maxSplits: 2).last!.dropLast())
        #elseif os(Linux)
        return String(name.split(separator: ".", maxSplits: 2).last!)
        #else
        #error("Platform not supported")
        #endif
    }
}

/// Records diagnostics into an array for testing.
private final class RecordingDiagnosticCollector: DiagnosticCollector, @unchecked Sendable {
    private let lock = NSLock()
    private var _diagnostics: [Diagnostic] = []
    var diagnostics: [Diagnostic] {
        lock.lock()
        defer { lock.unlock() }
        return _diagnostics
    }
    var verbose: Bool = false

    func emit(_ diagnostic: Diagnostic) {
        lock.lock()
        defer { lock.unlock() }
        _diagnostics.append(diagnostic)
        if verbose { print("Collected diagnostic: \(diagnostic.description)") }
    }
}

private func assertNoThrowWithValue<T>(
    _ body: @autoclosure () throws -> T,
    defaultValue: T? = nil,
    message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) rethrows -> T {
    do { return try body() } catch {
        XCTFail("\(message.map { $0 + ": " } ?? "")unexpected error \(error) thrown", file: file, line: line)
        if let defaultValue = defaultValue { return defaultValue } else { throw error }
    }
}

/// Returns true if `key` is a truthy string, otherwise returns false.
private func getBoolEnv(_ key: String) -> Bool? {
    switch ProcessInfo.processInfo.environment[key]?.lowercased() {
    case .none: return nil
    case "true", "y", "yes", "on", "1": return true
    default: return false
    }
}

private func getIntEnv(_ key: String) -> Int? { ProcessInfo.processInfo.environment[key].flatMap(Int.init(_:)) }

fileprivate extension URLSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        #if canImport(Darwin)
        return try await data(from: url, delegate: nil)
        #elseif os(Linux)
        return try await withCheckedThrowingContinuation { continuation in
            dataTask(with: URLRequest(url: url)) { data, response, error in
                if let error {
                    continuation.resume(with: .failure(error))
                    return
                }
                guard let response else {
                    continuation.resume(with: .failure(URLError(.unknown)))
                    return
                }
                continuation.resume(with: .success((data ?? Data(), response)))
            }
            .resume()
        }
        #else
        #error("Platform not supported")
        #endif
    }
}
