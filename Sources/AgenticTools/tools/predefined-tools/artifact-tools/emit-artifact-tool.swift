import Agentic
import AgenticExecution
import AgenticWorkspace
import Foundation
import Primitives

public struct EmitArtifactToolInput: Sendable, Codable, Hashable {
    public let kind: AgentArtifactKind
    public let title: String?
    public let filename: String?
    public let contentType: String?
    public let content: String
    public let metadata: [String: String]

    public init(
        kind: AgentArtifactKind,
        title: String? = nil,
        filename: String? = nil,
        contentType: String? = nil,
        content: String,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.title = title
        self.filename = filename
        self.contentType = contentType
        self.content = content
        self.metadata = metadata
    }
}

public struct EmitArtifactToolOutput: Sendable, Codable, Hashable {
    public let artifact: AgentArtifact
    public let contentCharacterCount: Int
    public let approximateTokenCount: Int

    public init(
        artifact: AgentArtifact,
        contentCharacterCount: Int,
        approximateTokenCount: Int
    ) {
        self.artifact = artifact
        self.contentCharacterCount = contentCharacterCount
        self.approximateTokenCount = approximateTokenCount
    }
}

public struct EmitArtifactTool: AgentTool {
    public static let identifier: AgentToolIdentifier = "emit_artifact"
    public static let description = "Emit a durable runtime artifact under the current Agentic session artifact directory."
    public static let risk: ActionRisk = .boundedmutate

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
            EmitArtifactToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [],
            summary: summary(
                for: decoded
            ),
            estimatedWriteCount: 2,
            estimatedByteCount: Data(decoded.content.utf8).count,
            sideEffects: [
                "writes runtime artifact metadata",
                "writes runtime artifact content"
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            EmitArtifactToolInput.self,
            from: input
        )

        let record = try await store.emit(
            .init(
                kind: decoded.kind,
                title: decoded.title,
                filename: decoded.filename,
                contentType: decoded.contentType,
                content: decoded.content,
                metadata: decoded.metadata
            )
        )

        return try JSONToolBridge.encode(
            EmitArtifactToolOutput(
                artifact: record.artifact,
                contentCharacterCount: decoded.content.count,
                approximateTokenCount: approximateTokenCount(
                    forCharacterCount: decoded.content.count
                )
            )
        )
    }
}

private extension EmitArtifactTool {
    func summary(
        for input: EmitArtifactToolInput
    ) -> String {
        let title = input.title?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if let title,
           !title.isEmpty {
            return "Emit \(input.kind.rawValue) artifact '\(title)'"
        }

        if let filename = input.filename?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !filename.isEmpty {
            return "Emit \(input.kind.rawValue) artifact '\(filename)'"
        }

        return "Emit \(input.kind.rawValue) artifact"
    }

    func approximateTokenCount(
        forCharacterCount characterCount: Int
    ) -> Int {
        max(
            1,
            Int(
                (Double(characterCount) / 4.0).rounded(.up)
            )
        )
    }
}
