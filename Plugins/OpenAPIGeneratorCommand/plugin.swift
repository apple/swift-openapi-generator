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
        guard arguments.count == 2,
              arguments[0] == "--target"
        else {
            throw PluginError.badArguments(arguments)
        }
        let targetName = arguments[1]

        let matchingTargets = try context.package.targets(named: [targetName])

        switch matchingTargets.count {
        case 0:
            throw PluginError.noTargetsMatchingTargetName(targetName: targetName)
        case 1:
            let mainTarget = matchingTargets[0]
            guard mainTarget is SwiftSourceModuleTarget else {
                throw PluginError.incompatibleTarget(targetName: mainTarget.name)
            }
            let allDependencies = mainTarget.recursiveTargetDependencies
            let packageTargets = Set(context.package.targets.map(\.id))
            let dependenciesInPackage = allDependencies.filter { packageTargets.contains($0.id) }

            var hadASuccessfulRun = false

            for target in [mainTarget] + dependenciesInPackage {
                guard let swiftTarget = target as? SwiftSourceModuleTarget else {
                    continue
                }
                do {
                    try runCommand(
                        targetWorkingDirectory: target.directory,
                        tool: context.tool,
                        sourceFiles: swiftTarget.sourceFiles,
                        targetName: target.name
                    )
                    hadASuccessfulRun = true
                } catch let error as PluginError {
                    if error.isDefiniteMisconfigurationError {
                        throw error
                    }
                }
            }

            guard hadASuccessfulRun else {
                throw PluginError.noTargetOrDependenciesWithExpectedFiles(
                    targetName: mainTarget.name
                )
            }
        default:
            throw PluginError.tooManyTargetsMatchingTargetName(
                targetName: targetName,
                matchingTargetNames: matchingTargets.map(\.name)
            )
        }
    }
}
