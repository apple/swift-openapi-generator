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
        switch CommandMode(arguments: arguments) {
        case .allTargets:
            var hasHadASuccessfulRun = false
            for target in context.package.targets {
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
                    hasHadASuccessfulRun = true
                } catch {
                    try throwErrorIfNecessary(error, targetName: target.name)
                }
            }
            if !hasHadASuccessfulRun {
                throw PluginError.noTargetsFoundForCommandPlugin
            }
        case .target(let targetName):
            let matchingTargets = try context.package.targets(named: [targetName])
            // `matchingTargets.count` can't be 0 because
            // `targets(named:)` would throw an error for that, based on its documentation.
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
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftOpenAPIGeneratorPlugin: XcodeCommandPlugin {
    func performCommand(
        context: XcodePluginContext,
        arguments: [String]
    ) throws {
        switch CommandMode(arguments: arguments) {
        case .allTargets:
            var hasHadASuccessfulRun = false
            for xcodeTarget in context.xcodeProject.targets {
                guard let target = xcodeTarget as? SourceModuleTarget else {
                    continue
                }
                do {
                    try runCommand(
                        targetWorkingDirectory: target.directory,
                        tool: context.tool,
                        sourceFiles: xcodeTarget.inputFiles,
                        targetName: xcodeTarget.displayName
                    )
                    hasHadASuccessfulRun = true
                } catch {
                    try throwErrorIfNecessary(error, targetName: target.name)
                }
            }
            if !hasHadASuccessfulRun {
                throw PluginError.noTargetsFoundForCommandPlugin
            }
        case .target(let targetName):
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
}
#endif

enum CommandMode {
    case allTargets
    case target(name: String)

    init(arguments: [String]) {
        if arguments.count == 2, arguments[0] == "--target" {
            self = .target(name: arguments[1])
        } else {
            self = .allTargets
        }
    }
}

extension SwiftOpenAPIGeneratorPlugin {
    func throwErrorIfNecessary(_ error: any Error, targetName: String) throws {
        if let error = error as? PluginError {
            switch error {
            case .fileErrors(let errors):
                if errors.count != FileError.Kind.allCases.count {
                    // There are some file-finding errors but at least 1 file is available.
                    // This means the user means to use the target with the generator, just
                    // hasn't configured their target properly.
                    // We'll throw this error to let them know.
                    throw error
                } else {
                    break
                }
            default:
                // We can't throw any of these errors because they only complain about
                // the target not being openapi-generator compatible.
                break
            }
        } else {
            print("Unknown error reported by run command for target '\(targetName)'. This is unexpected and should not happen. Please report at https://github.com/apple/swift-openapi-generator/issues")
            // Don't throw the error to not interrupt the process.
        }
    }
}
