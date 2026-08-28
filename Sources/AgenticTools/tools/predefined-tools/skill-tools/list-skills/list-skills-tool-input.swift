public struct ListSkillsToolInput: Sendable, Codable, Hashable {
    public let query: String?
    public let includeBody: Bool?

    public init(
        query: String? = nil,
        includeBody: Bool? = nil
    ) {
        self.query = query
        self.includeBody = includeBody
    }
}
