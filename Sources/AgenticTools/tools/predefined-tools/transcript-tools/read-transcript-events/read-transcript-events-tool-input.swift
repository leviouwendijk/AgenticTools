import Agentic
import Schema

@JSONSchema
public struct ReadTranscriptEventsToolInput: Sendable, Codable, Hashable {
    /// Optional first transcript event index to read.
    public let startIndex: Int?
    /// Optional maximum number of transcript events to return.
    public let limit: Int?
    /// Exact event identifiers to include. An empty array does not restrict by identifier.
    public let eventIDs: [String]
    /// Transcript event kinds to include. An empty array includes all kinds.
    public let kinds: [TranscriptEventKind]
    /// Whether to include full event text instead of compact excerpts.
    public let includeFullText: Bool
    /// Whether to return matching events in reverse chronological order.
    public let latestFirst: Bool

    public init(
        startIndex: Int? = nil,
        limit: Int? = nil,
        eventIDs: [String] = [],
        kinds: [TranscriptEventKind] = [],
        includeFullText: Bool = false,
        latestFirst: Bool = false
    ) {
        self.startIndex = startIndex
        self.limit = limit
        self.eventIDs = eventIDs
        self.kinds = kinds
        self.includeFullText = includeFullText
        self.latestFirst = latestFirst
    }
}
