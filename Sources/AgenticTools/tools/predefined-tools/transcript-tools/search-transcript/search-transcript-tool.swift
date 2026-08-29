import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct SearchTranscriptTool: TypedInstanceAgentTool {
    public typealias Input = SearchTranscriptToolInput

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
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            SearchTranscriptToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            summary: "Search transcript for '\(decoded.query)'",
            sideEffects: []
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            SearchTranscriptToolInput.self,
            from: input
        )
        let events = try await store.loadEvents()

        let matches = events.enumerated().compactMap { index, event -> SearchTranscriptMatch? in
            guard TranscriptToolSupport.matchesKinds(
                event,
                allowedKinds: decoded.kinds
            ) else {
                return nil
            }

            guard TranscriptToolSupport.containsQuery(
                event,
                query: decoded.query,
                caseSensitive: decoded.caseSensitive
            ) else {
                return nil
            }

            let score = TranscriptToolSupport.score(
                event,
                query: decoded.query,
                caseSensitive: decoded.caseSensitive
            )

            return .init(
                score: score,
                event: TranscriptToolSupport.record(
                    for: event,
                    index: index,
                    includeFullText: decoded.includeFullText
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
                decoded.clampedMaxResults
            )
        )

        return try JSONToolBridge.encode(
            SearchTranscriptToolOutput(
                query: decoded.query,
                totalEventCount: events.count,
                matchCount: limitedMatches.count,
                matches: limitedMatches
            )
        )
    }
}
