import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct ListSkillsTool: TypedInstanceAgentTool {
    public typealias Input = ListSkillsToolInput

    public static let identifier: AgentToolIdentifier = "list_skills"
    public static let description = "List available skills and their summaries."
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

    public let registry: SkillRegistry

    public init(
        registry: SkillRegistry
    ) {
        self.registry = registry
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ListSkillsToolInput.self,
            from: input
        )

        let query = decoded.query?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let summary = if let query,
                         !query.isEmpty {
            "List available skills matching '\(query)'."
        } else {
            "List all available skills."
        }

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: summary,
            sideEffects: risk.defaultSideEffects
        )
    }

    public func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            ListSkillsToolInput.self,
            from: input
        )

        let includeBody = decoded.includeBody ?? false
        let query = decoded.query?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let selected = registry.skills_sorted.filter { skill in
            guard let query,
                  !query.isEmpty
            else {
                return true
            }

            let normalized = query.lowercased()

            return skill.identifier.rawValue.lowercased().contains(normalized)
                || skill.name.lowercased().contains(normalized)
                || skill.summary.lowercased().contains(normalized)
        }

        let skills = selected.map { skill in
            ListedSkill(
                id: skill.identifier.rawValue,
                name: skill.name,
                summary: skill.summary,
                metadata: skill.metadata,
                body: includeBody ? skill.body : nil
            )
        }

        return try JSONToolBridge.encode(
            ListSkillsToolOutput(
                skills: skills,
                count: skills.count,
                catalog: selected
                    .map { skill in
                        skill.descriptionLine
                    }
                    .joined(separator: "\n")
            )
        )
    }
}
