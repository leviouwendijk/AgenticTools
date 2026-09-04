import Agentic
import AgenticExecution

public struct AgentTaskToolSet: AgentToolSet {
    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            CreateAgentTaskTool(
                manager: manager
            )
            UpdateAgentTaskTool(
                manager: manager
            )
            ListAgentTasksTool(
                manager: manager
            )
            GetAgentTaskTool(
                manager: manager
            )
            ClaimAgentTaskTool(
                manager: manager
            )
            CompleteAgentTaskTool(
                manager: manager
            )
        }
    }
}