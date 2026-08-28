import Agentic

public enum AgentAdvisorToolDefaults {
    public static let identifier = AgentToolIdentifier(
        "advisor_ask"
    )

    public static let systemPrompt = """
    You are an advisor model inside an Agentic run.

    Give concise architectural advice.
    Do not ask for tools.
    Do not claim to have read files directly.
    Base your answer only on the context provided by the executor.
    Your output is advisory only and does not authorize actions.
    """
}
