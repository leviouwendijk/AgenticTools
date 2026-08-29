import Agentic
import Schema

extension AgentArtifactKind:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .string(cases: allCases.map(\.rawValue))
    }
}

extension AgentTaskIdentifier:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .string()
    }
}

extension AgentTaskStatus:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .string(cases: allCases.map(\.rawValue))
    }
}

extension TranscriptEventKind:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .string(cases: allCases.map(\.rawValue))
    }
}
