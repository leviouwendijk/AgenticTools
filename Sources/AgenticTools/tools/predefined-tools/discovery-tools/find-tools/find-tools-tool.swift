import Agentic
import AgenticExecution
import AgenticWorkspace
import Foundation
import Primitives
import Search

public struct FindToolsTool:
    TypedInstanceAgentTool
{
    public typealias Input = FindToolsToolInput

    public static let identifier: AgentToolIdentifier = "find_tools"
    public static let description = "Search the installed Agentic tool catalog for capabilities relevant to the current task. Returned matches are exposed as native tools on subsequent model turns."
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

    public let registry: ToolRegistry
    public let exposure: AgentToolExposure

    public init(
        registry: ToolRegistry,
        exposure: AgentToolExposure
    ) {
        self.registry = registry
        self.exposure = exposure
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            FindToolsToolInput.self,
            from: input
        )
        let query = try normalizedQuery(
            decoded.query
        )

        return ToolPreflight(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Find and activate up to \(decoded.resultLimit) installed tool(s) matching '\(query)'.",
            sideEffects: [
                "updates model-visible tool exposure for subsequent turns",
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            FindToolsToolInput.self,
            from: input
        )
        let query = try normalizedQuery(
            decoded.query
        )
        let definitions = registry
            .modelFacingDefinitions
            .filter {
                $0.identifier != Self.identifier
            }

        let definitionsByIdentifier = Dictionary(
            uniqueKeysWithValues: definitions.map { definition in
                (
                    definition.identifier,
                    definition
                )
            }
        )

        let corpus = SearchCorpus(
            documents: definitions.map { definition in
                SearchDocument(
                    id: definition.identifier,
                    text: [
                        definition.identifier.rawValue,
                        definition.description,
                        definition.risk.rawValue,
                    ]
                    .joined(separator: "\n")
                )
            }
        )

        let result = TextSearch.search(
            query,
            in: corpus,
            options: .defaults
        )

        let tools = result.hits
            .prefix(
                decoded.resultLimit
            )
            .compactMap { hit -> FoundAgentTool? in
                guard let definition = definitionsByIdentifier[
                    hit.documentID
                ] else {
                    return nil
                }

                return FoundAgentTool(
                    identifier: definition.identifier,
                    description: definition.description,
                    risk: definition.risk
                )
            }

        let activated = try await exposure.activate(
            tools.map(\.identifier),
            in: registry
        )

        return try JSONToolBridge.encode(
            FindToolsToolOutput(
                query: query,
                tools: tools,
                activated: activated
            )
        )
    }
}

private extension FindToolsTool {
    func normalizedQuery(
        _ query: String
    ) throws -> String {
        let query = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            throw FindToolsToolError.emptyQuery
        }

        return query
    }
}
