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
            invocationSource: .CommandPlugin
        )

        let toolUrl = URL(fileURLWithPath: inputs.tool.path.string)
        let process = Process()
        process.executableURL = toolUrl
        process.arguments = inputs.arguments
        try process.run()
    }
}

extension SwiftOpenAPIGeneratorPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        guard arguments.count == 2, arguments[0] == "--target" else {
            throw PluginError.badArguments(arguments: arguments)
        }
        let targetName = arguments[1]
        let matchingTargets = try context.package.targets(named: [targetName])
        // `matchingTargets.count` can't be 0 because
        // `targets(named:)` would throw an error for that.
        guard matchingTargets.count == 1 else {
            throw PluginError.tooManyTargetsMatchingTargetName(targetNames: matchingTargets.map(\.name))
        }
        let target = matchingTargets[0]
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
            throw PluginError.incompatibleTarget(targetName: target.name)
        }
        return try runCommand(
            targetWorkingDirectory: target.directory,
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
            throw PluginError.badArguments(arguments: arguments)
        }
        let targetName = arguments[1]
        guard let xcodeTarget = context.xcodeProject.targets.first(
            where: { $0.displayName == targetName }
        ) else {
            throw PluginError.noTargetsMatchingTargetName(targetName: targetName)
        }
        guard let target = xcodeTarget as? SourceModuleTarget else {
            throw PluginError.incompatibleTarget(targetName: targetName)
        }
        return try runCommand(
            targetWorkingDirectory: target.directory,
            tool: context.tool,
            sourceFiles: xcodeTarget.inputFiles,
            targetName: xcodeTarget.displayName
        )
    }
}
#endif
