import Agentic

public struct AgentAdvisorToolConfiguration: Sendable, Codable, Hashable {
    public var identifier: AgentToolIdentifier
    public var modelSelection: AgentModelSelection
    public var systemPrompt: String
    public var maxOutputTokens: Int?
    public var temperature: Double?

    public init(
        identifier: AgentToolIdentifier = AgentAdvisorToolDefaults.identifier,
        modelSelection: AgentModelSelection = .advisor,
        systemPrompt: String = AgentAdvisorToolDefaults.systemPrompt,
        maxOutputTokens: Int? = 900,
        temperature: Double? = 0.0
    ) {
        self.identifier = identifier
        self.modelSelection = modelSelection
        self.systemPrompt = systemPrompt
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
    }
}
