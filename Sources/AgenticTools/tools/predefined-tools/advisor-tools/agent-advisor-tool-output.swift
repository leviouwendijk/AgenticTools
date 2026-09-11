import Agentic

public struct AgentAdvisorToolOutput: Sendable, Codable, Hashable {
    public var routePurpose: String
    public var profile: String
    public var gateway: String
    public var model: String
    public var diagnostics: [AgentModelSelectionDiagnostic]
    public var advice: String

    public init(
        routePurpose: String,
        profile: String,
        gateway: String,
        model: String,
        diagnostics: [AgentModelSelectionDiagnostic],
        advice: String
    ) {
        self.routePurpose = routePurpose
        self.profile = profile
        self.gateway = gateway
        self.model = model
        self.diagnostics = diagnostics
        self.advice = advice
    }
}
