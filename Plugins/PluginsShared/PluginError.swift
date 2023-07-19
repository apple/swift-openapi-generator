import PackagePlugin
import Foundation

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(targetName: String)
    case noTargetOrDependenciesWithExpectedFiles(targetName: String, dependencyNames: [String])
    case badArguments([String])
    case noTargetsMatchingTargetName(targetName: String)
    case tooManyTargetsMatchingTargetName(targetName: String, matchingTargetNames: [String])
    case fileErrors([FileError])

    var description: String {
        switch self {
        case .incompatibleTarget(let targetName):
            return "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI Generator plugin."
        case .noTargetOrDependenciesWithExpectedFiles(let targetName, let dependencyNames):
            let introduction = dependencyNames.isEmpty ?
            "Target called '\(targetName)' doesn't contain" :
            "Target called '\(targetName)' or its dependencies \(dependencyNames) don't contain"
            return "\(introduction) any config or document files with expected names. For OpenAPI code generation, a target needs to contain a config file named 'openapi-generator-config.yaml' or 'openapi-generator-config.yml', as well as an OpenAPI document named 'openapi.yaml', 'openapi.yml' or 'openapi.json' under target's source directory. See documentation for details."
        case .badArguments(let arguments):
            return "On Xcode, use Xcode's command plugin UI to choose one specific target before hitting 'Run'. On CLI make sure arguments are exactly of form '--target <target-name>'. The reason for this error is unexpected arguments: \(arguments)"
        case .noTargetsMatchingTargetName(let targetName):
            return "Found no targets matching target name '\(targetName)'. Please make sure the target name argument leads to one and only one target."
        case .tooManyTargetsMatchingTargetName(let targetName, let matchingTargetNames):
            return "Found too many targets matching target name '\(targetName)': \(matchingTargetNames). Please make sure the target name argument leads to a unique target."
        case .fileErrors(let errors):
            return "Found file errors: \(errors)."
        }
    }

    var errorDescription: String? {
        description
    }

    /// The error is definitely due to misconfiguration of a target.
    var isDefiniteMisconfigurationError: Bool {
        switch self {
        case .incompatibleTarget, .noTargetOrDependenciesWithExpectedFiles, .badArguments, .noTargetsMatchingTargetName, .tooManyTargetsMatchingTargetName:
            return false
        case .fileErrors(let errors):
            return errors.isDefiniteMisconfigurationError
        }
    }
}

struct FileError: Swift.Error, CustomStringConvertible, LocalizedError {

    enum Kind: CaseIterable {
        case config
        case document
    }

    enum Issue {
        case noFilesFound
        case multipleFilesFound(files: [Path])

        /// The error is definitely due to misconfiguration of a target.
        var isDefiniteMisconfigurationError: Bool {
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
        "FileError { \(helpAnchor!) }"
    }

    var helpAnchor: String? {
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

    static func notFoundFileErrors(forTarget targetName: String) -> [FileError] {
        FileError.Kind.allCases.map { kind in
            FileError(targetName: targetName, fileKind: kind, issue: .noFilesFound)
        }
    }
}


private extension [FileError] {
    /// The error is definitely due to misconfiguration of a target.
    var isDefiniteMisconfigurationError: Bool {
        // If errors for both files exist and none is "Definite Misconfiguration Error" then the
        // error can be related to a target that isn't supposed to be generator compatible at all.
        if count == FileError.Kind.allCases.count,
        self.allSatisfy({ !$0.issue.isDefiniteMisconfigurationError }) {
            return false
        }
        return true
    }
}
