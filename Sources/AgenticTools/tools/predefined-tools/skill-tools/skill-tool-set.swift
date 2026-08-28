import Agentic
import AgenticExecution

public struct SkillToolSet: AgentToolSet {
    public let registry: SkillRegistry

    public init(
        registry: SkillRegistry
    ) {
        self.registry = registry
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            [
                ListSkillsTool(
                    registry: self.registry
                ),
                LoadSkillTool(
                    registry: self.registry
                )
            ]
        )
    }
}
