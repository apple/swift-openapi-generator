import PackagePlugin
import Foundation

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(targetName: String)
    case badArguments([String])
    case noTargetsMatchingTargetName(targetName: String)
    case tooManyTargetsMatchingTargetName(targetName: String, matchingTargetNames: [String])
    case fileErrors([FileError], targetName: String)

    /// The error is definitely due to misconfiguration of a target.
    var isDefiniteMisconfigurationError: Bool {
        switch self {
        case .incompatibleTarget, .badArguments, .noTargetsMatchingTargetName, .tooManyTargetsMatchingTargetName:
            return false
        case .fileErrors(let errors, _):
            return errors.isDefiniteMisconfigurationError
        }
    }

    var description: String {
        switch self {
        case .incompatibleTarget(let targetName):
            return "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI Generator plugin."
        case .badArguments(let arguments):
            return "Unexpected arguments: \(arguments). On Xcode, use Xcode's command plugin UI to choose one specific target before hitting 'Run'. Otherwise make sure arguments are exactly of form '--target <target-name>'."
        case .noTargetsMatchingTargetName(let targetName):
            return "Found no targets matching target name '\(targetName)'. Please make sure the target name argument leads to one and only one target."
        case .tooManyTargetsMatchingTargetName(let targetName, let matchingTargetNames):
            return "Found too many targets matching target name '\(targetName)': \(matchingTargetNames). Please make sure the target name argument leads to a unique target."
        case .fileErrors(let errors, let targetName):
            return "Found file errors in target called '\(targetName)': \(errors)."
        }
    }

    var errorDescription: String? {
        description
    }
}

extension [PluginError]: Swift.Error, CustomStringConvertible, LocalizedError {
    public var errorDescription: String? {
        description
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
        if count == FileError.Kind.allCases.count,
           self.map(\.issue.isDefiniteMisconfigurationError).allSatisfy({ $0 ==  false }) {
            return false
        }
        return true
    }
}
