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
import _OpenAPIGeneratorCore
import ArgumentParser
import Foundation

extension _GenerateOptions {

    /// Runs the generator using the options provided by the user.
    /// - Parameters:
    ///   - outputDirectory: The directory path to which the generator writes
    ///   the generated Swift files.
    ///   - isPluginInvocation: A Boolean value that indicates whether this
    ///   generator invocation is coming from a SwiftPM plugin, as that forces
    ///   the generator to emit all 3 files (Types.swift, Client.Swift, and
    ///   Server.swift) regardless of which generator mode was requested, with
    ///   the caveat that the not requested files are empty. This is due to
    ///   a limitation of the build system used by SwiftPM under the hood.
    func runGenerator(
        outputDirectory: URL,
        isPluginInvocation: Bool
    ) throws {
        let config = try loadedConfig()
        let sortedModes = try resolvedModes(config)
        let resolvedAdditionalImports = resolvedAdditionalImports(config)
        let configs: [Config] = sortedModes.map {
            .init(
                mode: $0,
                additionalImports: resolvedAdditionalImports
            )
        }
        let diagnostics: DiagnosticCollector
        let finalizeDiagnostics: () throws -> Void
        if let diagnosticsOutputPath {
            let _diagnostics = _YamlFileDiagnosticsCollector(url: diagnosticsOutputPath)
            finalizeDiagnostics = _diagnostics.finalize
            diagnostics = _diagnostics
        } else {
            diagnostics = StdErrPrintingDiagnosticCollector()
            finalizeDiagnostics = {}
        }

        let doc = self.docPath
        print(
            """
            Swift OpenAPI Generator is running with the following configuration:
            - OpenAPI document path: \(doc.path)
            - Configuration path: \(self.config?.path ?? "<none>")
            - Generator modes: \(sortedModes.map(\.rawValue).joined(separator: ", "))
            - Output file names: \(sortedModes.map(\.outputFileName).joined(separator: ", "))
            - Output directory: \(outputDirectory.path)
            - Diagnostics output path: \(diagnosticsOutputPath?.path ?? "<none - logs to stderr>")
            - Current directory: \(FileManager.default.currentDirectoryPath)
            - Is plugin invocation: \(isPluginInvocation)
            - Additional imports: \(resolvedAdditionalImports.isEmpty ? "<none>" : resolvedAdditionalImports.joined(separator: ", "))
            """
        )
        do {
            try _Tool.runGenerator(
                doc: doc,
                configs: configs,
                isPluginInvocation: isPluginInvocation,
                outputDirectory: outputDirectory,
                diagnostics: diagnostics
            )
        } catch let error as Diagnostic {
            // Emit our nice Diagnostics message instead of relying on ArgumentParser output.
            diagnostics.emit(error)
            throw ExitCode.failure
        }
        try finalizeDiagnostics()
    }
}
