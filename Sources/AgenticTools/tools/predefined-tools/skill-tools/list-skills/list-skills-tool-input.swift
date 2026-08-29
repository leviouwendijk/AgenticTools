import Schema
import SchemaMacros

/// List available Agentic skills with optional filtering and body inclusion.
@JSONSchema
public struct ListSkillsToolInput: Sendable, Codable, Hashable {
    /// Optional text used to filter the skill catalog.
    public let query: String?

    /// Whether returned skills should include their full body.
    public let includeBody: Bool?

    public init(
        query: String? = nil,
        includeBody: Bool? = nil
    ) {
        self.query = query
        self.includeBody = includeBody
    }
}
