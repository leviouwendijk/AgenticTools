import Agentic
import AgenticExecution
import Foundation
import Guidelines
import Schema
import SchemaMacros

@JSONSchema
public struct GuidelineIndexToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Optional exact guideline area such as design, web_design, ergonomics, structure, or ai.
    public let area: String?

    public init(
        area: String? = nil
    ) {
        self.area = area
    }
}

public struct GuidelineIndexEntry:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let title: String
}

public struct GuidelineIndexChapter:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let area: String
    public let title: String
    public let guidelineCount: Int
    public let guidelines: [GuidelineIndexEntry]
}

public struct GuidelineIndexToolOutput:
    Sendable,
    Codable,
    Hashable
{
    public let area: String?
    public let chapterCount: Int
    public let guidelineCount: Int
    public let chapters: [GuidelineIndexChapter]
}

public struct GuidelineIndexTool: AgentTool {
    public typealias Input = GuidelineIndexToolInput
    public typealias Output = GuidelineIndexToolOutput

    public static let identifier: AgentToolIdentifier =
        "guideline_index"

    public static let description =
        "Inspect a cheap body-free index of guideline areas, chapters, references, and titles. Use this for structural orientation before loading summaries or full explanations."

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
        _ = try resolvedArea(
            input.area
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot:
                context.workspace?.rootURL.path,
            summary:
                "Inspect the body-free guideline index.",
            sideEffects:
                risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        let area = try resolvedArea(
            input.area
        )

        let chapters = GuidelineManual.chapters
            .filter {
                area == nil
                || $0.area == area
            }
            .map { chapter in
                GuidelineIndexChapter(
                    reference:
                        chapter.reference,
                    area:
                        chapter.area.rawValue,
                    title:
                        chapter.title,
                    guidelineCount:
                        chapter.guidelines.count,
                    guidelines:
                        chapter.guidelines.map {
                            GuidelineIndexEntry(
                                reference:
                                    $0.reference,
                                title:
                                    $0.title
                            )
                        }
                )
            }

        return .init(
            area:
                area?.rawValue,
            chapterCount:
                chapters.count,
            guidelineCount:
                chapters.reduce(0) {
                    $0 + $1.guidelineCount
                },
            chapters:
                chapters
        )
    }

    private func resolvedArea(
        _ rawValue: String?
    ) throws -> GuidelineArea? {
        guard let rawValue else {
            return nil
        }

        let normalized =
            rawValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !normalized.isEmpty else {
            return nil
        }

        guard let area =
            GuidelineArea(
                rawValue: normalized
            )
        else {
            throw GuidelineToolError
                .invalidArea(
                    normalized
                )
        }

        return area
    }
}
