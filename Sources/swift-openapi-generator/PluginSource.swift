/// The source of a plugin generator invocation.
enum PluginSource: String, Codable {
    /// BuildTool plugin
    case build
    /// Command plugin.
    case command
}
