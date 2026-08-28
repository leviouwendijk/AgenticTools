import Foundation

public enum SkillToolError: Error, Sendable, LocalizedError {
    case missingSkillIdentifier

    public var errorDescription: String? {
        switch self {
        case .missingSkillIdentifier:
            return "Expected either 'id' or 'name' for skill lookup."
        }
    }
}
