import PackagePlugin

enum PluginUtils {
    private static var supportedConfigFiles: Set<String> { Set(["yaml", "yml"].map { "openapi-generator-config." + $0 }) }
    private static var supportedDocFiles: Set<String> { Set(["yaml", "yml", "json"].map { "openapi." + $0 }) }

    struct ValidatedInputs {
        let doc: Path
        let config: Path
        let genSourcesDir: Path
        let arguments: [String]
        let tool: PluginContext.Tool
    }

    static func validateInputs(
        workingDirectory: Path,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String,
        invocationSource: InvocationSource
    ) throws -> ValidatedInputs {
        let (config, doc) = try findFiles(inputFiles: sourceFiles, targetName: targetName)
        let genSourcesDir = workingDirectory.appending("GeneratedSources")

        let arguments = [
            "generate", "\(doc)",
            "--config", "\(config)",
            "--output-directory", "\(genSourcesDir)",
            "--invoked-from", "\(invocationSource.rawValue)",
        ]

        let tool = try tool("swift-openapi-generator")

        return ValidatedInputs(
            doc: doc,
            config: config,
            genSourcesDir: genSourcesDir,
            arguments: arguments,
            tool: tool
        )
    }

    private static func findFiles(
        inputFiles: FileList,
        targetName: String
    ) throws -> (config: Path, doc: Path) {
        let config = findConfig(inputFiles: inputFiles, targetName: targetName)
        let doc = findDocument(inputFiles: inputFiles, targetName: targetName)
        switch (config, doc) {
        case (.failure(let error1), .failure(let error2)):
            throw PluginError.fileErrors([error1, error2], targetName: targetName)
        case (_, .failure(let error)):
            throw PluginError.fileErrors([error], targetName: targetName)
        case (.failure(let error), _):
            throw PluginError.fileErrors([error], targetName: targetName)
        case (.success(let config), .success(let doc)):
            return (config, doc)
        }
    }

    private static func findConfig(
        inputFiles: FileList,
        targetName: String
    ) -> Result<Path, FileError> {
        let matchedConfigs = inputFiles.filter { supportedConfigFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedConfigs.count > 0 else {
            return .failure(
                FileError(
                    targetName: targetName,
                    fileKind: .config,
                    issue: .notFound
                )
            )
        }
        guard matchedConfigs.count == 1 else {
            return .failure(
                FileError(
                    targetName: targetName,
                    fileKind: .config,
                    issue: .multiFound(files: matchedConfigs)
                )
            )
        }
        return .success(matchedConfigs[0])
    }

    private static func findDocument(
        inputFiles: FileList,
        targetName: String
    ) -> Result<Path, FileError> {
        let matchedDocs = inputFiles.filter { supportedDocFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedDocs.count > 0 else {
            return .failure(
                FileError(
                    targetName: targetName,
                    fileKind: .document,
                    issue: .notFound
                )
            )
        }
        guard matchedDocs.count == 1 else {
            return .failure(
                FileError(
                    targetName: targetName,
                    fileKind: .document,
                    issue: .multiFound(files: matchedDocs)
                )
            )
        }
        return .success(matchedDocs[0])
    }
}
