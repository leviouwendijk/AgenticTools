import Agentic
import AgenticExecution
import AgenticWorkspace
import Foundation
import Primitives
import Schema

public struct InspectToolRegistryTool:
    AgentTool
{
    public typealias Input =
        InspectToolRegistryToolInput
    public typealias Output =
        InspectToolRegistryToolOutput

    public static let identifier:
        AgentToolIdentifier = "inspect_tool_registry"

    public static let description =
        "Inspect the captured installed Agentic tool registry by listing registered tools or reading one exact identifier. Returns registration metadata and can optionally include semantic input schemas. This does not report or change current model-visible tool exposure."

    public static let risk:
        ActionRisk = .observe

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

    public init(
        registry: ToolRegistry
    ) {
        self.registry = registry
    }

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        let identifier = normalizedIdentifier(
            input.identifier
        )

        return ToolPreflight(
            toolName: name,
            risk: risk,
            workspaceRoot:
                context.workspace?.rootURL.path,
            summary:
                identifier.map {
                    "Inspect registered tool '\($0)' without changing model exposure."
                }
                ?? "Inspect all \(registry.count) captured registered tool(s) without changing model exposure.",
            sideEffects: []
        )
    }

    public func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        let inspection = registry.inspect()
        let entries:
            [AgentToolRegistryInspectionEntry]

        if let identifier = normalizedIdentifier(
            input.identifier
        ) {
            entries = registry.inspect(
                identifiedBy: .init(
                    identifier
                )
            ).map {
                [
                    $0,
                ]
            } ?? []
        } else {
            entries = inspection.tools
        }

        let tools = entries.map { entry in
            InspectedAgentTool(
                identifier: entry.identifier,
                description: entry.description,
                risk: entry.risk,
                modelFacing: entry.isModelFacing,
                workingLocation:
                    entry.workingLocation,
                hasSemanticInputSchema:
                    entry.semanticInputSchema != nil,
                semanticInputSchema:
                    input.resolvedIncludeSchemas
                        ? entry.semanticInputSchema?.jsonvalue
                        : nil
            )
        }

        return .init(
            totalCount: inspection.totalCount,
            returnedCount: tools.count,
            tools: tools
        )
    }
}

private extension InspectToolRegistryTool {
    func normalizedIdentifier(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
