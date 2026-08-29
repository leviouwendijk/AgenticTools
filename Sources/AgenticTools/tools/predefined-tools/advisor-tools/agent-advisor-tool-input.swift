import Schema

/// Ask the configured advisor model for bounded advisory reasoning.
@JSONSchema
public struct AgentAdvisorToolInput: Sendable, Codable, Hashable {
    /// The concrete question or decision to ask the advisor model about.
    public var prompt: String

    /// Optional bounded context already gathered by the executor.
    public var context: String?

    /// Optional extra instruction for the advisor response shape.
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
