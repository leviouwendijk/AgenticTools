import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct SearchTranscriptTool: AgentTool {
    public typealias Input = SearchTranscriptToolInput
    public typealias Output = SearchTranscriptToolOutput

    public static let identifier: AgentToolIdentifier = "search_transcript"
    public static let description = "Search transcript events in an attached transcript store."
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
            summary: "Search transcript for '\(input.query)'",
            sideEffects: []
        )
    }

    public func call(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> Output {
        let events = try await store.loadEvents()

        let matches = events.enumerated().compactMap { index, event -> SearchTranscriptMatch? in
            guard TranscriptToolSupport.matchesKinds(
                event,
                allowedKinds: input.kinds
            ) else {
                return nil
            }

            guard TranscriptToolSupport.containsQuery(
                event,
                query: input.query,
                caseSensitive: input.caseSensitive
            ) else {
                return nil
            }

            let score = TranscriptToolSupport.score(
                event,
                query: input.query,
                caseSensitive: input.caseSensitive
            )

            return .init(
                score: score,
                event: TranscriptToolSupport.record(
                    for: event,
                    index: index,
                    includeFullText: input.includeFullText
                )
            )
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.event.index > rhs.event.index
            }

            return lhs.score > rhs.score
        }

        let limitedMatches = Array(
            matches.prefix(
                input.clampedMaxResults
            )
        )

        return SearchTranscriptToolOutput(
                query: input.query,
                totalEventCount: events.count,
                matchCount: limitedMatches.count,
                matches: limitedMatches
            )
    }
}