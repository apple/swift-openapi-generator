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
        switch try CommandMode(arguments: arguments, fromXcode: false) {
        case .allTargets:
            var hasHadASuccessfulRun = false
            var errors = [(error: any Error, targetName: String)]()
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
                    errors.append((error, target.name))
                }
            }
            if !hasHadASuccessfulRun {
                throw PluginError.noTargetsFoundForCommandPlugin
            }
            try throwErrorsIfNecessary(errors)
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
        switch try CommandMode(arguments: arguments, fromXcode: true) {
        case .allTargets:
            var hasHadASuccessfulRun = false
            var errors = [(error: any Error, targetName: String)]()
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
                    errors.append((error, target.name))
                }
            }
            if !hasHadASuccessfulRun {
                throw PluginError.noTargetsFoundForCommandPlugin
            }
            try throwErrorsIfNecessary(errors)
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

    init(arguments: [String], fromXcode: Bool) throws {
        if arguments.count == 2, arguments[0] == "--target" {
            self = .target(name: arguments[1])
        } else if arguments.count != 0 {
            if fromXcode {
                throw PluginError.badArgumentsXcode(arguments: arguments)
            } else {
                throw PluginError.badArgumentsCLI(arguments: arguments)
            }
        } else {
            self = .allTargets
        }
    }
}

extension SwiftOpenAPIGeneratorPlugin {
    func throwErrorsIfNecessary(_ errors: [(error: any Error, targetName: String)]) throws {
        let errorsToBeReported = errors.compactMap {
            (error, targetName) -> PluginError? in
            if let error = error as? PluginError {
                switch error {
                case .fileErrors(let errors, _):
                    if errors.count != FileError.Kind.allCases.count {
                        // There are some file-finding errors but at least 1 file is available.
                        // This means the user means to use the target with the generator, just
                        // hasn't configured their target properly.
                        // We'll throw this error to let them know.
                        return error
                    } else {
                        return nil
                    }
                default:
                    // We can't throw any of these errors because they only complain about
                    // the target not being openapi-generator compatible.
                    // We can't expect all targets to be OpenAPI compatible.
                    return nil
                }
            } else {
                print("Unknown error reported by run command for target '\(targetName)'. This is unexpected and should not happen. Please report at https://github.com/apple/swift-openapi-generator/issues")
                // Don't throw the error to not interrupt the process.
                return nil
            }
        }

        if !errorsToBeReported.isEmpty {
            throw errorsToBeReported
        }
    }
}
