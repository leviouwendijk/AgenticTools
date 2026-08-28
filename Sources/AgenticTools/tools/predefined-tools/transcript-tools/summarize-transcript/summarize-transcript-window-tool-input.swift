import Agentic

public struct SummarizeTranscriptWindowToolInput: Sendable, Codable, Hashable {
    public let startIndex: Int?
    public let limit: Int?
    public let kinds: [TranscriptEventKind]
    public let latestFirst: Bool
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
