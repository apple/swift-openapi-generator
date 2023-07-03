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
import OpenAPIKit30
import Yams
@testable import _OpenAPIGeneratorCore

struct TestConfig: Encodable {
    var docFilePath: String
    var mode: GeneratorMode
    var additionalImports: [String]?
    var referenceOutputDirectory: String
}

extension TestConfig {
    var asConfig: Config {
        .init(
            mode: mode,
            additionalImports: additionalImports ?? []
        )
    }
}

/// Tests that the generator produces Swift files that match a reference.
class ReferenceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        #if !canImport(FoundationNetworking)
        executionTimeAllowance = 60 * 60
        #endif
    }

    func testPetstore() throws {
        try _test(referenceProjectNamed: .petstore)
    }

    // MARK: - Private

    var referenceTestResourcesDirectory: URL! = nil

    override func setUpWithError() throws {
        self.referenceTestResourcesDirectory = try XCTUnwrap(
            Bundle.module.url(forResource: "Resources", withExtension: nil),
            "Could not find reference test resources directory."
        )
    }

    func performReferenceTest(
        _ referenceTest: TestConfig
    ) throws {
        print(
            """
            \(String(repeating: "=", count: 60))
            Performing reference test
            \(h2("begin test config"))
            \(try YAMLEncoder().encode(referenceTest))
            \(h2("end test config"))
            """
        )

        // Load the doc file into memory
        let docFilePath = referenceTest.docFilePath
        let docFileURL = URL(
            fileURLWithPath: docFilePath,
            relativeTo: referenceTestResourcesDirectory
        )
        let input = InMemoryInputFile(
            absolutePath: docFileURL,
            contents: try Data(contentsOf: docFileURL)
        )

        // Run the requested generator invocation
        let diagnostics: DiagnosticCollector = strictDiagnosticsCollector
        let generatorPipeline = self.makeGeneratorPipeline(
            config: referenceTest.asConfig,
            diagnostics: diagnostics
        )
        let generatedOutputSource = try generatorPipeline.run(input)

        // Write generated sources to temporary directory
        let generatedOutputDir = try self.temporaryDirectory()
        let generatedOutputFile = URL(
            fileURLWithPath: generatedOutputSource.baseName,
            relativeTo: generatedOutputDir
        )
        try generatedOutputSource.contents.write(to: generatedOutputFile)

        // Compare the generated directory with the reference directory
        let referenceOutputDir = URL(
            fileURLWithPath: referenceTest.referenceOutputDirectory,
            relativeTo: referenceTestResourcesDirectory
        )
        let referenceOutputFile =
            referenceOutputDir
            .appendingPathComponent(generatedOutputSource.baseName)
        self.assert(
            contentsOf: generatedOutputFile,
            equalsContentsOf: referenceOutputFile,
            runDiffWhenContentsDiffer: true
        )
    }

    enum ReferenceProjectName: String, Hashable, CaseIterable {
        case petstore

        var fileName: String {
            "\(rawValue).yaml"
        }

        var directoryName: String {
            rawValue.capitalized
        }
    }

    func _test(referenceProjectNamed name: ReferenceProjectName) throws {
        let modes: [GeneratorMode] = [
            .types,
            .client,
            .server,
        ]
        for mode in modes {
            try performReferenceTest(
                .init(
                    docFilePath: "Docs/\(name.fileName)",
                    mode: mode,
                    additionalImports: [],
                    referenceOutputDirectory: "ReferenceSources/\(name.directoryName)"
                )
            )
        }
    }
}

struct StrictDiagnosticsCollector: DiagnosticCollector {
    var test: XCTestCase

    func emit(_ diagnostic: Diagnostic) {
        print("Test emitted diagnostic: \(diagnostic.description)")
        switch diagnostic.severity {
        case .note:
            // no need to fail, just print
            break
        case .warning, .error:
            XCTFail("Failing with a diagnostic: \(diagnostic.description)")
        }
    }
}

extension ReferenceTests {

    var strictDiagnosticsCollector: DiagnosticCollector {
        StrictDiagnosticsCollector(test: self)
    }

    private func makeGeneratorPipeline(
        config: Config,
        diagnostics: DiagnosticCollector
    ) -> GeneratorPipeline {

        let parser = YamsParser()
        let translator = MultiplexTranslator()
        let renderer = TextBasedRenderer()

        return _OpenAPIGeneratorCore.makeGeneratorPipeline(
            parser: parser,
            translator: translator,
            renderer: renderer,
            formatter: { file in
                var newFile = file
                newFile.contents = try newFile.contents.swiftFormatted
                return newFile
            },
            config: config,
            diagnostics: diagnostics
        )
    }

    private func temporaryDirectory(fileManager: FileManager = .default) throws -> URL {
        let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        addTeardownBlock {
            do {
                if fileManager.fileExists(atPath: directoryURL.path) {
                    try fileManager.removeItem(at: directoryURL)
                    XCTAssertFalse(fileManager.fileExists(atPath: directoryURL.path))
                }
            } catch {
                // Treat any errors during file deletion as a test failure.
                XCTFail("Error while deleting temporary directory: \(error)")
            }
        }
        return directoryURL
    }

    private func assert(
        contentsOf generatedFile: URL,
        equalsContentsOf referenceFile: URL,
        message: @autoclosure () -> String = "",
        runDiffWhenContentsDiffer: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if FileManager.default.contentsEqual(atPath: generatedFile.path, andPath: referenceFile.path) {
            return
        }

        let diffOutput: String?
        if runDiffWhenContentsDiffer {
            do {
                diffOutput = try runDiff(reference: referenceFile, actual: generatedFile)
            } catch {
                diffOutput = "failed: \(error)"
            }
        } else {
            diffOutput = nil
        }

        XCTFail(
            """
            \(message())
            Directory contents not equal:
              File under test: \(generatedFile.relativePath)
              Reference file: \(referenceFile.relativePath)
              Diff output: \(diffOutput == nil ? "[disabled]" : "(see below)")
            \(h2("begin diff output"))
            \(diffOutput ?? "[diff disabled]")
            \(h2("end diff output"))
            """,
            file: file,
            line: line
        )
    }

    private func runDiff(reference: URL, actual: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.currentDirectoryURL = self.referenceTestResourcesDirectory
        process.arguments = [
            "git",
            "diff",
            "--no-index",
            "-U5",
            // The following arguments are useful for development.
            //            "--ignore-space-change",
            //            "--ignore-all-space",
            //            "--ignore-blank-lines",
            //            "--ignore-space-at-eol",
            reference.relativePath,
            actual.path,
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let pipeData = try XCTUnwrap(
            pipe.fileHandleForReading.readToEnd(),
            """
            No output from command:
            \(process.executableURL!.path) \(process.arguments!.joined(separator: " "))
            """
        )
        return String(decoding: pipeData, as: UTF8.self)
    }

    func heading(_ message: String, paddingCharacter: Character, lineLength: Int) -> String {
        let prefix = String(repeating: paddingCharacter, count: 3)
        return "\(prefix) \(message.trimmingCharacters(in: .whitespaces)) "
            .padding(toLength: lineLength, withPad: "\(paddingCharacter)", startingAt: 0)
    }

    func h1(_ message: String, lineLength: Int = 60) -> String {
        heading(message, paddingCharacter: "=", lineLength: lineLength)
    }
    func h2(_ message: String, lineLength: Int = 60) -> String {
        heading(message, paddingCharacter: "-", lineLength: lineLength)
    }
}
