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
#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
#else
import struct Foundation.URL
import struct Foundation.Data
#endif
import class Foundation.FileManager
import ArgumentParser
import _OpenAPIGeneratorCore

extension _Tool {
    /// Runs the generator with the specified configuration values.
    /// - Parameters:
    ///   - doc: A path to the OpenAPI document.
    ///   - configs: A list of generator configurations.
    ///   - pluginSource: The source of the generator invocation.
    ///   - outputDirectory: The directory to which the generator writes
    ///   the generated Swift files.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    static func runGenerator(
        doc: URL,
        configs: [Config],
        pluginSource: PluginSource?,
        outputDirectory: URL,
        isDryRun: Bool,
        diagnostics: any DiagnosticCollector & Sendable
    ) async throws {
        let docData: Data
        do {
            docData = try Data(contentsOf: doc)
        } catch {
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
                        outputFileName: config.mode.outputFileName,
                        isDryRun: isDryRun,
                        diagnostics: diagnostics
                    )
                }
            }
            try await group.waitForAll()
        }

        // If from a BuildTool plugin, the generator will have to emit all 3 files
        // (Types.swift, Client.Swift, and Server.swift) regardless of which generator
        // mode was requested, with the caveat that the not-requested files are empty.
        // This is due to a limitation of the build system used by SwiftPM under the hood.
        if pluginSource == .build {
            let nonGeneratedModes = Set(GeneratorMode.allCases).subtracting(configs.map(\.mode))
            for mode in nonGeneratedModes.sorted() {
                try replaceFileContents(
                    inDirectory: outputDirectory,
                    fileName: mode.outputFileName,
                    with: { Data() },
                    isDryRun: isDryRun
                )
            }
        }
    }

    /// Runs the generator with the specified configuration values.
    /// - Parameters:
    ///   - doc: A path to the OpenAPI document.
    ///   - docData: The raw contents of the OpenAPI document.
    ///   - config: A set of configuration values for the generator.
    ///   - outputDirectory: The directory to which the generator writes
    ///   the generated Swift file.
    ///   - outputFileName: The file name to which the generator writes
    ///   the generated Swift file.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    static func runGenerator(
        doc: URL,
        docData: Data,
        config: Config,
        outputDirectory: URL,
        outputFileName: String,
        isDryRun: Bool,
        diagnostics: any DiagnosticCollector
    ) throws {
        try replaceFileContents(
            inDirectory: outputDirectory,
            fileName: outputFileName,
            with: {
                let output = try _OpenAPIGeneratorCore.runGenerator(
                    input: .init(absolutePath: doc, contents: docData),
                    config: config,
                    diagnostics: diagnostics
                )
                return output.contents
            },
            isDryRun: isDryRun
        )
    }

    /// Evaluates a closure to generate file data and writes the data to disk
    /// if the data is different than the current file contents. Will write to disk
    /// only if `isDryRun` is set as `false`.
    /// - Parameters:
    ///   - path: A path to the file.
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
            try fileManager.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
            try data.write(to: path)
        }
    }
}
