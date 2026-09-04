import Agentic
import AgenticExecution
import AgenticWorkspace
import Foundation
import Primitives

public struct AgentAdvisorTool: AgentTool {
    public typealias Input = AgentAdvisorToolInput
    public typealias Output = AgentAdvisorToolOutput

    public static let identifier = AgentAdvisorToolDefaults.identifier

    public var provider: any AgentAdvisorModelProviding
    public var configuration: AgentAdvisorToolConfiguration

    public init(
        provider: any AgentAdvisorModelProviding,
        configuration: AgentAdvisorToolConfiguration = .init()
    ) {
        self.provider = provider
        self.configuration = configuration
    }

    public var identifier: AgentToolIdentifier {
        configuration.identifier
    }

    public var description: String {
        "Ask the configured advisor model for bounded, advisory reasoning. The advisor receives no tools and cannot authorize actions."
    }

    public var risk: ActionRisk {
        .observe
    }

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        ToolPreflight(
            toolName: name,
            risk: risk,
            workspaceRoot: context.workspace?.rootURL.path,
            summary: """
            Ask an advisor model using route purpose '\(configuration.routePolicy.purpose.rawValue)'.

            The advisor call receives bounded text context only.
            No tools are exposed to the advisor model.
            """,
            sideEffects: [
                "model_call",
                "route:\(configuration.routePolicy.purpose.rawValue)",
            ]
        )
    }

    public func call(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> Output {

        let prompt = try Self.normalizedPrompt(
            input.prompt
        )

        var metadata = context.metadata

        metadata["tool"] = identifier.rawValue
        metadata["route"] = configuration.routePolicy.purpose.rawValue

        let request = AgentRequest(
            messages: [
                .init(
                    role: .system,
                    text: configuration.systemPrompt
                ),
                .init(
                    role: .user,
                    text: Self.userPrompt(
                        input: input,
                        prompt: prompt
                    )
                ),
            ],
            tools: [],
            generationConfiguration: .init(
                maxOutputTokens: configuration.maxOutputTokens,
                temperature: configuration.temperature
            ),
            metadata: metadata
        )

        let route = try provider.route(
            request: request,
            policy: configuration.routePolicy
        )

        let response = try await provider.buffered(
            request: request,
            policy: configuration.routePolicy
        )

        let output = AgentAdvisorToolOutput(
            routePurpose: route.route.purpose.rawValue,
            profile: route.route.profile.identifier.rawValue,
            adapter: route.route.profile.adapterIdentifier.rawValue,
            model: route.route.profile.model,
            reasons: route.reasons,
            warnings: route.warnings,
            advice: response.message.content.text
        )

        return output
    }
}

private extension AgentAdvisorTool {
    static func normalizedPrompt(
        _ value: String
    ) throws -> String {
        let prompt = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !prompt.isEmpty else {
            throw AgentAdvisorToolError.emptyPrompt
        }

        return prompt
    }

    static func normalizedOptionalText(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }

    static func userPrompt(
        input: AgentAdvisorToolInput,
        prompt: String
    ) -> String {
        var sections: [String] = []

        if let context = normalizedOptionalText(
            input.context
        ) {
            sections.append(
                """
                Context:
                \(context)
                """
            )
        }

        sections.append(
            """
            Question:
            \(prompt)
            """
        )

        if let instruction = normalizedOptionalText(
            input.instruction
        ) {
            sections.append(
                """
                Instruction:
                \(instruction)
                """
            )
        }

        return sections.joined(
            separator: "\n\n"
        )
    }
}