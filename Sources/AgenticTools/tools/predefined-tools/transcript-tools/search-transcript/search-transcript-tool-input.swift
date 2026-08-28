import Agentic

public struct SearchTranscriptToolInput: Sendable, Codable, Hashable {
    public let query: String
    public let kinds: [TranscriptEventKind]
    public let maxResults: Int?
    public let includeFullText: Bool
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
