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
        try throwErrorsIfNecessary(errors)
        guard hasHadASuccessfulRun else {
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
        try throwErrorsIfNecessary(errors)
        guard hasHadASuccessfulRun else {
            throw PluginError.noTargetsFoundForCommandPlugin
        }
    }
}
#endif

extension SwiftOpenAPIGeneratorPlugin {
    /// Throws if there are any errors that show a target is definitely trying to
    /// have OpenAPI generator compatibility, but is failing to.
    func throwErrorsIfNecessary(_ errors: [(error: any Error, targetName: String)]) throws {
        let errorsToBeReported = errors.compactMap { (error, targetName) -> PluginError? in
            guard let error = error as? PluginError else {
                print("Unknown error reported by run command for target '\(targetName)'. This is unexpected and should not happen. Please report at https://github.com/apple/swift-openapi-generator/issues")
                // Don't throw the error to not interrupt the process.
                return nil
            }
            switch error {
            case .fileErrors(let errors, _):
                if errors.count == FileError.Kind.allCases.count,
                   errors.allSatisfy(\.issue.isNotFound)
                {
                    // No files were found so there is no indication that the target is supposed
                    // to be generator-compatible.
                    return nil
                }
                return error
            case .incompatibleTarget, .noTargetsFoundForCommandPlugin:
                // We can't throw any of these errors because they only complain about
                // the target not being openapi-generator compatible.
                // We can't expect all targets to be OpenAPI compatible.
                return nil
            }
        }

        guard errorsToBeReported.isEmpty else {
            throw errorsToBeReported
        }
    }
}
