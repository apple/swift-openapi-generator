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
        case badArguments(arguments: [String])
        // The description is only suitable for Xcode, as it's only thrown in Xcode plugins.
        case noTargetsMatchingTargetName(targetName: String)
        case tooManyTargetsMatchingTargetName(targetNames: [String])
        case noConfigFound(targetName: String)
        case noDocumentFound(targetName: String)
        case multiConfigFound(targetName: String, files: [Path])
        case multiDocumentFound(targetName: String, files: [Path])

        var description: String {
            switch self {
            case .incompatibleTarget(let targetName):
                return
                    "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI generator plugin."
            case .badArguments(let arguments):
                return "Bad arguments provided: \(arguments). On Xcode, use Xcode's run plugin UI to choose a specific target. On CLI, pass a specific target's name to the command like so: '--target TARGET_NAME'"
            case .noTargetsMatchingTargetName(let targetName):
                return "No target called '\(targetName)' were found. Use Xcode's UI to choose a single specific target before triggering the command plugin."
            case .tooManyTargetsMatchingTargetName(let targetNames):
                return "Too many targets found matching the provided target name: '\(targetNames)'. Target name must be specific enough for the plugin to only find a single target."
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
        guard arguments.count == 2, arguments[0] == "--target" else {
            throw Error.badArguments(arguments: arguments)
        }
        let targetName = arguments[1]
        let matchingTargets = try context.package.targets(named: [targetName])
        // `matchingTargets.count` can't be 0 because
        // `targets(named:)` would throw an error for that.
        guard matchingTargets.count == 1 else {
            throw Error.tooManyTargetsMatchingTargetName(targetNames: matchingTargets.map(\.name))
        }
        let target = matchingTargets[0]
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
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
        guard arguments.count == 2, arguments[0] == "--target" else {
            throw Error.badArguments(arguments: arguments)
        }
        let targetName = arguments[1]
        guard let target = context.xcodeProject.targets.first(where: {
            $0.displayName == targetName
        }) else {
            throw Error.noTargetsMatchingTargetName(targetName: targetName)
        }
        return try runCommand(
            pluginWorkDirectory: context.pluginWorkDirectory,
            tool: context.tool,
            sourceFiles: target.inputFiles,
            targetName: target.displayName
        )
    }
}
#endif
