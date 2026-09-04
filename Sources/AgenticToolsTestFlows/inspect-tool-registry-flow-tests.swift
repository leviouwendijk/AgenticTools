import Agentic
import AgenticExecution
import AgenticTools
import TestFlows

extension AgenticToolsFlowTesting {
    static func runInspectToolRegistry()
        async throws
        -> [TestFlowDiagnostic]
    {
        var registry = ToolRegistry()

        try registry.register {
            InspectToolRegistryProbeTool(
                identifier: "read_file",
                description:
                    "Read a bounded source file from the current workspace.",
                risk: .observe,
                execution: .fixed
            )
            InspectToolRegistryProbeTool(
                identifier: "git_push",
                description:
                    "Push committed Git history to a configured remote repository.",
                risk: .privileged,
                execution: .targetable
            )
        }

        let inspection = registry.inspect()

        try Expect.equal(
            inspection.totalCount,
            2,
            "registry inspection retains complete installed count"
        )
        try Expect.equal(
            inspection.tools.map(
                \.identifier
            ),
            [
                AgentToolIdentifier(
                    "git_push"
                ),
                AgentToolIdentifier(
                    "read_file"
                ),
            ],
            "registry inspection preserves deterministic registry ordering"
        )
        try Expect.equal(
            registry.inspect(
                identifiedBy:
                    AgentToolIdentifier(
                        "git_push"
                    )
            )?.workingLocation,
            Optional(
                AgentToolExecutionContract
                    .WorkingLocation
                    .targetable
            ),
            "exact inspection retains execution contract"
        )
        try Expect.equal(
            registry.inspect(
                identifiedBy:
                    AgentToolIdentifier(
                        "missing_tool"
                    )
            ) == nil,
            true,
            "exact inspection returns nil for an unregistered identifier"
        )

        let tool = InspectToolRegistryTool(
            registry: registry
        )
        let listed = try await tool.call(
            .init(),
            context: .init()
        )

        try Expect.equal(
            listed.totalCount,
            2,
            "model-facing inspection reports complete captured registry count"
        )
        try Expect.equal(
            listed.returnedCount,
            2,
            "model-facing inspection lists the captured registry by default"
        )
        try Expect.equal(
            listed.tools.allSatisfy {
                $0.semanticInputSchema == nil
            },
            true,
            "schemas are omitted by default"
        )
        try Expect.equal(
            listed.tools.allSatisfy {
                $0.hasSemanticInputSchema
            },
            true,
            "schema availability remains visible without dumping schemas"
        )

        let exact = try await tool.call(
            .init(
                identifier: "git_push",
                includeSchemas: true
            ),
            context: .init()
        )

        try Expect.equal(
            exact.returnedCount,
            1,
            "exact model-facing inspection returns one registered tool"
        )
        try Expect.equal(
            exact.tools.first?.identifier,
            Optional(
                AgentToolIdentifier(
                    "git_push"
                )
            ),
            "exact model-facing inspection resolves the requested identifier"
        )
        try Expect.equal(
            exact.tools.first?
                .workingLocation,
            Optional(
                AgentToolExecutionContract
                    .WorkingLocation
                    .targetable
            ),
            "model-facing inspection exposes targetable execution metadata"
        )
        try Expect.equal(
            exact.tools.first?
                .semanticInputSchema != nil,
            true,
            "schema is included only when requested"
        )

        let missing = try await tool.call(
            .init(
                identifier: "missing_tool"
            ),
            context: .init()
        )

        try Expect.equal(
            missing.totalCount,
            2,
            "missing exact lookup still reports complete registry count"
        )
        try Expect.equal(
            missing.returnedCount,
            0,
            "missing exact lookup returns an empty result instead of mutating or widening"
        )
        try Expect.equal(
            registry.count,
            2,
            "inspection never changes the captured registry"
        )

        return [
            .field(
                "registered",
                "\(listed.totalCount)"
            ),
            .field(
                "exact",
                exact.tools.first?
                    .identifier.rawValue
                    ?? "<none>"
            ),
            .field(
                "missing",
                "\(missing.returnedCount)"
            ),
        ]
    }
}

private struct InspectToolRegistryProbeTool:
    AgentTool
{
    typealias Input = FindToolsToolInput
    typealias Output = FindToolsToolInput

    let identifier: AgentToolIdentifier
    let description: String
    let risk: ActionRisk
    let execution: AgentToolExecutionContract

    func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        input
    }
}
