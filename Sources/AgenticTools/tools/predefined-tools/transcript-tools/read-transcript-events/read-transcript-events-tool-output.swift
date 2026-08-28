import Agentic

public struct ReadTranscriptEventsToolOutput: Sendable, Codable, Hashable {
    public let totalEventCount: Int
    public let returnedEventCount: Int
    public let events: [TranscriptEventRecord]

    public init(
        totalEventCount: Int,
        returnedEventCount: Int,
        events: [TranscriptEventRecord]
    ) {
        self.totalEventCount = totalEventCount
        self.returnedEventCount = returnedEventCount
        self.events = events
    }
}
