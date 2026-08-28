public struct AgentAdvisorToolOutput: Sendable, Codable, Hashable {
    public var routePurpose: String
    public var profile: String
    public var adapter: String
    public var model: String
    public var reasons: [String]
    public var warnings: [String]
    public var advice: String

    public init(
        routePurpose: String,
        profile: String,
        adapter: String,
        model: String,
        reasons: [String],
        warnings: [String],
        advice: String
    ) {
        self.routePurpose = routePurpose
        self.profile = profile
        self.adapter = adapter
        self.model = model
        self.reasons = reasons
        self.warnings = warnings
        self.advice = advice
    }
}
