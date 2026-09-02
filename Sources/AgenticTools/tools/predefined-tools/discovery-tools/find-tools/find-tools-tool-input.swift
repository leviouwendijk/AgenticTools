import Schema
import SchemaMacros

/// Search the installed model-facing Agentic tool catalog and expose the best matches for subsequent model turns.
@JSONSchema
public struct FindToolsToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Natural-language capability or operation to search for.
    public let query: String

    /// Maximum number of matching tools to return and activate. Defaults to 5 and is capped at 8.
    public let maximumResults: Int?

    public init(
        query: String,
        maximumResults: Int? = nil
    ) {
        self.query = query
        self.maximumResults = maximumResults
    }

    public var resultLimit: Int {
        max(
            1,
            min(
                maximumResults ?? 5,
                8
            )
        )
    }
}
