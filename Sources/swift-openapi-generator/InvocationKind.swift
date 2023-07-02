
public enum InvocationKind: String {
    case CLI
    case BuildTool
    case Command

    var isPluginInvocation: Bool {
        switch self {
        case .CLI:
            return false
        case .BuildTool:
            return true
        case .Command:
            return true
        }
    }
}
