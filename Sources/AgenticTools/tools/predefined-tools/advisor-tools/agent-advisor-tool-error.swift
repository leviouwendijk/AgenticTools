import Foundation

public enum AgentAdvisorToolError: Error, Sendable, LocalizedError {
    case emptyPrompt

    public var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Tool 'advisor_ask' requires a non-empty prompt."
        }
    }
}
