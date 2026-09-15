import Agentic
import AgenticExecution
import AgenticWorkspace
import Macros
import Primitives
import Schema

@JSONSchema
public struct ClarifyWithUserToolInput: Sendable, Codable, Hashable {
    public let prompt: String
    public let reason: String?
    public let requirement: UserInputRequirement?
    public let input: UserInputSpec
    public let presentation: UserInputPresentation?
    public let metadata: [String: String]

    public init(
        prompt: String,
        reason: String? = nil,
        requirement: UserInputRequirement? = nil,
        input: UserInputSpec = .text(
            .init()
        ),
        presentation: UserInputPresentation? = nil,
        metadata: [String: String] = [:]
    ) {
        self.prompt = prompt
        self.reason = reason
        self.requirement = requirement
        self.input = input
        self.presentation = presentation
        self.metadata = metadata
    }

    public func request() throws -> UserInputRequest {
        try UserInputRequest(
            .init(
                prompt: prompt,
                reason: reason,
                requirement: requirement,
                input: input,
                presentation: presentation,
                metadata: metadata
            )
        )
    }
}

public struct ClarifyWithUserToolOutput: Sendable, Codable, Hashable {
    public let kind: String
    public let request: UserInputRequest

    public init(
        kind: String = "pending_user_input",
        request: UserInputRequest
    ) {
        self.kind = kind
        self.request = request
    }
}

public struct ClarifyWithUserTool: AgentTool {
    public typealias Input = ClarifyWithUserToolInput
    public typealias Output = ClarifyWithUserToolOutput

    public static let identifier: AgentToolIdentifier = "clarify_with_user"
    public static let description = "Suspend the current agent run and ask the user for missing information needed to continue."
    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier { Self.identifier }
    public var description: String { Self.description }
    public var risk: ActionRisk { Self.risk }

    public init() {}

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        let request = try input.request()

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: context.workspace?.rootURL.path,
            targetPaths: [],
            summary: request.prompt,
            estimatedWriteCount: 0,
            estimatedByteCount: 0,
            sideEffects: [
                "suspends the current agent run",
                "waits for typed user input before continuing",
            ]
        )
    }

    public func call(
        _ input: Input,
        context _: AgentToolExecutionContext
    ) async throws -> Output {
        .init(
            request: try input.request()
        )
    }
}
