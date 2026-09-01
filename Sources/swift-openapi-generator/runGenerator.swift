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
import class Foundation.JSONEncoder
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
    ///   - dependencyManifestFileName: The optional dependency manifest file name to write beside Swift outputs.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    /// - Throws: An error if there are issues loading the OpenAPI document,
    ///  running the generator for each configuration, or handling diagnostics.
    static func runGenerator(
        doc: URL,
        configs: [Config],
        pluginSource: PluginSource?,
        outputDirectory: URL,
        isDryRun: Bool,
        dependencyManifestFileName: String? = nil,
        diagnostics: any DiagnosticCollector & Sendable
    ) async throws {
        if pluginSource == .build,
            configs.contains(where: {
                $0.mode == .types && ($0.maxDeclarationsPerFile != nil || $0.dependencyLayerCount != nil)
            })
        {
            throw ValidationError(
                "Dynamic output splitting is not supported by the build-tool plugin because its generated output files must be declared before generation."
            )
        }
        if pluginSource == .build, dependencyManifestFileName != nil {
            throw ValidationError(
                "Dependency manifests are not supported by the build-tool plugin because its output files must be declared before generation."
            )
        }

        let docData: Data
        do { docData = try Data(contentsOf: doc) } catch {
            throw ValidationError("Failed to load the OpenAPI document at path \(doc.path), error: \(error)")
        }

        let generatedOutputs = try await withThrowingTaskGroup(of: [InMemoryOutputFile].self) { group in
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
            var outputs: [InMemoryOutputFile] = []
            for try await generated in group { outputs.append(contentsOf: generated) }
            return outputs
        }

        if let dependencyManifestFileName {
            let manifest = DependencyManifest.make(input: docData, outputs: generatedOutputs)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var encoded = try encoder.encode(manifest)
            encoded.append(Data("\n".utf8))
            try replaceFileContents(
                inDirectory: outputDirectory,
                fileName: dependencyManifestFileName,
                with: { encoded },
                isDryRun: isDryRun
            )
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
    /// - Returns: The in-memory outputs that were written to disk.
    static func runGenerator(
        doc: URL,
        docData: Data,
        config: Config,
        outputDirectory: URL,
        isDryRun: Bool,
        diagnostics: any DiagnosticCollector
    ) throws -> [InMemoryOutputFile] {
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
        return outputs
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
