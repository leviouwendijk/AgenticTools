import Agentic

public struct AgentAdvisorToolConfiguration: Sendable, Codable, Hashable {
    public var identifier: AgentToolIdentifier
    public var routePolicy: AgentModelUsePolicy
    public var systemPrompt: String
    public var maxOutputTokens: Int?
    public var temperature: Double?

    public init(
        identifier: AgentToolIdentifier = AgentAdvisorToolDefaults.identifier,
        routePolicy: AgentModelUsePolicy = .advisor,
        systemPrompt: String = AgentAdvisorToolDefaults.systemPrompt,
        maxOutputTokens: Int? = 900,
        temperature: Double? = 0.0
    ) {
        self.identifier = identifier
        self.routePolicy = routePolicy
        self.systemPrompt = systemPrompt
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
    }
}
