import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct ReadTranscriptEventsTool: TypedInstanceAgentTool {
    public typealias Input = ReadTranscriptEventsToolInput

    public static let identifier: AgentToolIdentifier = "read_transcript_events"
    public static let description = "Read selected transcript events from an attached transcript store."
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
            ReadTranscriptEventsToolInput.self,
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
            ReadTranscriptEventsToolInput.self,
            from: input
        )
        let events = try await store.loadEvents()

        let selected: [(index: Int, event: AgentTranscriptEvent)]
        if decoded.eventIDs.isEmpty {
            selected = TranscriptToolSupport.selectedEvents(
                from: events,
                startIndex: decoded.startIndex,
                limit: decoded.limit,
                allowedKinds: decoded.kinds,
                latestFirst: decoded.latestFirst
            )
        } else {
            let requestedIDs = Set(
                decoded.eventIDs
            )

            selected = events.enumerated().compactMap { index, event in
                guard requestedIDs.contains(event.id) else {
                    return nil
                }

                guard TranscriptToolSupport.matchesKinds(
                    event,
                    allowedKinds: decoded.kinds
                ) else {
                    return nil
                }

                return (
                    index: index,
                    event: event
                )
            }
        }

        let records = selected.map { indexedEvent in
            TranscriptToolSupport.record(
                for: indexedEvent.event,
                index: indexedEvent.index,
                includeFullText: decoded.includeFullText
            )
        }

        return try JSONToolBridge.encode(
            ReadTranscriptEventsToolOutput(
                totalEventCount: events.count,
                returnedEventCount: records.count,
                events: records
            )
        )
    }
}

private extension ReadTranscriptEventsTool {
    func summary(
        for input: ReadTranscriptEventsToolInput
    ) -> String {
        if !input.eventIDs.isEmpty {
            return "Read \(input.eventIDs.count) transcript event(s) by id."
        }

        let limit = input.limit ?? 40

        if let startIndex = input.startIndex {
            return "Read up to \(limit) transcript event(s) from index \(startIndex)."
        }

        return "Read up to \(limit) transcript event(s)."
    }
}
