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
import PackagePlugin
import Foundation

@main
struct SwiftOpenAPIGeneratorPlugin {
    enum Error: Swift.Error, CustomStringConvertible, LocalizedError {
        case incompatibleTarget(targetName: String)
        case noConfigFound(targetName: String)
        case noDocumentFound(targetName: String)
        case multiConfigFound(targetName: String, files: [Path])
        case multiDocumentFound(targetName: String, files: [Path])

        var description: String {
            switch self {
            case .incompatibleTarget(let targetName):
                return
                    "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI generator plugin."
            case .noConfigFound(let targetName):
                return
                    "No config file found in the target named '\(targetName)'. Add a file called 'openapi-generator-config.yaml' or 'openapi-generator-config.yml' to the target's source directory. See documentation for details."
            case .noDocumentFound(let targetName):
                return
                    "No OpenAPI document found in the target named '\(targetName)'. Add a file called 'openapi.yaml', 'openapi.yml' or 'openapi.json' (can also be a symlink) to the target's source directory. See documentation for details."
            case .multiConfigFound(let targetName, let files):
                return
                    "Multiple config files found in the target named '\(targetName)', but exactly one is required. Found \(files.map(\.description).joined(separator: " "))."
            case .multiDocumentFound(let targetName, let files):
                return
                    "Multiple OpenAPI documents found in the target named '\(targetName)', but exactly one is required. Found \(files.map(\.description).joined(separator: " "))."
            }
        }

        var errorDescription: String? {
            description
        }
    }

    private var supportedConfigFiles: Set<String> { Set(["yaml", "yml"].map { "openapi-generator-config." + $0 }) }
    private var supportedDocFiles: Set<String> { Set(["yaml", "yml", "json"].map { "openapi." + $0 }) }

    func createBuildCommands(
        pluginWorkDirectory: PackagePlugin.Path,
        tool: (String) throws -> PackagePlugin.PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String
    ) throws -> [Command] {
        let inputFiles = sourceFiles
        let matchedConfigs = inputFiles.filter { supportedConfigFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedConfigs.count > 0 else {
            throw Error.noConfigFound(targetName: targetName)
        }
        guard matchedConfigs.count == 1 else {
            throw Error.multiConfigFound(targetName: targetName, files: matchedConfigs)
        }
        let config = matchedConfigs[0]

        let matchedDocs = inputFiles.filter { supportedDocFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedDocs.count > 0 else {
            throw Error.noDocumentFound(targetName: targetName)
        }
        guard matchedDocs.count == 1 else {
            throw Error.multiDocumentFound(targetName: targetName, files: matchedDocs)
        }
        let doc = matchedDocs[0]
        let genSourcesDir = pluginWorkDirectory.appending("GeneratedSources")
        let outputFiles: [Path] = GeneratorMode.allCases.map { genSourcesDir.appending($0.outputFileName) }
        return [
            .buildCommand(
                displayName: "Running swift-openapi-generator",
                executable: try tool("swift-openapi-generator").path,
                arguments: [
                    "generate", "\(doc)",
                    "--config", "\(config)",
                    "--output-directory", "\(genSourcesDir)",
                    "--is-plugin-invocation",
                ],
                environment: [:],
                inputFiles: [
                    config,
                    doc,
                ],
                outputFiles: outputFiles
            )
        ]
    }
}

extension SwiftOpenAPIGeneratorPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
            throw Error.incompatibleTarget(targetName: target.name)
        }
        return try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectory,
            tool: context.tool,
            sourceFiles: swiftTarget.sourceFiles,
            targetName: target.name
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftOpenAPIGeneratorPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        return try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectory,
            tool: context.tool,
            sourceFiles: target.inputFiles,
            targetName: target.displayName
        )
    }
}
#endif
