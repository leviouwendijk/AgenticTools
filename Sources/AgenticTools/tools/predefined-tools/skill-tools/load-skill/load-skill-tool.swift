import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives

public struct LoadSkillTool: TypedInstanceAgentTool {
    public typealias Input = LoadSkillToolInput

    public static let identifier: AgentToolIdentifier = "load_skill"
    public static let description = "Load the full instructions for one available skill by id or name."
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
            LoadSkillToolInput.self,
            from: input
        )

        let lookup = try lookupValue(
            from: decoded
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Load skill '\(lookup)'.",
            sideEffects: risk.defaultSideEffects
        )
    }

    public func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            LoadSkillToolInput.self,
            from: input
        )

        let lookup = try lookupValue(
            from: decoded
        )
        let skill = try registry.requireSkill(
            matching: lookup
        )

        return try JSONToolBridge.encode(
            LoadSkillToolOutput(
                id: skill.identifier.rawValue,
                name: skill.name,
                summary: skill.summary,
                content: skill.contextText,
                metadata: decoded.includeMetadata == true ? skill.metadata : nil
            )
        )
    }
}

private extension LoadSkillTool {
    func lookupValue(
        from input: LoadSkillToolInput
    ) throws -> String {
        let value = input.id ?? input.name
        let trimmed = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let trimmed,
              !trimmed.isEmpty
        else {
            throw SkillToolError.missingSkillIdentifier
        }

        return trimmed
    }
}
