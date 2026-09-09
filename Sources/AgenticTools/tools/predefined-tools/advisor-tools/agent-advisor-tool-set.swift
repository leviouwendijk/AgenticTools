import Agentic
import AgenticExecution

public struct AgentAdvisorToolSet: AgentToolSet {
    public var modelInvoker: any AgentModelInvoking
    public var configuration: AgentAdvisorToolConfiguration

    public init(
        modelInvoker: any AgentModelInvoking,
        configuration: AgentAdvisorToolConfiguration = .init()
    ) {
        self.modelInvoker = modelInvoker
        self.configuration = configuration
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            AgentAdvisorTool(
                modelInvoker: modelInvoker,
                configuration: configuration
            )
        )
    }
}
