import PackagePlugin
import Foundation

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(name: String)
    case generatorFailure(targetName: String)
    case noTargetOrDependenciesWithExpectedFiles(targetName: String, dependencyNames: [String])
    case badArguments([String])
    case noTargetsMatchingTargetName(String)
    case tooManyTargetsMatchingTargetName(String, matchingTargetNames: [String])
    case fileErrors([FileError])

    var description: String {
        switch self {
        case .incompatibleTarget(let name):
            return "Incompatible target called '\(name)'. Only Swift source targets can be used with the Swift OpenAPI Generator plugin."
        case .generatorFailure(let targetName):
            return "The generator failed to generate OpenAPI files for target '\(targetName)'."
        case .noTargetOrDependenciesWithExpectedFiles(let targetName, let dependencyNames):
            let introduction = dependencyNames.isEmpty ? "Target called '\(targetName)' doesn't contain" : "Target called '\(targetName)' or its local dependencies \(dependencyNames.joined(separator: ", ")) don't contain"
            return "\(introduction) any config or OpenAPI document files with expected names. See documentation for details."
        case .badArguments(let arguments):
            return "Unexpected arguments: '\(arguments.joined(separator: " "))', expected: '--target MyTarget'."
        case .noTargetsMatchingTargetName(let targetName):
            return "Found no targets with the name '\(targetName)'."
        case .tooManyTargetsMatchingTargetName(let targetName, let matchingTargetNames):
            return "Found too many targets with the name '\(targetName)': \(matchingTargetNames.joined(separator: ", ")). Select a target name with a unique name."
        case .fileErrors(let fileErrors):
            return "Issues with required files: \(fileErrors.map(\.description).joined(separator: ", and"))."
        }
    }

    var errorDescription: String? {
        description
    }

    /// The error is definitely due to misconfiguration of a target.
    var isMisconfigurationError: Bool {
        switch self {
        case .incompatibleTarget,
                .generatorFailure,
                .noTargetOrDependenciesWithExpectedFiles,
                .badArguments,
                .noTargetsMatchingTargetName,
                .tooManyTargetsMatchingTargetName:
            return false
        case .fileErrors(let errors):
            return errors.isMisconfigurationError
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
            case .noFilesFound:
                return false
            case .multipleFilesFound:
                return true
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
                return "No config file found in the target named '\(targetName)'. Add a file called 'openapi-generator-config.yaml' or 'openapi-generator-config.yml' to the target's source directory. See documentation for details."
            case .multipleFilesFound(let files):
                return "Multiple config files found in the target named '\(targetName)', but exactly one is expected. Found \(files.map(\.description).joined(separator: " "))."
            }
        case .document:
            switch issue {
            case .noFilesFound:
                return "No OpenAPI document found in the target named '\(targetName)'. Add a file called 'openapi.yaml', 'openapi.yml' or 'openapi.json' (can also be a symlink) to the target's source directory. See documentation for details."
            case .multipleFilesFound(let files):
                return "Multiple OpenAPI documents found in the target named '\(targetName)', but exactly one is expected. Found \(files.map(\.description).joined(separator: " "))."
            }
        }
    }

    var errorDescription: String? {
        description
    }
}

private extension Array where Element == FileError {
    /// The error is definitely due to misconfiguration of a target.
    var isMisconfigurationError: Bool {
        // If errors for both files exist and none is "Definite Misconfiguration Error" then the
        // error can be related to a target that isn't supposed to be generator compatible at all.
        if count == FileError.Kind.allCases.count,
           self.allSatisfy({ !$0.issue.isMisconfigurationError })
        {
            return false
        }
        return true
    }
}
