/// The source of the generator invocation.
enum InvocationSource: String, Codable {
    case BuildToolPlugin
    case CommandPlugin
    case CLI
}
