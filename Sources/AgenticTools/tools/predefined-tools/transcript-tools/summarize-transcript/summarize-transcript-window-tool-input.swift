import Agentic
import Schema

@JSONSchema
public struct SummarizeTranscriptWindowToolInput: Sendable, Codable, Hashable {
    /// Optional first transcript event index for the summary window.
    public let startIndex: Int?
    /// Optional maximum number of transcript events in the summary window.
    public let limit: Int?
    /// Transcript event kinds to include. An empty array includes all kinds.
    public let kinds: [TranscriptEventKind]
    /// Whether to traverse the selected transcript window newest first.
    public let latestFirst: Bool
    /// Optional maximum excerpt characters retained per summarized event.
    public let maxExcerptCharacters: Int?

    public init(
        startIndex: Int? = nil,
        limit: Int? = nil,
        kinds: [TranscriptEventKind] = [],
        latestFirst: Bool = false,
        maxExcerptCharacters: Int? = nil
    ) {
        self.startIndex = startIndex
        self.limit = limit
        self.kinds = kinds
        self.latestFirst = latestFirst
        self.maxExcerptCharacters = maxExcerptCharacters
    }

    public var clampedMaxExcerptCharacters: Int {
        max(
            32,
            min(
                maxExcerptCharacters ?? 220,
                2_000
            )
        )
    }
}
