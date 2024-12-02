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
import ArgumentParser
import Foundation
import _OpenAPIGeneratorCore

struct _GenerateCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "generate",
        abstract: "Generate Swift files from an OpenAPI document",
        discussion: """
            In addition to providing command line options, you can provide
            a path to a configuration YAML file.

            Any option provided on the command line takes precedence over
            the matching key in the configuration file.

            Example configuration file contents:
            ```yaml
            \(_UserConfig.sample.description.dropLast(1))
            ```
            """
    )

    @OptionGroup var generate: _GenerateOptions

    @Option(
        help:
            "Output directory where the generated files are written. Warning: Replaces any existing files with the same filename. Reserved filenames: \(GeneratorMode.allOutputFileNames.joined(separator: ", "))"
    ) var outputDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    @Option(
        help:
            "Source of invocation if by a plugin. The generator needs to produce all files when invoked as a build plugin, so non-requested modes produce empty files."
    ) var pluginSource: PluginSource?

    @Flag(
        name: .customLong("dry-run"),
        help: "Simulate the command and print the operations, without actually affecting the file system."
    ) var isDryRun: Bool = false

    func run() async throws {
        try await generate.runGenerator(
            outputDirectory: outputDirectory,
            pluginSource: pluginSource,
            isDryRun: isDryRun
        )
    }
}

// MARK: - InvocationSource + ExpressibleByArgument
extension PluginSource: ExpressibleByArgument {}
