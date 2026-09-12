import Agentic
import AgenticExecution
import Foundation
import Guidelines
import GuidelinesSearch
import Schema
import Macros

@JSONSchema
public struct ReadGuidelineToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Exact guideline reference returned by guideline_index or find_guidelines.
    public let reference: String

    public init(
        reference: String
    ) {
        self.reference = reference
    }
}

public struct ReadGuidelineToolOutput:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let area: String
    public let title: String
    public let summary: String
    public let explanation: String
}

public struct ReadGuidelineTool: AgentTool {
    public typealias Input = ReadGuidelineToolInput
    public typealias Output = ReadGuidelineToolOutput

    public static let identifier: AgentToolIdentifier =
        "read_guideline"

    public static let description =
        "Load the full title, summary, and explanation for one exact guideline reference after discovery or when the reference is already known."

    public static let risk: ActionRisk =
        .observe

    public init() {}

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        let reference =
            try normalizedReference(
                input.reference
            )

        _ = try guideline(
            reference: reference
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot:
                context.workspace?.rootURL.path,
            summary:
                "Load the full explanation for guideline '\(reference)'.",
            sideEffects:
                risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        let reference =
            try normalizedReference(
                input.reference
            )

        let guideline =
            try guideline(
                reference: reference
            )

        return .init(
            reference:
                guideline.reference,
            area:
                guideline.area.rawValue,
            title:
                guideline.title,
            summary:
                guideline.summary,
            explanation:
                GuidelineStructuredContentProjection
                    .text(
                        guideline.explanation
                    )
        )
    }

    private func normalizedReference(
        _ value: String
    ) throws -> String {
        let reference =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !reference.isEmpty else {
            throw GuidelineToolError
                .missingReference
        }

        return reference
    }

    private func guideline(
        reference: String
    ) throws -> Guideline {
        guard let guideline =
            Guideline.all.first(
                where: {
                    $0.reference == reference
                }
            )
        else {
            throw GuidelineToolError
                .unknownGuideline(
                    reference
                )
        }

        return guideline
    }
}

@JSONSchema
public struct ReadGuidelineChapterToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Exact chapter reference returned by guideline_index.
    public let reference: String

    public init(
        reference: String
    ) {
        self.reference = reference
    }
}

public struct ReadGuidelineChapterToolOutput:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let area: String
    public let title: String
    public let introduction: String
    public let guidelineCount: Int
    public let guidelines: [GuidelineToolSummary]
}

public struct ReadGuidelineChapterTool: AgentTool {
    public typealias Input = ReadGuidelineChapterToolInput
    public typealias Output = ReadGuidelineChapterToolOutput

    public static let identifier: AgentToolIdentifier =
        "read_guideline_chapter"

    public static let description =
        "Load one guideline chapter introduction plus guideline references, titles, and summaries without loading every full guideline explanation."

    public static let risk: ActionRisk =
        .observe

    public init() {}

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        let reference =
            try normalizedReference(
                input.reference
            )

        _ = try chapter(
            reference: reference
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot:
                context.workspace?.rootURL.path,
            summary:
                "Load summary-level context for guideline chapter '\(reference)'.",
            sideEffects:
                risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        let reference =
            try normalizedReference(
                input.reference
            )

        let chapter =
            try chapter(
                reference: reference
            )

        let guidelines =
            chapter.guidelines.map {
                GuidelineToolSummary(
                    guideline: $0,
                    chapter: chapter
                )
            }

        return .init(
            reference:
                chapter.reference,
            area:
                chapter.area.rawValue,
            title:
                chapter.title,
            introduction:
                GuidelineStructuredContentProjection
                    .text(
                        chapter.introduction
                    ),
            guidelineCount:
                guidelines.count,
            guidelines:
                guidelines
        )
    }

    private func normalizedReference(
        _ value: String
    ) throws -> String {
        let reference =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !reference.isEmpty else {
            throw GuidelineToolError
                .missingReference
        }

        return reference
    }

    private func chapter(
        reference: String
    ) throws -> GuidelineChapter {
        guard let chapter =
            GuidelineManual.chapters.first(
                where: {
                    $0.reference == reference
                }
            )
        else {
            throw GuidelineToolError
                .unknownChapter(
                    reference
                )
        }

        return chapter
    }
}
