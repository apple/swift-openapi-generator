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
        var targets: [any Target] = []
        /// On CLI, we run the generator on all targets if no target names are passed
        if arguments.isEmpty {
            targets = context.package.targets
            print("Running OpenAPI generator CommandPlugin all targets")
        } else {
            let targetNames = try parseTargetNames(arguments: arguments)
            print("Running OpenAPI generator CommandPlugin on targets: \(targetNames)")
            targets = try context.package.targets(named: Array(targetNames))
        }

        var hasHadASuccessfulRun = false
        var errors = [(error: any Error, targetName: String)]()
        for target in targets {
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
        try throwErrorsIfNecessary(errors)
        if !hasHadASuccessfulRun {
            throw PluginError.noTargetsFoundForCommandPlugin
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
        // On Xcode, it automatically includes all targets when you run the plugin.
        let targetNames = try parseTargetNames(arguments: arguments)
        print("Running OpenAPI generator CommandPlugin on targets: \(targetNames)")
        let targets = context.xcodeProject.targets.filter { targetNames.contains($0.displayName) }
        var hasHadASuccessfulRun = false
        var errors = [(error: any Error, targetName: String)]()
        for xcodeTarget in targets {
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
        try throwErrorsIfNecessary(errors)
        if !hasHadASuccessfulRun {
            throw PluginError.noTargetsFoundForCommandPlugin
        }
    }
}
#endif

extension SwiftOpenAPIGeneratorPlugin {
    func parseTargetNames(arguments: [String]) throws -> Set<String> {
        guard arguments.count % 2 == 0 else {
            throw PluginError.badArguments(arguments: arguments)
        }
        var targets: Set<String> = []
        targets.reserveCapacity(arguments.count / 2)
        for idx in 0..<arguments.count / 2 {
            if arguments[idx] == "--target" {
                targets.insert(arguments[idx + 1])
            } else {
                throw PluginError.badArguments(arguments: arguments)
            }
        }
        return targets
    }
    
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
