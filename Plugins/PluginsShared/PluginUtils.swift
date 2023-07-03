import PackagePlugin

enum PluginUtils {

    struct ValidatedInputs {
        let doc: Path
        let config: Path
        let genSourcesDir: Path
        let arguments: [String]
        let tool: PluginContext.Tool
    }

    private static var supportedConfigFiles: Set<String> { Set(["yaml", "yml"].map { "openapi-generator-config." + $0 }) }
    private static var supportedDocFiles: Set<String> { Set(["yaml", "yml", "json"].map { "openapi." + $0 }) }

    static func validateInputs(
        workingDirectory: Path,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String,
        invocationSource: InvocationSource
    ) throws -> ValidatedInputs {
        let inputFiles = sourceFiles
        let matchedConfigs = inputFiles.filter { supportedConfigFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedConfigs.count > 0 else {
            throw PluginError.noConfigFound(targetName: targetName)
        }
        guard matchedConfigs.count == 1 else {
            throw PluginError.multiConfigFound(targetName: targetName, files: matchedConfigs)
        }
        let config = matchedConfigs[0]

        let matchedDocs = inputFiles.filter { supportedDocFiles.contains($0.path.lastComponent) }.map(\.path)
        guard matchedDocs.count > 0 else {
            throw PluginError.noDocumentFound(targetName: targetName)
        }
        guard matchedDocs.count == 1 else {
            throw PluginError.multiDocumentFound(targetName: targetName, files: matchedDocs)
        }
        let doc = matchedDocs[0]
        let genSourcesDir = workingDirectory.appending("GeneratedSources")

        let arguments = [
            "generate", "\(doc)",
            "--config", "\(config)",
            "--output-directory", "\(genSourcesDir)",
            "--invoked-from", "\(invocationSource)"
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
}
