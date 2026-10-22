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
import struct Foundation.URL
import struct Foundation.Data
import class Foundation.FileManager
import ArgumentParser
import _OpenAPIGeneratorCore

/// Describes what the generator does with the files it produces.
enum OutputFileHandling: String {

    /// Writes the files to disk, skipping files that are already up to date,
    /// and prints each operation.
    case write

    /// Prints each operation, without writing to disk.
    case dryRun

    /// Only returns the URLs of the files that would be written, without
    /// reading or processing the OpenAPI document.
    case list
}

extension _Tool {
    /// Runs the generator with the specified configuration values.
    /// - Parameters:
    ///   - doc: A path to the OpenAPI document.
    ///   - configs: A list of generator configurations.
    ///   - pluginSource: The source of the generator invocation.
    ///   - outputDirectory: The directory to which the generator writes
    ///   the generated Swift files.
    ///   - outputFileHandling: What the generator does with the files it produces.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    /// - Returns: The URLs of all the files that the generator writes, or would write, sorted by path.
    /// - Throws: An error if there are issues loading the OpenAPI document,
    ///  running the generator for each configuration, or handling diagnostics.
    @discardableResult static func runGenerator(
        doc: URL,
        configs: [Config],
        pluginSource: PluginSource?,
        outputDirectory: URL,
        outputFileHandling: OutputFileHandling,
        diagnostics: any DiagnosticCollector & Sendable
    ) async throws -> [URL] {
        // The output file names depend only on the generator modes, not on the OpenAPI document,
        // so listing them doesn't require processing the document.
        let outputModes = pluginSource == .build ? GeneratorMode.allCases : configs.map(\.mode)
        let outputFileURLs = Set(outputModes.flatMap(\.outputFileNames)).map(\.rawValue).sorted()
            .map { outputDirectory.appendingPathComponent($0) }
        if outputFileHandling == .list { return outputFileURLs }
        let isDryRun = outputFileHandling == .dryRun

        let docData: Data
        do { docData = try Data(contentsOf: doc) } catch {
            throw ValidationError("Failed to load the OpenAPI document at path \(doc.path), error: \(error)")
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for config in configs {
                group.addTask {
                    try runGenerator(
                        doc: doc,
                        docData: docData,
                        config: config,
                        outputDirectory: outputDirectory,
                        isDryRun: isDryRun,
                        diagnostics: diagnostics
                    )
                }
            }
            try await group.waitForAll()
        }

        // If from a BuildTool plugin, the generator must emit every declared output
        // regardless of which generator modes were requested, with the caveat that
        // the outputs for non-requested modes are empty.
        // This is due to a limitation of the build system used by SwiftPM under the hood.
        if pluginSource == .build {
            let nonGeneratedModes = Set(GeneratorMode.allCases).subtracting(configs.map(\.mode))
            for mode in nonGeneratedModes.sorted() {
                for outputFileName in OutputFileName.allCases where mode.outputFileNames.contains(outputFileName) {
                    try replaceFileContents(
                        inDirectory: outputDirectory,
                        fileName: outputFileName.rawValue,
                        with: { Data() },
                        isDryRun: isDryRun
                    )
                }
            }
        }
        return outputFileURLs
    }

    /// Runs the generator with the specified configuration values.
    /// - Parameters:
    ///   - doc: A path to the OpenAPI document.
    ///   - docData: The raw contents of the OpenAPI document.
    ///   - config: A set of configuration values for the generator.
    ///   - outputDirectory: The directory to which the generator writes
    ///   the generated Swift files.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    /// - Throws: An error if there are issues loading the OpenAPI document,
    ///  running the generator for each configuration, or handling diagnostics.
    static func runGenerator(
        doc: URL,
        docData: Data,
        config: Config,
        outputDirectory: URL,
        isDryRun: Bool,
        diagnostics: any DiagnosticCollector
    ) throws {
        let outputs = try _OpenAPIGeneratorCore.runGenerator(
            input: .init(absolutePath: doc, contents: docData),
            config: config,
            diagnostics: diagnostics
        )
        for output in outputs {
            try replaceFileContents(
                inDirectory: outputDirectory,
                fileName: output.baseName,
                with: { output.contents },
                isDryRun: isDryRun
            )
        }
    }

    /// Evaluates a closure to generate file data and writes the data to disk
    /// if the data is different than the current file contents. Will write to disk
    /// only if `isDryRun` is set as `false`.
    /// - Parameters:
    ///   - outputDirectory: The directory where the file is located.
    ///   - fileName: The name of the file.
    ///   - contents: A closure evaluated to produce the file contents data.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run. File system changes will not be written to disk in this mode.
    /// - Throws: When writing to disk fails.
    static func replaceFileContents(
        inDirectory outputDirectory: URL,
        fileName: String,
        with contents: () throws -> Data,
        isDryRun: Bool
    ) throws {
        let fileManager = FileManager.default
        let path = outputDirectory.appendingPathComponent(fileName)
        let data = try contents()

        if let existingData = try? Data(contentsOf: path), existingData == data {
            print("File \(path.lastPathComponent) already up to date.")
            return
        }
        print("Writing data to file \(path.lastPathComponent)...")
        if !isDryRun {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try data.write(to: path)
        }
    }
}
