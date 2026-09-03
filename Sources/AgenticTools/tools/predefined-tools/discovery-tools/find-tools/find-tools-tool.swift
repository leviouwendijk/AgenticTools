import Agentic
import AgenticExecution
import AgenticWorkspace
import Foundation
import Primitives
import Search

public struct FindToolsTool:
    TypedInstanceAgentTool
{
    public typealias Input = FindToolsToolInput

    public static let identifier: AgentToolIdentifier = "find_tools"
    public static let description = "Search the installed Agentic tool catalog by exact identifier or natural-language capability. Returned matches are exposed as native tools on subsequent model turns."
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

    public let registry: ToolRegistry
    public let exposure: AgentToolExposure

    public init(
        registry: ToolRegistry,
        exposure: AgentToolExposure
    ) {
        self.registry = registry
        self.exposure = exposure
    }

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            FindToolsToolInput.self,
            from: input
        )
        let query = try normalizedQuery(
            decoded.query
        )

        return ToolPreflight(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            summary: "Find and activate up to \(decoded.resultLimit) installed tool(s) matching '\(query)'.",
            sideEffects: [
                "updates model-visible tool exposure for subsequent turns",
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace _: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            FindToolsToolInput.self,
            from: input
        )
        let query = try normalizedQuery(
            decoded.query
        )
        let definitions = registry
            .modelFacingDefinitions
            .filter {
                $0.identifier != Self.identifier
            }

        let exact = exactDefinition(
            for: query,
            in: definitions
        )
        let ranked = rankedDefinitions(
            for: query,
            in: definitions
        )

        var selected = [AgentToolDefinition]()

        if let exact {
            selected.append(
                exact
            )
        }

        for definition in ranked
        where definition.identifier != exact?.identifier {
            guard selected.count < decoded.resultLimit else {
                break
            }

            selected.append(
                definition
            )
        }

        if selected.count > decoded.resultLimit {
            selected = Array(
                selected.prefix(
                    decoded.resultLimit
                )
            )
        }

        let tools = selected.map { definition in
            FoundAgentTool(
                identifier: definition.identifier,
                description: definition.description,
                risk: definition.risk
            )
        }

        let activated = try await exposure.activate(
            tools.map(\.identifier),
            in: registry
        )

        return try JSONToolBridge.encode(
            FindToolsToolOutput(
                query: query,
                tools: tools,
                activated: activated
            )
        )
    }
}

private extension FindToolsTool {
    struct SearchScore {
        var identifierScore = 0
        var descriptionScore = 0
        var matchedProbeIDs = Set<String>()

        var total: Int {
            identifierScore * 3
                + descriptionScore * 2
                + matchedProbeIDs.count * 100
        }
    }

    func exactDefinition(
        for query: String,
        in definitions: [AgentToolDefinition]
    ) -> AgentToolDefinition? {
        definitions.first { definition in
            definition.identifier.rawValue.compare(
                query,
                options: [
                    .caseInsensitive,
                ]
            ) == .orderedSame
        }
    }

    func rankedDefinitions(
        for query: String,
        in definitions: [AgentToolDefinition]
    ) -> [AgentToolDefinition] {
        let probes = searchProbes(
            for: query
        )

        guard !probes.isEmpty else {
            return []
        }

        let identifierCorpus = SearchCorpus(
            documents: definitions.map { definition in
                SearchDocument(
                    id: definition.identifier,
                    text: definition.identifier.rawValue
                )
            }
        )
        let descriptionCorpus = SearchCorpus(
            documents: definitions.map { definition in
                SearchDocument(
                    id: definition.identifier,
                    text: definition.description
                )
            }
        )
        let options = SearchOptions(
            mode: .ranked,
            strategy: .fuzzy,
            caseSensitive: false,
            minimumScore: 1,
            maximumResults: nil
        )
        let identifierResult = TextSearch.search(
            probes: probes,
            in: identifierCorpus,
            options: options
        )
        let descriptionResult = TextSearch.search(
            probes: probes,
            in: descriptionCorpus,
            options: options
        )

        var scores = [AgentToolIdentifier: SearchScore]()

        accumulate(
            identifierResult,
            field: .identifier,
            into: &scores
        )
        accumulate(
            descriptionResult,
            field: .description,
            into: &scores
        )

        return definitions
            .filter { definition in
                scores[definition.identifier] != nil
            }
            .sorted { lhs, rhs in
                let lhsScore = scores[lhs.identifier] ?? SearchScore()
                let rhsScore = scores[rhs.identifier] ?? SearchScore()

                if lhsScore.total != rhsScore.total {
                    return lhsScore.total > rhsScore.total
                }

                if lhsScore.matchedProbeIDs.count
                    != rhsScore.matchedProbeIDs.count {
                    return lhsScore.matchedProbeIDs.count
                        > rhsScore.matchedProbeIDs.count
                }

                if lhsScore.identifierScore
                    != rhsScore.identifierScore {
                    return lhsScore.identifierScore
                        > rhsScore.identifierScore
                }

                if lhsScore.descriptionScore
                    != rhsScore.descriptionScore {
                    return lhsScore.descriptionScore
                        > rhsScore.descriptionScore
                }

                return lhs.identifier.rawValue
                    < rhs.identifier.rawValue
            }
    }

    enum SearchField {
        case identifier
        case description
    }

    func accumulate(
        _ result: SearchResult<AgentToolIdentifier>,
        field: SearchField,
        into scores: inout [AgentToolIdentifier: SearchScore]
    ) {
        for hit in result.hits {
            var score = scores[hit.documentID]
                ?? SearchScore()

            switch field {
            case .identifier:
                score.identifierScore += hit.score.value

            case .description:
                score.descriptionScore += hit.score.value
            }

            score.matchedProbeIDs.formUnion(
                hit.evidence.compactMap(\.queryID)
            )

            scores[hit.documentID] = score
        }
    }

    func searchProbes(
        for query: String
    ) -> [SearchProbe] {
        let terms = capabilityTerms(
            in: query
        )

        guard !terms.isEmpty else {
            return []
        }

        var probes = [
            SearchProbe(
                query,
                id: "query",
                weight: 3,
                role: .preferred,
                strategy: .fuzzy
            ),
        ]

        for term in terms {
            probes.append(
                SearchProbe(
                    term,
                    id: "term:\(term)",
                    weight: 1,
                    role: .preferred,
                    strategy: .fuzzy
                )
            )
        }

        return probes
    }

    func capabilityTerms(
        in value: String
    ) -> [String] {
        let ignoredTerms: Set<String> = [
            "and",
            "can",
            "could",
            "find",
            "help",
            "need",
            "please",
            "that",
            "the",
            "this",
            "tool",
            "tools",
            "use",
            "want",
            "with",
            "you",
        ]
        var seen = Set<String>()

        return normalizedTerms(
            in: value
        ).filter { term in
            guard term.count >= 3,
                  !ignoredTerms.contains(term),
                  !seen.contains(term)
            else {
                return false
            }

            seen.insert(
                term
            )
            return true
        }
    }

    func normalizedTerms(
        in value: String
    ) -> [String] {
        value
            .lowercased()
            .split { character in
                !character.isLetter
                    && !character.isNumber
            }
            .map(String.init)
            .map { term in
                if term.count > 4,
                   term.hasSuffix("ies") {
                    return String(
                        term.dropLast(3)
                    ) + "y"
                }

                return term
            }
    }

    func normalizedQuery(
        _ query: String
    ) throws -> String {
        let query = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            throw FindToolsToolError.emptyQuery
        }

        return query
    }
}
