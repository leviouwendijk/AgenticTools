import Agentic

public struct SearchTranscriptMatch: Sendable, Codable, Hashable {
    public let score: Int
    public let event: TranscriptEventRecord

    public init(
        score: Int,
        event: TranscriptEventRecord
    ) {
        self.score = score
        self.event = event
    }
}

public struct SearchTranscriptToolOutput: Sendable, Codable, Hashable {
    public let query: String
    public let totalEventCount: Int
    public let matchCount: Int
    public let matches: [SearchTranscriptMatch]

    public init(
        query: String,
        totalEventCount: Int,
        matchCount: Int,
        matches: [SearchTranscriptMatch]
    ) {
        self.query = query
        self.totalEventCount = totalEventCount
        self.matchCount = matchCount
        self.matches = matches
    }
}
