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
        case multiTargetFound(targetNames: [String])
        case noConfigFound(targetName: String)
        case noDocumentFound(targetName: String)
        case multiConfigFound(targetName: String, files: [Path])
        case multiDocumentFound(targetName: String, files: [Path])

        var description: String {
            switch self {
            case .incompatibleTarget(let targetName):
                return
                    "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI generator plugin."
            case .multiTargetFound(let targetNames):
                return "Please choose a specific target for the OpenAPI Generator Command plugin. This Command plugin can't run on multiple targets at the same time. The current target names are: \(targetNames)"
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

    func runCommand(
        pluginWorkDirectory: PackagePlugin.Path,
        tool: (String) throws -> PackagePlugin.PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String
    ) throws {
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

        let tool = try tool("swift-openapi-generator")
        let toolUrl = URL(fileURLWithPath: tool.path.string)
        let process = Process()
        process.executableURL = toolUrl
        process.arguments = [
            "generate", "\(doc)",
            "--config", "\(config)",
            "--output-directory", "\(genSourcesDir)",
            "--invocation-kind", "Command"
        ]
        try process.run()
    }
}

extension SwiftOpenAPIGeneratorPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        guard context.package.targets.count == 1 else {
            print("Error with context:", context)
            print("Args:", arguments)
            throw Error.multiTargetFound(targetNames: context.package.targets.map(\.name))
        }
        let target = context.package.targets[0]
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
            print("Error with context:", context)
            print("Args:", arguments)
            throw Error.incompatibleTarget(targetName: target.name)
        }
        return try runCommand(
            pluginWorkDirectory: context.pluginWorkDirectory,
            tool: context.tool,
            sourceFiles: swiftTarget.sourceFiles,
            targetName: target.name
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftOpenAPIGeneratorPlugin: XcodeCommandPlugin {
    func performCommand(
        context: XcodePluginContext,
        arguments: [String]
    ) throws {
        guard context.xcodeProject.targets.count == 1 else {
            throw Error.multiTargetFound(
                targetNames: context.xcodeProject.targets.map(\.displayName)
            )
        }
        let target = context.xcodeProject.targets[0]
        return try runCommand(
            pluginWorkDirectory: context.pluginWorkDirectory,
            tool: context.tool,
            sourceFiles: target.inputFiles,
            targetName: target.displayName
        )
    }
}
#endif
