import Search

public struct TranscriptRetrievalOptions: Sendable, Codable, Hashable {
    public var search: SearchOptions

    public init(
        search: SearchOptions = .defaults
    ) {
        self.search = search
    }

    public static let `default` = Self()
}
