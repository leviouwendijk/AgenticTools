import Agentic
import AgenticExecution

public struct CoreArtifactToolSet: AgentToolSet {
    public let store: any AgentArtifactStore

    public init(
        store: any AgentArtifactStore
    ) {
        self.store = store
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            EmitArtifactTool(
                store: store
            )
            ListArtifactsTool(
                store: store
            )
            ReadArtifactTool(
                store: store
            )
        }
    }
}