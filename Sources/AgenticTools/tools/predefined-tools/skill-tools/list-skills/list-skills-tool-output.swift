import Agentic

public struct ListedSkill: Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let summary: String
    public let metadata: AgentSkillMetadata
    public let body: String?

    public init(
        id: String,
        name: String,
        summary: String,
        metadata: AgentSkillMetadata,
        body: String?
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.metadata = metadata
        self.body = body
    }
}

public struct ListSkillsToolOutput: Sendable, Codable, Hashable {
    public let skills: [ListedSkill]
    public let count: Int
    public let catalog: String

    public init(
        skills: [ListedSkill],
        count: Int,
        catalog: String
    ) {
        self.skills = skills
        self.count = count
        self.catalog = catalog
    }
}
