import Agentic
import AgenticExecution
import AgenticTools
import TestFlows

private struct FixtureAdvisorModelInvoker: AgentModelInvoking {
    func buffered(
        _ invocation: AgentModelInvocation
    ) async throws -> AgentModelInvocationResult {
        let route = AgentModelRoute(
            purpose: invocation.selection.purpose,
            profile: AgentModelProfile(
                identifier: "fixture.advisor",
                gatewayIdentifier: "fixture.gateway",
                model: "fixture-advisor",
                purposes: [
                    .advisor,
                ]
            )
        )
        let diagnostic = AgentModelSelectionDiagnostic(
            code: .purpose_match_selected,
            message: "fixture advisor route"
        )

        return AgentModelInvocationResult(
            response: AgentResponse(
                message: .init(
                    role: .assistant,
                    text: "fixture advice"
                ),
                stopReason: .end_turn
            ),
            route: AgentModelRouteRecord(
                route: route,
                diagnostics: [
                    diagnostic,
                ],
                requestMetadata: invocation.metadata
            )
        )
    }

    func stream(
        _ invocation: AgentModelInvocation
    ) -> AsyncThrowingStream<AgentModelInvocationEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}

extension AgenticToolsFlowTesting {
    static func runAdvisorSemanticInvocation() async throws -> [TestFlowDiagnostic] {
        let tool = AgentAdvisorTool(
            modelInvoker: FixtureAdvisorModelInvoker()
        )
        let output = try await tool.call(
            AgentAdvisorToolInput(
                prompt: "Review this architecture."
            ),
            context: .init()
        )

        try Expect.equal(
            output.routePurpose,
            AgentModelRoutePurpose.advisor.rawValue,
            "advisor tool invokes the advisor model selection"
        )
        try Expect.equal(
            output.profile,
            "fixture.advisor",
            "advisor tool reports the exact routed profile"
        )
        try Expect.equal(
            output.gateway,
            "fixture.gateway",
            "advisor tool reports the exact routed gateway"
        )
        try Expect.equal(
            output.model,
            "fixture-advisor",
            "advisor tool reports the exact routed model"
        )
        try Expect.equal(
            output.advice,
            "fixture advice",
            "advisor tool returns the semantic invocation response"
        )
        try Expect.equal(
            output.diagnostics.map(\.code),
            [
                .purpose_match_selected,
            ],
            "advisor tool preserves typed route diagnostics"
        )

        var registry = ToolRegistry()
        try AgentAdvisorToolSet(
            modelInvoker: FixtureAdvisorModelInvoker()
        ).register(
            into: &registry
        )

        try Expect.equal(
            registry.registeredTool(
                identifiedBy: AgentAdvisorTool.identifier
            ) != nil,
            true,
            "advisor tool set registers through the concrete registry API"
        )

        return [
            .field(
                "purpose",
                output.routePurpose
            ),
            .field(
                "profile",
                output.profile
            ),
            .field(
                "gateway",
                output.gateway
            ),
            .field(
                "model",
                output.model
            ),
            .field(
                "diagnostics",
                String(output.diagnostics.count)
            ),
        ]
    }
}
