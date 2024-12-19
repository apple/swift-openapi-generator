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
    ///   - pluginSource: The source of the generator invocation if from a plugin.
    ///   - isDryRun: A Boolean value that indicates whether this invocation should
    ///   be run in a testing mode to preview all the operations being carried out without
    ///   making any actual changes.
    /// - Throws: An error if any part of the generator execution encounters an issue, including loading configuration,
    /// resolving options, generating code, and handling diagnostics.
    func runGenerator(outputDirectory: URL, pluginSource: PluginSource?, isDryRun: Bool) async throws {
        let config = try loadedConfig()
        let sortedModes = try resolvedModes(config)
        let resolvedAccessModifier = resolvedAccessModifier(config) ?? Config.defaultAccessModifier
        let resolvedAdditionalImports = resolvedAdditionalImports(config)
        let resolvedNamingStragy = resolvedNamingStrategy(config)
        let resolvedNameOverrides = resolvedNameOverrides(config)
        let resolvedFeatureFlags = resolvedFeatureFlags(config)
        let configs: [Config] = sortedModes.map {
            .init(
                mode: $0,
                access: resolvedAccessModifier,
                additionalImports: resolvedAdditionalImports,
                filter: config?.filter,
                namingStrategy: resolvedNamingStragy,
                nameOverrides: resolvedNameOverrides,
                featureFlags: resolvedFeatureFlags
            )
        }
        let (diagnostics, finalizeDiagnostics) = preparedDiagnosticsCollector(outputPath: diagnosticsOutputPath)
        let doc = self.docPath
        print(
            """
            Swift OpenAPI Generator is running with the following configuration:
            - OpenAPI document path: \(doc.path)
            - Configuration path: \(self.config?.path ?? "<none>")
            - Generator modes: \(sortedModes.map(\.rawValue).joined(separator: ", "))
            - Access modifier: \(resolvedAccessModifier.rawValue)
            - Naming strategy: \(resolvedNamingStragy.rawValue)
            - Name overrides: \(resolvedNameOverrides.isEmpty ? "<none>" : resolvedNameOverrides
                .sorted(by: { $0.key < $1.key })
                .map { "\"\($0.key)\"->\"\($0.value)\"" }.joined(separator: ", "))
            - Feature flags: \(resolvedFeatureFlags.isEmpty ? "<none>" : resolvedFeatureFlags.map(\.rawValue).joined(separator: ", "))
            - Output file names: \(sortedModes.map(\.outputFileName).joined(separator: ", "))
            - Output directory: \(outputDirectory.path)
            - Diagnostics output path: \(diagnosticsOutputPath?.path ?? "<none - logs to stderr>")
            - Current directory: \(FileManager.default.currentDirectoryPath)
            - Plugin source: \(pluginSource?.rawValue ?? "<none>")
            - Is dry run: \(isDryRun)
            - Additional imports: \(resolvedAdditionalImports.isEmpty ? "<none>" : resolvedAdditionalImports.joined(separator: ", "))
            """
        )
        do {
            try await _Tool.runGenerator(
                doc: doc,
                configs: configs,
                pluginSource: pluginSource,
                outputDirectory: outputDirectory,
                isDryRun: isDryRun,
                diagnostics: diagnostics
            )
            try finalizeDiagnostics()
        } catch let error as Diagnostic {
            // Emit our nice Diagnostics message instead of relying on ArgumentParser output.
            try diagnostics.emit(error)
            try finalizeDiagnostics()
            throw ExitCode.failure
        } catch {
            try finalizeDiagnostics()
            throw error
        }
    }
}
