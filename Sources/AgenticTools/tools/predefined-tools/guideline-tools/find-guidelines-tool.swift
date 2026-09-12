import Agentic
import AgenticExecution
import Foundation
import GuidelinesSearch
import Schema
import Macros

@JSONSchema
public struct FindGuidelinesToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Natural-language intent, guideline title, summary text, or exact guideline reference.
    public let query: String

    /// Optional result limit. Defaults to 5 and is clamped to 1...8.
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

public struct FindGuidelinesToolOutput:
    Sendable,
    Codable,
    Hashable
{
    public let query: String
    public let count: Int
    public let matches: [GuidelineToolSummary]
}

public struct FindGuidelinesTool: AgentTool {
    public typealias Input = FindGuidelinesToolInput
    public typealias Output = FindGuidelinesToolOutput

    public static let identifier: AgentToolIdentifier =
        "find_guidelines"

    public static let description =
        "Search guidelines by natural-language intent and return a bounded set of references, titles, chapters, and summaries without full explanations."

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
        let query = try normalizedQuery(
            input.query
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot:
                context.workspace?.rootURL.path,
            summary:
                "Search guideline summaries for '\(query)' with at most \(input.resultLimit) result(s).",
            sideEffects:
                risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        let query = try normalizedQuery(
            input.query
        )

        let matches: [GuidelineToolSummary] =
            GuidelineSearchIndex()
                .searchGuidelines(
                    query,
                    limit: input.resultLimit
                )
                .compactMap { entry -> GuidelineToolSummary? in
                    guard let guideline = entry.guideline else {
                        return nil
                    }

                    return GuidelineToolSummary(
                        guideline: guideline,
                        chapter: entry.chapter
                    )
                }

                return .init(
                    query: query,
                    count: matches.count,
                    matches: matches
                )
            }

    private func normalizedQuery(
        _ value: String
    ) throws -> String {
        let query =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !query.isEmpty else {
            throw GuidelineToolError
                .emptyQuery
        }

        return query
    }
}
