import TestFlows

@main
enum AgenticToolsFlowTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: AgenticToolsFlowSuite.self
        )
    }
}

enum AgenticToolsFlowSuite:
    TestFlowRegistry
{
    static let title = "AgenticTools flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "find-tools-discovery-activation",
            tags: [
                "agentic-tools",
                "tools",
                "discovery",
                "search",
                "exposure",
            ]
        ) {
            try await AgenticToolsFlowTesting
                .runFindToolsDiscoveryActivation()
        },
        TestFlow(
            "find-tools-search-quality",
            tags: [
                "agentic-tools",
                "tools",
                "discovery",
                "search",
                "ranking",
            ]
        ) {
            try await AgenticToolsFlowTesting
                .runFindToolsSearchQuality()
        },
        TestFlow(
            "find-tools-input-bounds",
            tags: [
                "agentic-tools",
                "tools",
                "discovery",
                "bounds",
            ]
        ) {
            try AgenticToolsFlowTesting
                .runFindToolsInputBounds()
        },
        TestFlow(
            "inspect-tool-registry",
            tags: [
                "agentic-tools",
                "tools",
                "inspection",
                "registry",
                "schema",
            ]
        ) {
            try await AgenticToolsFlowTesting
                .runInspectToolRegistry()
        },
    ]
}
