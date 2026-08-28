import Agentic
import Foundation

enum TranscriptToolSupport {
    static func record(
        for event: AgentTranscriptEvent,
        index: Int,
        includeFullText: Bool
    ) -> TranscriptEventRecord {
        .init(
            index: index,
            id: event.id,
            kind: kind(
                of: event
            ),
            summary: summary(
                for: event
            ),
            text: includeFullText
                ? fullText(for: event)
                : nil,
            messageRole: messageRole(
                for: event
            ),
            toolName: toolName(
                for: event
            ),
            isError: isError(
                for: event
            )
        )
    }

    static func kind(
        of event: AgentTranscriptEvent
    ) -> TranscriptEventKind {
        switch event {
        case .message:
            return .message

        case .tool_call:
            return .tool_call

        case .tool_result:
            return .tool_result

        case .session_branch:
            return .session_branch

        case .note:
            return .note
        }
    }

    static func matchesKinds(
        _ event: AgentTranscriptEvent,
        allowedKinds: [TranscriptEventKind]
    ) -> Bool {
        guard !allowedKinds.isEmpty else {
            return true
        }

        return allowedKinds.contains(
            kind(
                of: event
            )
        )
    }

    static func summary(
        for event: AgentTranscriptEvent,
        maxLength: Int = 240
    ) -> String {
        truncate(
            event.summaryText.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            maxLength: maxLength
        )
    }

    static func fullText(
        for event: AgentTranscriptEvent
    ) -> String {
        switch event {
        case .message(let message):
            return message.content.text

        case .tool_call(let call):
            return [
                "tool_call",
                "id=\(call.id)",
                "name=\(call.name)",
                "input=\(call.input)"
            ].joined(separator: "\n")

        case .tool_result(let result):
            return [
                "tool_result",
                "toolCallID=\(result.toolCallID)",
                "name=\(result.name ?? "")",
                "isError=\(result.isError)",
                "output=\(result.output)"
            ].joined(separator: "\n")

        case .session_branch(let event):
            return event.summaryText

        case .note(_, let text):
            return text
        }
    }

    static func messageRole(
        for event: AgentTranscriptEvent
    ) -> AgentRole? {
        guard case .message(let message) = event else {
            return nil
        }

        return message.role
    }

    static func toolName(
        for event: AgentTranscriptEvent
    ) -> String? {
        switch event {
        case .tool_call(let call):
            return call.name

        case .tool_result(let result):
            return result.name

        case .message,
             .session_branch,
             .note:
            return nil
        }
    }

    static func isError(
        for event: AgentTranscriptEvent
    ) -> Bool? {
        guard case .tool_result(let result) = event else {
            return nil
        }

        return result.isError
    }

    static func truncate(
        _ value: String,
        maxLength: Int
    ) -> String {
        let clamped = max(
            16,
            maxLength
        )

        guard value.count > clamped else {
            return value
        }

        let index = value.index(
            value.startIndex,
            offsetBy: clamped
        )

        return "\(value[..<index])…"
    }

    static func selectedEvents(
        from events: [AgentTranscriptEvent],
        startIndex: Int?,
        limit: Int?,
        allowedKinds: [TranscriptEventKind],
        latestFirst: Bool
    ) -> [(index: Int, event: AgentTranscriptEvent)] {
        let clampedLimit = max(
            1,
            min(
                limit ?? 40,
                500
            )
        )

        let filtered = events.enumerated().filter { index, event in
            if let startIndex,
               index < startIndex {
                return false
            }

            return matchesKinds(
                event,
                allowedKinds: allowedKinds
            )
        }

        let selected: [(offset: Int, element: AgentTranscriptEvent)]
        if latestFirst {
            selected = Array(
                filtered.reversed().prefix(
                    clampedLimit
                )
            )
        } else {
            selected = Array(
                filtered.prefix(
                    clampedLimit
                )
            )
        }

        return selected.map { item in
            (
                index: item.offset,
                event: item.element
            )
        }
    }

    static func containsQuery(
        _ event: AgentTranscriptEvent,
        query: String,
        caseSensitive: Bool
    ) -> Bool {
        let haystack = fullText(
            for: event
        )
        let needle = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !needle.isEmpty else {
            return false
        }

        if caseSensitive {
            return haystack.contains(
                needle
            )
        }

        return haystack.localizedCaseInsensitiveContains(
            needle
        )
    }

    static func score(
        _ event: AgentTranscriptEvent,
        query: String,
        caseSensitive: Bool
    ) -> Int {
        let rawHaystack = fullText(
            for: event
        )
        let rawSummary = event.summaryText
        let rawQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !rawQuery.isEmpty else {
            return 0
        }

        let haystack = caseSensitive
            ? rawHaystack
            : rawHaystack.lowercased()
        let summary = caseSensitive
            ? rawSummary
            : rawSummary.lowercased()
        let normalizedQuery = caseSensitive
            ? rawQuery
            : rawQuery.lowercased()

        var score = 0

        if summary.contains(normalizedQuery) {
            score += 20
        }

        if haystack.contains(normalizedQuery) {
            score += 10
        }

        let terms = normalizedQuery
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        for term in terms {
            if summary.contains(term) {
                score += 4
            }

            if haystack.contains(term) {
                score += 2
            }
        }

        return score
    }

    static func summarize(
        events indexedEvents: [(index: Int, event: AgentTranscriptEvent)],
        totalEventCount: Int,
        maxExcerptCharacters: Int
    ) -> TranscriptWindowSummary {
        var countsByKind: [String: Int] = [:]
        var countsByRole: [String: Int] = [:]
        var countsByToolName: [String: Int] = [:]
        var approximateCharacterCount = 0
        var excerpts: [String] = []

        for indexedEvent in indexedEvents {
            let event = indexedEvent.event
            let kind = kind(
                of: event
            ).rawValue
            countsByKind[kind, default: 0] += 1

            if let role = messageRole(
                for: event
            ) {
                countsByRole[role.rawValue, default: 0] += 1
            }

            if let toolName = toolName(
                for: event
            ) {
                countsByToolName[toolName, default: 0] += 1
            }

            approximateCharacterCount += fullText(
                for: event
            ).count

            excerpts.append(
                "\(indexedEvent.index): \(kind): \(summary(for: event, maxLength: maxExcerptCharacters))"
            )
        }

        let firstIndex = indexedEvents.map(\.index).min()
        let lastIndex = indexedEvents.map(\.index).max()

        let summary = [
            "Selected \(indexedEvents.count) of \(totalEventCount) transcript event(s).",
            firstIndex.map { "First index: \($0)." },
            lastIndex.map { "Last index: \($0)." }
        ].compactMap { $0 }.joined(separator: " ")

        return .init(
            totalEventCount: totalEventCount,
            selectedEventCount: indexedEvents.count,
            firstIndex: firstIndex,
            lastIndex: lastIndex,
            countsByKind: countsByKind,
            countsByRole: countsByRole,
            countsByToolName: countsByToolName,
            approximateCharacterCount: approximateCharacterCount,
            excerpts: excerpts,
            summary: summary
        )
    }
}
