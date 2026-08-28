public struct LoadSkillToolInput: Sendable, Codable, Hashable {
    public let id: String?
    public let name: String?
    public let includeMetadata: Bool?

    public init(
        id: String? = nil,
        name: String? = nil,
        includeMetadata: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.includeMetadata = includeMetadata
    }
}
