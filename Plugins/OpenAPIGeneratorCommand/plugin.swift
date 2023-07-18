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
    func runCommand(
        targetWorkingDirectory: Path,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String
    ) throws {
        let inputs = try PluginUtils.validateInputs(
            workingDirectory: targetWorkingDirectory,
            tool: tool,
            sourceFiles: sourceFiles,
            targetName: targetName,
            pluginSource: .command
        )

        let toolUrl = URL(fileURLWithPath: inputs.tool.path.string)
        let process = Process()
        process.executableURL = toolUrl
        process.arguments = inputs.arguments
        process.environment = [:]
        try process.run()
        process.waitUntilExit()
    }
}

extension SwiftOpenAPIGeneratorPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let targetName = try parseTargetName(from: arguments)
        let matchingTargets = try context.package.targets(named: [targetName])

        switch matchingTargets.count {
        case 0:
            throw PluginError.noTargetsMatchingTargetName(targetName: targetName)
        case 1:
            let target = matchingTargets[0]
            guard let swiftTarget = target as? SwiftSourceModuleTarget else {
                throw PluginError.incompatibleTarget(targetName: target.name)
            }
            try runCommand(
                targetWorkingDirectory: target.directory,
                tool: context.tool,
                sourceFiles: swiftTarget.sourceFiles,
                targetName: target.name
            )
        default:
            throw PluginError.tooManyTargetsMatchingTargetName(
                targetName: targetName,
                matchingTargetNames: matchingTargets.map(\.name)
            )
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftOpenAPIGeneratorPlugin: XcodeCommandPlugin {
    func performCommand(
        context: XcodePluginContext,
        arguments: [String]
    ) throws {
        let targetName = try parseTargetName(from: arguments)
        let matchingTargets = context.xcodeProject.targets.filter {
            $0.displayName == targetName
        }

        switch matchingTargets.count {
        case 0:
            throw PluginError.noTargetsMatchingTargetName(targetName: targetName)
        case 1:
            let xcodeTarget = matchingTargets[0]
            guard let target = xcodeTarget as? SourceModuleTarget else {
                throw PluginError.incompatibleTarget(targetName: xcodeTarget.displayName)
            }
            try runCommand(
                targetWorkingDirectory: target.directory,
                tool: context.tool,
                sourceFiles: xcodeTarget.inputFiles,
                targetName: xcodeTarget.displayName
            )
        default:
            throw PluginError.tooManyTargetsMatchingTargetName(
                targetName: targetName,
                matchingTargetNames: matchingTargets.map(\.displayName)
            )
        }
    }
}
#endif

extension SwiftOpenAPIGeneratorPlugin {
    /// Parses the target name from the arguments.
    func parseTargetName(from arguments: [String]) throws -> String {
        guard arguments.count == 2,
              arguments[0] == "--target"
        else {
            throw PluginError.badArguments(arguments)
        }
        return arguments[1]
    }
}
