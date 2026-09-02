import Agentic

public struct FoundAgentTool:
    Sendable,
    Codable,
    Hashable
{
    public let identifier: AgentToolIdentifier
    public let description: String
    public let risk: ActionRisk

    public init(
        identifier: AgentToolIdentifier,
        description: String,
        risk: ActionRisk
    ) {
        self.identifier = identifier
        self.description = description
        self.risk = risk
    }
}

public struct FindToolsToolOutput:
    Sendable,
    Codable,
    Hashable
{
    public let query: String
    public let tools: [FoundAgentTool]
    public let activated: [AgentToolIdentifier]

    public init(
        query: String,
        tools: [FoundAgentTool],
        activated: [AgentToolIdentifier]
    ) {
        self.query = query
        self.tools = tools
        self.activated = activated
    }
}
