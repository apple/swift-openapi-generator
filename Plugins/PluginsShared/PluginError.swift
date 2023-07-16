import PackagePlugin
import Foundation

enum PluginError: Swift.Error, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(targetName: String)
    case badArgumentsXcode(arguments: [String])
    case badArgumentsCLI(arguments: [String])
    case noTargetsFoundForCommandPlugin
    // The description is only suitable for Xcode, as it's only thrown in Xcode plugins.
    case noTargetsMatchingTargetName(targetName: String)
    // The description is not suitable for Xcode, as it's not thrown in Xcode plugins.
    case tooManyTargetsMatchingTargetName(targetNames: [String])
    case fileErrors([FileError], targetName: String)

    var description: String {
        switch self {
        case .incompatibleTarget(let targetName):
            return
            "Incompatible target called '\(targetName)'. Only Swift source targets can be used with the Swift OpenAPI generator plugin."
        case .badArgumentsCLI(let arguments):
            return "Bad arguments provided: \(arguments). Only arguments of form '--target TARGET_NAME' are supported so the generator only acts on a specific target."
        case .badArgumentsXcode(let arguments):
            return "Bad arguments provided: \(arguments). On Xcode, use Xcode's run plugin UI to choose a specific target."
        case .noTargetsFoundForCommandPlugin:
            return "None of the targets include valid OpenAPI spec files. Please make sure at least one of your targets has any valid OpenAPI spec files before triggering this command plugin. See documentation for details."
        case .noTargetsMatchingTargetName(let targetName):
            return "No target called '\(targetName)' were found. Use Xcode's UI to choose a single specific target before triggering the command plugin."
        case .tooManyTargetsMatchingTargetName(let targetNames):
            return "Too many targets found matching the provided target name: '\(targetNames)'. Target name must be specific enough for the plugin to only find a single target."
        case .fileErrors(let errors, let targetName):
            return "Found file errors in target called '\(targetName)': \(errors.description)"
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
        case notFound
        case multiFound(files: [Path])
    }

    let targetName: String
    let fileKind: Kind
    let issue: Issue

    var description: String {
        "FileError { targetName: \(targetName), fileKind: \(fileKind), description: \(preciseErrorDescription) }"
    }

    var preciseErrorDescription: String {
        switch fileKind {
        case .config:
            switch issue {
            case .notFound:
                return
                "No config file found in the target named '\(targetName)'. Add a file called 'openapi-generator-config.yaml' or 'openapi-generator-config.yml' to the target's source directory. See documentation for details."
            case .multiFound(let files):
                return
                "Multiple config files found in the target named '\(targetName)', but exactly one is expected. Found \(files.map(\.description).joined(separator: " "))."
            }
        case .document:
            switch issue {
            case .notFound:
                return
                "No OpenAPI document found in the target named '\(targetName)'. Add a file called 'openapi.yaml', 'openapi.yml' or 'openapi.json' (can also be a symlink) to the target's source directory. See documentation for details."
            case .multiFound(let files):
                return
                "Multiple OpenAPI documents found in the target named '\(targetName)', but exactly one is expected. Found \(files.map(\.description).joined(separator: " "))."
            }
        }
    }

    var errorDescription: String? {
        description
    }
}
