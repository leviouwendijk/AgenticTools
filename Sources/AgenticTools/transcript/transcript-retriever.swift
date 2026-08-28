import Agentic
import Foundation
import Search

public struct TranscriptRetriever: Sendable {
    public let options: TranscriptRetrievalOptions

    public init(
        options: TranscriptRetrievalOptions = .default
    ) {
        self.options = options
    }

    public func retrieve(
        _ query: String,
        in events: [AgentTranscriptEvent]
    ) -> SearchResult<Int> {
        let corpus = SearchCorpus(
            documents: events.enumerated().map { index, event in
                let record = TranscriptToolSupport.record(
                    for: event,
                    index: index,
                    includeFullText: true
                )

                return SearchDocument(
                    id: index,
                    text: [
                        event.id,
                        record.summary,
                        record.text ?? "",
                    ]
                    .filter {
                        !$0.isEmpty
                    }
                    .joined(separator: "\n")
                )
            }
        )

        return TextSearch.search(
            query.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            in: corpus,
            options: options.search
        )
    }

    public func event(
        for hit: SearchHit<Int>,
        in events: [AgentTranscriptEvent]
    ) -> AgentTranscriptEvent? {
        guard events.indices.contains(
            hit.documentID
        ) else {
            return nil
        }

        return events[
            hit.documentID
        ]
    }
}
