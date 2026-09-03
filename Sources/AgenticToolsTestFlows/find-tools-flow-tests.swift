import Agentic
import AgenticExecution
import AgenticTools
import AgenticWorkspace
import Primitives
import TestFlows

private struct FindToolsProbeTool:
    TypedInstanceAgentTool
{
    typealias Input = FindToolsToolInput

    let identifier: AgentToolIdentifier
    let description: String
    let risk: ActionRisk

    func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        input
    }
}

enum AgenticToolsFlowTesting {
    static func runFindToolsDiscoveryActivation() async throws -> [TestFlowDiagnostic] {
        var catalog = ToolRegistry()

        try catalog.register(
            [
                FindToolsProbeTool(
                    identifier: "read_file",
                    description: "Read a bounded source file from the current workspace.",
                    risk: .observe
                ),
                FindToolsProbeTool(
                    identifier: "git_push",
                    description: "Push committed Git history to a configured remote repository.",
                    risk: .privileged
                ),
            ] as [any AgentTool]
        )

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

        var runtimeRegistry = catalog
        try runtimeRegistry.register(
            findTools
        )

        let initiallyExposed = try await exposure
            .definitions(
                in: runtimeRegistry
            )
            .map(\.name)

        try Expect.equal(
            initiallyExposed,
            [
                "find_tools",
            ],
            "discoverable runtime begins with only find_tools exposed"
        )

        let greetingOutputValue = try await findTools.call(
            input: try JSONToolBridge.encode(
                FindToolsToolInput(
                    query: "hi"
                )
            ),
            workspace: nil
        )

        let greetingOutput = try JSONToolBridge.decode(
            FindToolsToolOutput.self,
            from: greetingOutputValue
        )

        try Expect.equal(
            greetingOutput.tools.isEmpty,
            true,
            "low-signal greeting returns no discovered tools"
        )

        try Expect.equal(
            greetingOutput.activated.isEmpty,
            true,
            "low-signal greeting activates no tools"
        )

        let afterGreeting = try await exposure
            .definitions(
                in: runtimeRegistry
            )
            .map(\.name)

        try Expect.equal(
            afterGreeting,
            [
                "find_tools",
            ],
            "low-signal discovery leaves exposure unchanged"
        )

        let unrelatedOutputValue = try await findTools.call(
            input: try JSONToolBridge.encode(
                FindToolsToolInput(
                    query: "qzxwvv"
                )
            ),
            workspace: nil
        )

        let unrelatedOutput = try JSONToolBridge.decode(
            FindToolsToolOutput.self,
            from: unrelatedOutputValue
        )

        try Expect.equal(
            unrelatedOutput.tools.isEmpty,
            true,
            "unrelated capability query returns no tools"
        )

        try Expect.equal(
            unrelatedOutput.activated.isEmpty,
            true,
            "unrelated capability query activates no tools"
        )

        let outputValue = try await findTools.call(
            input: try JSONToolBridge.encode(
                FindToolsToolInput(
                    query: "read a source file",
                    maximumResults: 1
                )
            ),
            workspace: nil
        )

        let output = try JSONToolBridge.decode(
            FindToolsToolOutput.self,
            from: outputValue
        )

        try Expect.equal(
            output.tools.map(\.identifier),
            [
                AgentToolIdentifier(
                    "read_file"
                ),
            ],
            "Search ranks read_file first for a source-file reading query"
        )

        try Expect.equal(
            output.activated,
            [
                AgentToolIdentifier(
                    "read_file"
                ),
            ],
            "find_tools activates its returned match"
        )

        let subsequentlyExposed = try await exposure
            .definitions(
                in: runtimeRegistry
            )
            .map(\.name)

        try Expect.equal(
            subsequentlyExposed,
            [
                "find_tools",
                "read_file",
            ],
            "activated tool persists into subsequent model exposure"
        )

        let parsed = try await exposure.parseModelCall(
            AgentToolCall(
                id: "read-after-discovery",
                name: "read_file",
                input: try JSONToolBridge.encode(
                    FindToolsToolInput(
                        query: "fixture"
                    )
                )
            ),
            registry: runtimeRegistry
        )

        try Expect.equal(
            parsed.call.name,
            "read_file",
            "discovered tool becomes model-callable through exposure enforcement"
        )

        try Expect.equal(
            runtimeRegistry.count,
            3,
            "discovery leaves the complete runtime registry intact"
        )

        try Expect.equal(
            runtimeRegistry.tool(
                named: "git_push"
            ) != nil,
            true,
            "unexposed tools remain installed in the runtime registry"
        )

        return [
            .field(
                "initial",
                initiallyExposed.joined(separator: ",")
            ),
            .field(
                "subsequent",
                subsequentlyExposed.joined(separator: ",")
            ),
        ]
    }

    static func runFindToolsInputBounds() throws -> [TestFlowDiagnostic] {
        try Expect.equal(
            FindToolsToolInput(
                query: "anything"
            ).resultLimit,
            5,
            "find_tools defaults to five results"
        )

        try Expect.equal(
            FindToolsToolInput(
                query: "anything",
                maximumResults: 100
            ).resultLimit,
            8,
            "find_tools caps result activation at eight tools"
        )

        try Expect.equal(
            FindToolsToolInput(
                query: "anything",
                maximumResults: 0
            ).resultLimit,
            1,
            "find_tools keeps result activation positively bounded"
        )

        return [
            .field(
                "default-limit",
                "5"
            ),
            .field(
                "maximum-limit",
                "8"
            ),
        ]
    }
}
