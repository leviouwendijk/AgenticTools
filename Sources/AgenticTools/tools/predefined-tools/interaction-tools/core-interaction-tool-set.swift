import AgenticExecution

public struct CoreInteractionToolSet: AgentToolSet {
    public init() {}

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            ClarifyWithUserTool()
        }
    }
}
