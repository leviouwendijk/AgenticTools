import Agentic

public struct SummarizeTranscriptWindowToolOutput: Sendable, Codable, Hashable {
    public let window: TranscriptWindowSummary

    public init(
        window: TranscriptWindowSummary
    ) {
        self.window = window
    }
}
