public struct AgentAdvisorToolInput: Sendable, Codable, Hashable {
    public var prompt: String
    public var context: String?
    public var instruction: String?

    public init(
        prompt: String,
        context: String? = nil,
        instruction: String? = nil
    ) {
        self.prompt = prompt
        self.context = context
        self.instruction = instruction
    }
}
