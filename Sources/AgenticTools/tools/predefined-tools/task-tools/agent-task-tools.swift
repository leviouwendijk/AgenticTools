import Agentic
import AgenticExecution
import AgenticWorkspace
import Primitives
import Schema

/// Create a new agent task.
@JSONSchema
public struct CreateAgentTaskToolInput: Sendable, Codable, Hashable {
    public let subject: String
    public let description: String
    public let blockedBy: [AgentTaskIdentifier]
    public let owner: String?
    public let sessionID: String?
    public let metadata: [String: String]

    public init(
        subject: String,
        description: String = "",
        blockedBy: [AgentTaskIdentifier] = [],
        owner: String? = nil,
        sessionID: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.subject = subject
        self.description = description
        self.blockedBy = blockedBy
        self.owner = owner
        self.sessionID = sessionID
        self.metadata = metadata
    }
}

/// Update mutable fields on an existing agent task.
@JSONSchema
public struct UpdateAgentTaskToolInput: Sendable, Codable, Hashable {
    public let id: AgentTaskIdentifier
    public let subject: String?
    public let description: String?
    public let status: AgentTaskStatus?
    public let owner: String?
    public let addBlockedBy: [AgentTaskIdentifier]
    public let removeBlockedBy: [AgentTaskIdentifier]
    public let sessionID: String?
    public let metadataPatch: [String: String]

    public init(
        id: AgentTaskIdentifier,
        subject: String? = nil,
        description: String? = nil,
        status: AgentTaskStatus? = nil,
        owner: String? = nil,
        addBlockedBy: [AgentTaskIdentifier] = [],
        removeBlockedBy: [AgentTaskIdentifier] = [],
        sessionID: String? = nil,
        metadataPatch: [String: String] = [:]
    ) {
        self.id = id
        self.subject = subject
        self.description = description
        self.status = status
        self.owner = owner
        self.addBlockedBy = addBlockedBy
        self.removeBlockedBy = removeBlockedBy
        self.sessionID = sessionID
        self.metadataPatch = metadataPatch
    }
}

/// List agent tasks with optional status, owner, readiness, and completion filters.
@JSONSchema
public struct ListAgentTasksToolInput: Sendable, Codable, Hashable {
    public let statuses: [AgentTaskStatus]
    public let owner: String?
    public let readyOnly: Bool
    public let includeCompleted: Bool

    public init(
        statuses: [AgentTaskStatus] = [],
        owner: String? = nil,
        readyOnly: Bool = false,
        includeCompleted: Bool = true
    ) {
        self.statuses = statuses
        self.owner = owner
        self.readyOnly = readyOnly
        self.includeCompleted = includeCompleted
    }
}

/// Read one agent task by identifier.
@JSONSchema
public struct GetAgentTaskToolInput: Sendable, Codable, Hashable {
    public let id: AgentTaskIdentifier

    public init(
        id: AgentTaskIdentifier
    ) {
        self.id = id
    }
}

/// Claim an agent task for an owner.
@JSONSchema
public struct ClaimAgentTaskToolInput: Sendable, Codable, Hashable {
    public let id: AgentTaskIdentifier
    public let owner: String

    public init(
        id: AgentTaskIdentifier,
        owner: String
    ) {
        self.id = id
        self.owner = owner
    }
}

/// Mark an agent task complete.
@JSONSchema
public struct CompleteAgentTaskToolInput: Sendable, Codable, Hashable {
    public let id: AgentTaskIdentifier

    public init(
        id: AgentTaskIdentifier
    ) {
        self.id = id
    }
}

public struct AgentTaskToolOutput: Sendable, Codable, Hashable {
    public let task: AgentTask

    public init(
        task: AgentTask
    ) {
        self.task = task
    }
}

public struct AgentTaskListToolOutput: Sendable, Codable, Hashable {
    public let tasks: [AgentTask]
    public let count: Int

    public init(
        tasks: [AgentTask]
    ) {
        self.tasks = tasks
        self.count = tasks.count
    }
}

public struct CreateAgentTaskTool: TypedInstanceAgentTool {
    public typealias Input = CreateAgentTaskToolInput

    public static let identifier: AgentToolIdentifier = "task_create"
    public static let description = "Create a durable Agentic task."
    public static let risk: ActionRisk = .boundedmutate

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            CreateAgentTaskToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Create durable task: \(decoded.subject)",
            estimatedWriteCount: 1,
            sideEffects: [
                "writes task file"
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            CreateAgentTaskToolInput.self,
            from: input
        )

        let task = try await manager.create(
            subject: decoded.subject,
            description: decoded.description,
            blockedBy: decoded.blockedBy,
            owner: decoded.owner,
            sessionID: decoded.sessionID,
            metadata: decoded.metadata
        )

        return try JSONToolBridge.encode(
            AgentTaskToolOutput(
                task: task
            )
        )
    }
}

public struct UpdateAgentTaskTool: TypedInstanceAgentTool {
    public typealias Input = UpdateAgentTaskToolInput

    public static let identifier: AgentToolIdentifier = "task_update"
    public static let description = "Update a durable Agentic task."
    public static let risk: ActionRisk = .boundedmutate

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            UpdateAgentTaskToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Update durable task \(decoded.id.rawValue).",
            estimatedWriteCount: decoded.status == .completed ? 2 : 1,
            sideEffects: [
                "writes task file",
                "may clear dependency from blocked tasks"
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            UpdateAgentTaskToolInput.self,
            from: input
        )

        let task = try await manager.update(
            id: decoded.id,
            subject: decoded.subject,
            description: decoded.description,
            status: decoded.status,
            owner: decoded.owner,
            addBlockedBy: decoded.addBlockedBy,
            removeBlockedBy: decoded.removeBlockedBy,
            sessionID: decoded.sessionID,
            metadataPatch: decoded.metadataPatch
        )

        return try JSONToolBridge.encode(
            AgentTaskToolOutput(
                task: task
            )
        )
    }
}

public struct ListAgentTasksTool: TypedInstanceAgentTool {
    public typealias Input = ListAgentTasksToolInput

    public static let identifier: AgentToolIdentifier = "task_list"
    public static let description = "List durable Agentic tasks."
    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func preflight(
        input _: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "List durable tasks.",
            sideEffects: []
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            ListAgentTasksToolInput.self,
            from: input
        )

        let tasks = try await manager.list(
            statuses: decoded.statuses,
            owner: decoded.owner,
            readyOnly: decoded.readyOnly,
            includeCompleted: decoded.includeCompleted
        )

        return try JSONToolBridge.encode(
            AgentTaskListToolOutput(
                tasks: tasks
            )
        )
    }
}

public struct GetAgentTaskTool: TypedInstanceAgentTool {
    public typealias Input = GetAgentTaskToolInput

    public static let identifier: AgentToolIdentifier = "task_get"
    public static let description = "Read a durable Agentic task."
    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            GetAgentTaskToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Read durable task \(decoded.id.rawValue).",
            sideEffects: []
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            GetAgentTaskToolInput.self,
            from: input
        )

        let task = try await manager.get(
            decoded.id
        )

        return try JSONToolBridge.encode(
            AgentTaskToolOutput(
                task: task
            )
        )
    }
}

public struct ClaimAgentTaskTool: TypedInstanceAgentTool {
    public typealias Input = ClaimAgentTaskToolInput

    public static let identifier: AgentToolIdentifier = "task_claim"
    public static let description = "Claim a durable Agentic task for an owner."
    public static let risk: ActionRisk = .boundedmutate

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ClaimAgentTaskToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Claim task \(decoded.id.rawValue) for \(decoded.owner).",
            estimatedWriteCount: 1,
            sideEffects: [
                "writes task file"
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            ClaimAgentTaskToolInput.self,
            from: input
        )

        let task = try await manager.claim(
            id: decoded.id,
            owner: decoded.owner
        )

        return try JSONToolBridge.encode(
            AgentTaskToolOutput(
                task: task
            )
        )
    }
}

public struct CompleteAgentTaskTool: TypedInstanceAgentTool {
    public typealias Input = CompleteAgentTaskToolInput

    public static let identifier: AgentToolIdentifier = "task_complete"
    public static let description = "Complete a durable Agentic task and unblock dependents."
    public static let risk: ActionRisk = .boundedmutate

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public let manager: AgentTaskManager

    public init(
        manager: AgentTaskManager
    ) {
        self.manager = manager
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            CompleteAgentTaskToolInput.self,
            from: input
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Complete task \(decoded.id.rawValue) and clear dependency edges.",
            estimatedWriteCount: 2,
            sideEffects: [
                "writes task file",
                "may unblock dependent tasks"
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        _ = workspace

        let decoded = try JSONToolBridge.decode(
            CompleteAgentTaskToolInput.self,
            from: input
        )

        let task = try await manager.complete(
            id: decoded.id
        )

        return try JSONToolBridge.encode(
            AgentTaskToolOutput(
                task: task
            )
        )
    }
}
