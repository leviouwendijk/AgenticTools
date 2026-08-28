import Agentic

public struct ReadTranscriptEventsToolInput: Sendable, Codable, Hashable {
    public let startIndex: Int?
    public let limit: Int?
    public let eventIDs: [String]
    public let kinds: [TranscriptEventKind]
    public let includeFullText: Bool
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
