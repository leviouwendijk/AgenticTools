import Agentic
import AgenticExecution
import AgenticWorkspace
import Foundation
import Primitives
import Schema
import SchemaMacros

@JSONSchema
public struct EmitArtifactToolInput: Sendable, Codable, Hashable {
    /// Artifact kind to emit.
    public let kind: AgentArtifactKind
    /// Optional human-readable artifact title.
    public let title: String?
    /// Optional preferred artifact filename.
    public let filename: String?
    /// Optional MIME/content type.
    public let contentType: String?
    /// Artifact content to persist.
    public let content: String
    /// Additional artifact metadata.
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
    public typealias Input = EmitArtifactToolInput
    public typealias Output = EmitArtifactToolOutput

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
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: context.workspace?.rootURL.path,
            targetPaths: [],
            summary: summary(
                for: input
            ),
            estimatedWriteCount: 2,
            estimatedByteCount: Data(input.content.utf8).count,
            sideEffects: [
                "writes runtime artifact metadata",
                "writes runtime artifact content"
            ]
        )
    }

    public func call(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> Output {

        let record = try await store.emit(
            .init(
                kind: input.kind,
                title: input.title,
                filename: input.filename,
                contentType: input.contentType,
                content: input.content,
                metadata: input.metadata
            )
        )

        return EmitArtifactToolOutput(
                artifact: record.artifact,
                contentCharacterCount: input.content.count,
                approximateTokenCount: approximateTokenCount(
                    forCharacterCount: input.content.count
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