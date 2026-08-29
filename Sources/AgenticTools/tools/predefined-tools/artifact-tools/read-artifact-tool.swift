import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives
import Schema
import SchemaMacros

@JSONSchema
public struct ReadArtifactToolInput: Sendable, Codable, Hashable {
    /// Exact artifact identifier to read.
    public let id: String
    /// Whether to include artifact content. Defaults to true when omitted.
    public let includeContent: Bool?
    /// Optional maximum number of content characters to return.
    public let maxCharacters: Int?

    public init(
        id: String,
        includeContent: Bool? = nil,
        maxCharacters: Int? = nil
    ) {
        self.id = id
        self.includeContent = includeContent
        self.maxCharacters = maxCharacters
    }

    public var shouldIncludeContent: Bool {
        includeContent ?? true
    }

    public var resolvedMaxCharacters: Int? {
        guard let maxCharacters else {
            return nil
        }

        return max(
            0,
            maxCharacters
        )
    }
}

public struct ReadArtifactToolOutput: Sendable, Codable, Hashable {
    public let artifact: AgentArtifact
    public let content: String?
    public let truncated: Bool

    public init(
        artifact: AgentArtifact,
        content: String?,
        truncated: Bool
    ) {
        self.artifact = artifact
        self.content = content
        self.truncated = truncated
    }
}

public struct ReadArtifactTool: TypedInstanceAgentTool {
    public typealias Input = ReadArtifactToolInput

    public static let identifier: AgentToolIdentifier = "read_artifact"
    public static let description = "Read a durable artifact emitted for the current Agentic session."
    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let store: any AgentArtifactStore

    public init(
        store: any AgentArtifactStore
    ) {
        self.store = store
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ReadArtifactToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Read session artifact \(decoded.id).",
            sideEffects: []
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            ReadArtifactToolInput.self,
            from: input
        )

        guard let record = try await store.load(
            id: decoded.id
        ) else {
            throw AgentArtifactError.artifactNotFound(
                decoded.id
            )
        }

        let renderedContent: String?
        let truncated: Bool

        if decoded.shouldIncludeContent {
            let limited = limitedContent(
                record.content,
                maxCharacters: decoded.resolvedMaxCharacters
            )

            renderedContent = limited.content
            truncated = limited.truncated
        } else {
            renderedContent = nil
            truncated = false
        }

        return try JSONToolBridge.encode(
            ReadArtifactToolOutput(
                artifact: record.artifact,
                content: renderedContent,
                truncated: truncated
            )
        )
    }
}

private extension ReadArtifactTool {
    func limitedContent(
        _ content: String,
        maxCharacters: Int?
    ) -> (content: String, truncated: Bool) {
        guard let maxCharacters else {
            return (
                content,
                false
            )
        }

        guard content.count > maxCharacters else {
            return (
                content,
                false
            )
        }

        return (
            String(
                content.prefix(
                    maxCharacters
                )
            ),
            true
        )
    }
}
