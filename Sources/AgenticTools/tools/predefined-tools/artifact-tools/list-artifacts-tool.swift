import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives
import Schema
import SchemaMacros

@JSONSchema
public struct ListArtifactsToolInput: Sendable, Codable, Hashable {
    /// Artifact kinds to include. An empty array includes every kind.
    public let kinds: [AgentArtifactKind]
    /// Whether to list newest artifacts first. Defaults to true when omitted.
    public let latestFirst: Bool?
    /// Optional maximum number of artifacts to return.
    public let limit: Int?

    public init(
        kinds: [AgentArtifactKind] = [],
        latestFirst: Bool? = nil,
        limit: Int? = nil
    ) {
        self.kinds = kinds
        self.latestFirst = latestFirst
        self.limit = limit
    }

    public var resolvedLatestFirst: Bool {
        latestFirst ?? true
    }

    public var resolvedLimit: Int? {
        guard let limit else {
            return nil
        }

        return max(
            0,
            limit
        )
    }
}

public struct ListArtifactsToolOutput: Sendable, Codable, Hashable {
    public let artifacts: [AgentArtifact]
    public let count: Int

    public init(
        artifacts: [AgentArtifact]
    ) {
        self.artifacts = artifacts
        self.count = artifacts.count
    }
}

public struct ListArtifactsTool: TypedInstanceAgentTool {
    public typealias Input = ListArtifactsToolInput

    public static let identifier: AgentToolIdentifier = "list_artifacts"
    public static let description = "List durable artifacts emitted for the current Agentic session."
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
            ListArtifactsToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: summary(
                for: decoded
            ),
            sideEffects: []
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            ListArtifactsToolInput.self,
            from: input
        )

        let artifacts = try await store.list(
            kinds: decoded.kinds,
            latestFirst: decoded.resolvedLatestFirst,
            limit: decoded.resolvedLimit
        )

        return try JSONToolBridge.encode(
            ListArtifactsToolOutput(
                artifacts: artifacts
            )
        )
    }
}

private extension ListArtifactsTool {
    func summary(
        for input: ListArtifactsToolInput
    ) -> String {
        guard !input.kinds.isEmpty else {
            return "List session artifacts"
        }

        return "List session artifacts filtered to \(input.kinds.map(\.rawValue).joined(separator: ", "))"
    }
}
