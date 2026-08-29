import Agentic
import Schema

@JSONSchema
public struct SearchTranscriptToolInput: Sendable, Codable, Hashable {
    /// Text query to search for in transcript events.
    public let query: String
    /// Transcript event kinds to search. An empty array includes all kinds.
    public let kinds: [TranscriptEventKind]
    /// Optional maximum number of search results.
    public let maxResults: Int?
    /// Whether to include full event text in search results.
    public let includeFullText: Bool
    /// Whether text matching is case-sensitive.
    public let caseSensitive: Bool

    public init(
        query: String,
        kinds: [TranscriptEventKind] = [],
        maxResults: Int? = nil,
        includeFullText: Bool = false,
        caseSensitive: Bool = false
    ) {
        self.query = query
        self.kinds = kinds
        self.maxResults = maxResults
        self.includeFullText = includeFullText
        self.caseSensitive = caseSensitive
    }

    public var clampedMaxResults: Int {
        max(
            1,
            min(
                maxResults ?? 8,
                50
            )
        )
    }
}
