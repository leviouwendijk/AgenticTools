import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct SummarizeTranscriptWindowTool: AgentTool {
    public typealias Input = SummarizeTranscriptWindowToolInput
    public typealias Output = SummarizeTranscriptWindowToolOutput

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
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {

        return .init(
            toolName: name,
            risk: risk,
            summary: summary(
                for: input
            ),
            sideEffects: []
        )
    }

    public func call(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> Output {
        let events = try await store.loadEvents()
        let selected = TranscriptToolSupport.selectedEvents(
            from: events,
            startIndex: input.startIndex,
            limit: input.limit,
            allowedKinds: input.kinds,
            latestFirst: input.latestFirst
        )

        let window = TranscriptToolSupport.summarize(
            events: selected,
            totalEventCount: events.count,
            maxExcerptCharacters: input.clampedMaxExcerptCharacters
        )

        return SummarizeTranscriptWindowToolOutput(
                window: window
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