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
            "advisor-semantic-model-invocation",
            tags: [
                "agentic-tools",
                "advisor",
                "model-invocation",
                "routing",
            ]
        ) {
            try await AgenticToolsFlowTesting
                .runAdvisorSemanticInvocation()
        },
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
            "guideline-tools-progressive-disclosure",
            tags: [
                "agentic-tools",
                "guidelines",
                "tools",
                "progressive-disclosure",
            ]
        ) {
            try await AgenticToolsFlowTesting
                .runGuidelineToolsProgressiveDisclosure()
        },
        TestFlow(
            "guideline-tools-search-bounds",
            tags: [
                "agentic-tools",
                "guidelines",
                "tools",
                "bounds",
            ]
        ) {
            try await AgenticToolsFlowTesting
                .runGuidelineToolsSearchBounds()
        },
    ]
}
