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

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(name: String)
    case generatorFailure(targetName: String)
    case noTargetsWithExpectedFiles(targetNames: [String])
    case noTargetsMatchingTargetNames([String])
    case fileErrors([FileError])

    var description: String {
        switch self {
        case .incompatibleTarget(let name):
            return
                "Incompatible target called '\(name)'. Only Swift source targets can be used with the Swift OpenAPI Generator plugin."
        case .generatorFailure(let targetName):
            return "The generator failed to generate OpenAPI files for target '\(targetName)'."
        case .noTargetsWithExpectedFiles(let targetNames):
            let fileNames = FileError.Kind.allCases.map(\.name).joined(separator: ", ", lastSeparator: " or ")
            let targetNames = targetNames.joined(separator: ", ", lastSeparator: " and ")
            return
                "Targets with names \(targetNames) don't contain any \(fileNames) files with expected names. See documentation for details."
        case .noTargetsMatchingTargetNames(let targetNames):
            let targetNames = targetNames.joined(separator: ", ", lastSeparator: " and ")
            return "Found no targets with names \(targetNames)."
        case .fileErrors(let fileErrors):
            return "Issues with required files:\n\(fileErrors.map { "- " + $0.description }.joined(separator: "\n"))."
        }
    }

    var errorDescription: String? { description }

    /// The error is definitely due to misconfiguration of a target.
    var isMisconfigurationError: Bool {
        switch self {
        case .incompatibleTarget: return false
        case .generatorFailure: return false
        case .noTargetsWithExpectedFiles: return false
        case .noTargetsMatchingTargetNames: return false
        case .fileErrors(let errors): return errors.isMisconfigurationError
        }
    }
}

struct FileError: Swift.Error, CustomStringConvertible, LocalizedError {

    /// The kind of the file.
    enum Kind: CaseIterable {
        /// Config file.
        case config
        /// OpenAPI document file.
        case document

        var name: String {
            switch self {
            case .config: return "config"
            case .document: return "OpenAPI document"
            }
        }
    }

    /// Encountered issue.
    enum Issue {
        /// File wasn't found.
        case noFilesFound
        /// More than 1 file found.
        case multipleFilesFound(files: [Path])

        /// The error is definitely due to misconfiguration of a target.
        var isMisconfigurationError: Bool {
            switch self {
            case .noFilesFound: return false
            case .multipleFilesFound: return true
            }
        }
    }

    let targetName: String
    let fileKind: Kind
    let issue: Issue

    var description: String {
        switch fileKind {
        case .config:
            switch issue {
            case .noFilesFound:
                return
                    "No config file found in the target named '\(targetName)'. Add a file called 'openapi-generator-config.yaml' or 'openapi-generator-config.yml' to the target's source directory. See documentation for details."
            case .multipleFilesFound(let files):
                return
                    "Multiple config files found in the target named '\(targetName)', but exactly one is expected. Found \(files.map(\.description).joined(separator: " "))."
            }
        case .document:
            switch issue {
            case .noFilesFound:
                return
                    "No OpenAPI document found in the target named '\(targetName)'. Add a file called 'openapi.yaml', 'openapi.yml' or 'openapi.json' (can also be a symlink) to the target's source directory. See documentation for details."
            case .multipleFilesFound(let files):
                return
                    "Multiple OpenAPI documents found in the target named '\(targetName)', but exactly one is expected. Found \(files.map(\.description).joined(separator: " "))."
            }
        }
    }

    var errorDescription: String? { description }
}

private extension Array where Element == FileError {
    /// The error is definitely due to misconfiguration of a target.
    var isMisconfigurationError: Bool {
        // If errors for both files exist and none is a "Misconfiguration Error" then the
        // error can be related to a target that isn't supposed to be generator compatible at all.
        if count == FileError.Kind.allCases.count, self.allSatisfy({ !$0.issue.isMisconfigurationError }) {
            return false
        }
        return true
    }
}
