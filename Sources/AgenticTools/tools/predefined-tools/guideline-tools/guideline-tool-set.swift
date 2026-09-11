import AgenticExecution

public struct GuidelineToolSet: AgentToolSet {
    public init() {}

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            GuidelineIndexTool()
            FindGuidelinesTool()
            ReadGuidelineTool()
            ReadGuidelineChapterTool()
        }
    }
}
