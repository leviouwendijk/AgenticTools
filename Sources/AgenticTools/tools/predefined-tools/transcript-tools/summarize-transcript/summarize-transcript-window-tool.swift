import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct SummarizeTranscriptWindowTool: AgentTool {
    public static let identifier: AgentToolIdentifier = "summarize_transcript_window"
    public static let description = "Create a deterministic summary of a transcript event window."
    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let store: any AgentTranscriptStore

    public init(
        store: any AgentTranscriptStore
    ) {
        self.store = store
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            SummarizeTranscriptWindowToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            summary: summary(
                for: decoded
            ),
            sideEffects: []
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            SummarizeTranscriptWindowToolInput.self,
            from: input
        )
        let events = try await store.loadEvents()
        let selected = TranscriptToolSupport.selectedEvents(
            from: events,
            startIndex: decoded.startIndex,
            limit: decoded.limit,
            allowedKinds: decoded.kinds,
            latestFirst: decoded.latestFirst
        )

        let window = TranscriptToolSupport.summarize(
            events: selected,
            totalEventCount: events.count,
            maxExcerptCharacters: decoded.clampedMaxExcerptCharacters
        )

        return try JSONToolBridge.encode(
            SummarizeTranscriptWindowToolOutput(
                window: window
            )
        )
    }
}

private extension SummarizeTranscriptWindowTool {
    func summary(
        for input: SummarizeTranscriptWindowToolInput
    ) -> String {
        let limit = input.limit ?? 40

        if let startIndex = input.startIndex {
            return "Summarize up to \(limit) transcript event(s) from index \(startIndex)."
        }

        return "Summarize up to \(limit) transcript event(s)."
    }
}
