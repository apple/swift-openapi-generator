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
    
    /// A structure that defines ANSI escape codes for different colors in the terminal output.
    ///
    /// You can use these codes to change the color of the text printed by the `print` function or other methods that write to the standard output. To reset the text color to the default, use the `reset` code.
    ///
    /// For example, to print "Hello" in red and "World" in green, you can use:
    /// ```swift
    /// print(
    ///     CommandLineColors.red +
    ///      "Hello" +
    ///        CommandLineColors.green +
    ///         "World" +
    ///          CommandLineColors.reset
    /// )
    /// ```
    struct CommandLineColors {
        /// The ANSI escape code for resetting the text color and style to the default.
        static let reset = "\u{001B}[0;0m"
        /// The ANSI escape code for changing the text color to red.
        static let red = "\u{001B}[0;31m"
        /// The ANSI escape code for changing the text color to green.
        static let green = "\u{001B}[0;32m"
    }


    /// Runs the generator with the specified configuration values.
    /// - Parameters:
    ///   - doc: A path to the OpenAPI document.
    ///   - configs: A list of generator configurations.
    ///   - isPluginInvocation: A Boolean value that indicates whether this
    ///   generator invocation is coming from a SwiftPM plugin.
    ///   - outputDirectory: The directory to which the generator writes
    ///   the generated Swift files.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    static func runGenerator(
        doc: URL,
        configs: [Config],
        isPluginInvocation: Bool,
        outputDirectory: URL,
        isDryRun: Bool,
        diagnostics: any DiagnosticCollector
    ) throws {
        let docData: Data
        do {
            docData = try Data(contentsOf: doc)
        } catch {
            throw ValidationError("Failed to load the OpenAPI document at path \(doc.path), error: \(error)")
        }
        let filePathForMode: (GeneratorMode) -> URL = { mode in
            outputDirectory.appendingPathComponent(mode.outputFileName)
        }
        if isDryRun {
            print("--------------------------------")
            print("Dry run mode: No files will be created or modified")
        }
        for config in configs {
            try runGenerator(
                doc: doc,
                docData: docData,
                config: config,
                outputFilePath: filePathForMode(config.mode),
                isDryRun: isDryRun,
                diagnostics: diagnostics
            )
        }
        if isPluginInvocation {
            let nonGeneratedModes = Set(GeneratorMode.allCases).subtracting(configs.map(\.mode))
            for mode in nonGeneratedModes.sorted() {
                let path = filePathForMode(mode)
                try replaceFileContents(at: path, with: { Data() }, isDryRun: isDryRun)
            }
        }
    }

    /// Runs the generator with the specified configuration values.
    /// - Parameters:
    ///   - doc: A path to the OpenAPI document.
    ///   - docData: The raw contents of the OpenAPI document.
    ///   - config: A set of configuration values for the generator.
    ///   - outputFilePath: The directory to which the generator writes
    ///   the generated Swift files.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run.
    ///   - diagnostics: A collector for diagnostics emitted by the generator.
    static func runGenerator(
        doc: URL,
        docData: Data,
        config: Config,
        outputFilePath: URL,
        isDryRun: Bool,
        diagnostics: any DiagnosticCollector
    ) throws {
        let didChange = try replaceFileContents(
            at: outputFilePath,
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
        if !isDryRun {
            print("File \(outputFilePath.lastPathComponent): \(didChange ? "changed" : "unchanged")")
        }
    }

    /// Evaluates a closure to generate file data and writes the data to disk
    /// if the data is different than the current file contents.
    /// - Parameters:
    ///   - path: A path to the file.
    ///   - contents: A closure evaluated to produce the file contents data.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be a dry run. File system changes will not be written to disk in this mode.
    /// - Throws: When writing to disk fails.
    /// - Returns: `true` if the generated contents changed, otherwise `false`.
    @discardableResult
    static func replaceFileContents(
        at path: URL,
        with contents: () throws -> Data,
        isDryRun: Bool
    ) throws -> Bool {
        let data = try contents()
        let didChange: Bool
        if FileManager.default.fileExists(atPath: path.path) {
            let existingData = try? Data(contentsOf: path)
            didChange = existingData != data
            if didChange {
                print(CommandLineColors.red + "File \(path.lastPathComponent) will be overwritten." + CommandLineColors.reset)
            } else {
                print(CommandLineColors.green + "File \(path.lastPathComponent) will remain unchanged." + CommandLineColors.reset)
            }
        } else {
            print(CommandLineColors.green + "File \(path.lastPathComponent) does not exist.\nCreating new file..." + CommandLineColors.reset)
            didChange = true
        }
        if didChange {
            if isDryRun {
                print(CommandLineColors.green + "Writing data to \(path.lastPathComponent)..." + CommandLineColors.reset)
            } else {
                try data.write(to: path)
            }
        }
        return didChange
    }
}
