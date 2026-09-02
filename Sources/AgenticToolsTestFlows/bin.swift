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
    ]
}
