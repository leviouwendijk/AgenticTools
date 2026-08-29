import Schema
import SchemaMacros

/// Load one Agentic skill by identifier or name.
@JSONSchema
public struct LoadSkillToolInput: Sendable, Codable, Hashable {
    /// Optional exact skill identifier. Supply id or name.
    public let id: String?

    /// Optional exact skill name. Supply name or id.
    public let name: String?

    /// Whether to include skill metadata in the returned result.
    public let includeMetadata: Bool?

    public init(
        id: String? = nil,
        name: String? = nil,
        includeMetadata: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.includeMetadata = includeMetadata
    }
}
