import Agentic
import AgenticExecution
import AgenticTools
import AgenticWorkspace
import Primitives
import TestFlows

extension AgenticToolsFlowTesting {
    static func runFindToolsSearchQuality()
        async throws
        -> [TestFlowDiagnostic]
    {
        var catalog = ToolRegistry()

        try catalog.register {
            FindToolsSearchQualityProbeTool(
                identifier: "git_repository_state",
                description: "Inspect Git repository status and working-tree state without mutating the repository.",
                risk: .observe
            )
            FindToolsSearchQualityProbeTool(
                identifier: "git_diff",
                description: "Observe tracked Git working-tree and staged differences.",
                risk: .observe
            )
            FindToolsSearchQualityProbeTool(
                identifier: "git_push",
                description: "Push committed Git history to a configured remote repository.",
                risk: .privileged
            )
            FindToolsSearchQualityProbeTool(
                identifier: "git_diff_helper",
                description: "Helper documentation mentioning git_diff and Git differences repeatedly.",
                risk: .observe
            )
            FindToolsSearchQualityProbeTool(
                identifier: "read_file",
                description: "Read a bounded source file from the current workspace.",
                risk: .observe
            )
        }

        let exposure = AgentToolExposure(
            policy: .discoverable(
                [
                    FindToolsTool.identifier,
                ]
            )
        )
        let findTools = FindToolsTool(
            registry: catalog,
            exposure: exposure
        )

        let naturalOutput = try await findTools.call(
            FindToolsToolInput(
                query: "git status",
                maximumResults: 3
            ),
            context: .init()
        )

        try Expect.equal(
            naturalOutput.tools.first?.identifier,
            Optional(
                AgentToolIdentifier(
                    "git_repository_state"
                )
            ),
            "natural-language git status ranks repository-state capability first"
        )

        try Expect.equal(
            naturalOutput.activated.contains(
                AgentToolIdentifier(
                    "git_repository_state"
                )
            ),
            true,
            "natural-language discovery activates the strongest ranked capability"
        )

        try Expect.equal(
            Set(
                naturalOutput.activated
            ),
            Set(
                naturalOutput.tools.map(\.identifier)
            ),
            "activation reports the selected tool set without requiring ranking order"
        )

        let exactOutput = try await findTools.call(
            FindToolsToolInput(
                query: "git_diff",
                maximumResults: 3
            ),
            context: .init()
        )

        try Expect.equal(
            exactOutput.tools.first?.identifier,
            Optional(
                AgentToolIdentifier(
                    "git_diff"
                )
            ),
            "exact identifier is pinned ahead of fuzzy competitors"
        )

        let descriptionOutput = try await findTools.call(
            FindToolsToolInput(
                query: "read source file",
                maximumResults: 2
            ),
            context: .init()
        )

        try Expect.equal(
            descriptionOutput.tools.first?.identifier,
            Optional(
                AgentToolIdentifier(
                    "read_file"
                )
            ),
            "description evidence contributes independently to capability ranking"
        )

        let lowSignalOutput = try await findTools.call(
            FindToolsToolInput(
                query: "hi"
            ),
            context: .init()
        )

        try Expect.equal(
            lowSignalOutput.tools.isEmpty,
            true,
            "low-signal query still returns no tools"
        )
        try Expect.equal(
            lowSignalOutput.activated.isEmpty,
            true,
            "low-signal query still leaves exposure unchanged"
        )

        return [
            .field(
                "natural",
                naturalOutput.tools.first?.identifier.rawValue
                    ?? "<none>"
            ),
            .field(
                "exact",
                exactOutput.tools.first?.identifier.rawValue
                    ?? "<none>"
            ),
            .field(
                "description",
                descriptionOutput.tools.first?.identifier.rawValue
                    ?? "<none>"
            ),
        ]
    }
}

private struct FindToolsSearchQualityProbeTool: AgentTool {
    typealias Input = FindToolsToolInput
    typealias Output = FindToolsToolInput

    let identifier: AgentToolIdentifier
    let description: String
    let risk: ActionRisk

    func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        input
    }
}