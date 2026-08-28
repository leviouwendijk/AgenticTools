import Agentic
import AgenticExecution

public struct CoreTranscriptToolSet: AgentToolSet {
    public let store: any AgentTranscriptStore

    public init(
        store: any AgentTranscriptStore
    ) {
        self.store = store
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            [
                ReadTranscriptEventsTool(
                    store: store
                ),
                SearchTranscriptTool(
                    store: store
                ),
                SummarizeTranscriptWindowTool(
                    store: store
                )
            ]
        )
    }
}

