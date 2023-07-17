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
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    static func runGenerator(
        doc: URL,
        configs: [Config],
        pluginSource: PluginSource?,
        outputDirectory: URL,
        diagnostics: any DiagnosticCollector
    ) throws {
        let docData: Data
        do {
            docData = try Data(contentsOf: doc)
        } catch {
            throw ValidationError("Failed to load the OpenAPI document at path \(doc.path), error: \(error)")
        }
        for config in configs {
            try runGenerator(
                doc: doc,
                docData: docData,
                config: config,
                outputDirectory: outputDirectory,
                outputFileName: config.mode.outputFileName,
                diagnostics: diagnostics
            )
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
                    with: { Data() }
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
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    static func runGenerator(
        doc: URL,
        docData: Data,
        config: Config,
        outputDirectory: URL,
        outputFileName: String,
        diagnostics: any DiagnosticCollector
    ) throws {
        let didChange = try replaceFileContents(
            inDirectory: outputDirectory,
            fileName: outputFileName
        ) {
            let output = try _OpenAPIGeneratorCore.runGenerator(
                input: .init(absolutePath: doc, contents: docData),
                config: config,
                diagnostics: diagnostics
            )
            return output.contents
        }
        print("File \(outputFileName): \(didChange ? "changed" : "unchanged")")
    }

    /// Evaluates a closure to generate file data and writes the data to disk
    /// if the data is different than the current file contents.
    /// - Parameters:
    ///   - path: A path to the file.
    ///   - contents: A closure evaluated to produce the file contents data.
    /// - Throws: When writing to disk fails.
    /// - Returns: `true` if the generated contents changed, otherwise `false`.
    @discardableResult
    static func replaceFileContents(
        inDirectory outputDirectory: URL,
        fileName: String,
        with contents: () throws -> Data
    ) throws -> Bool {
        let fm = FileManager.default

        // Create directory if it doesn't exist.
        if !fm.fileExists(atPath: outputDirectory.path) {
            try fm.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
        }

        let path = outputDirectory.appendingPathComponent(fileName)
        let data = try contents()
        guard fm.fileExists(atPath: path.path) else {
            return fm.createFile(atPath: path.path, contents: data)
        }
        let existingData = try? Data(contentsOf: path)
        guard existingData == data else {
            try data.write(to: path)
            return true
        }
        return false
    }
}
