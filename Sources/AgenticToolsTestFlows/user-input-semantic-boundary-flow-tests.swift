import Agentic
import AgenticTools
import TestFlows

extension AgenticToolsFlowTesting {
    static func runUserInputSemanticBoundary()
        throws -> [TestFlowDiagnostic]
    {
        let request = try UserInputRequest(
            prompt: "Choose a direction.",
            input: .single_choice(
                .init(
                    choices: [
                        .init(
                            id: "left",
                            label: "Left",
                            value: "left"
                        ),
                        .init(
                            id: "right",
                            label: "Right",
                            value: "right"
                        ),
                    ],
                    defaultChoiceID: "left"
                )
            )
        )

        let response = try UserInputResponse(
            answer: .single_choice(
                .choice(
                    " right "
                )
            ),
            for: request
        )

        try Expect.equal(
            response.outcome,
            .answered(
                .single_choice(
                    .choice(
                        "right"
                    )
                )
            ),
            "strong user-input response stores the refined answer"
        )

        let toolInput = ClarifyWithUserToolInput(
            prompt: "Choose a direction.",
            input: request.input
        )
        let toolRequest = try toolInput.request()

        try Expect.equal(
            toolRequest.input,
            request.input,
            "model-facing clarify input parses into the core semantic request"
        )

        var rejectedNegativeSelectionCount = false

        do {
            _ = try UserInputRequest(
                prompt: "Choose.",
                input: .multi_choice(
                    .init(
                        choices: [
                            .init(
                                id: "one",
                                label: "One",
                                value: "one"
                            ),
                        ],
                        minimumSelectionCount: -1
                    )
                )
            )
        } catch UserInputError.invalidSelectionBounds(_, _) {
            rejectedNegativeSelectionCount = true
        }

        try Expect.equal(
            rejectedNegativeSelectionCount,
            true,
            "negative selection counts are rejected instead of silently clamped"
        )

        var rejectedDuplicateChoiceID = false

        do {
            _ = try UserInputRequest(
                prompt: "Choose.",
                input: .single_choice(
                    .init(
                        choices: [
                            .init(
                                id: "same",
                                label: "First",
                                value: "first"
                            ),
                            .init(
                                id: "same",
                                label: "Second",
                                value: "second"
                            ),
                        ]
                    )
                )
            )
        } catch UserInputError.duplicateChoiceID(_) {
            rejectedDuplicateChoiceID = true
        }

        try Expect.equal(
            rejectedDuplicateChoiceID,
            true,
            "duplicate choice identifiers fail at request construction"
        )

        var rejectedUnknownAnswer = false

        do {
            _ = try UserInputResponse(
                answer: .single_choice(
                    .choice(
                        "missing"
                    )
                ),
                for: request
            )
        } catch UserInputError.unknownChoiceID(_) {
            rejectedUnknownAnswer = true
        }

        try Expect.equal(
            rejectedUnknownAnswer,
            true,
            "response construction rejects values outside the request semantics"
        )

        return [
            .field(
                "request_kind",
                "single_choice"
            ),
            .field(
                "refined_choice",
                "right"
            ),
            .field(
                "negative_bounds_rejected",
                String(rejectedNegativeSelectionCount)
            ),
            .field(
                "duplicate_ids_rejected",
                String(rejectedDuplicateChoiceID)
            ),
            .field(
                "unknown_answer_rejected",
                String(rejectedUnknownAnswer)
            ),
        ]
    }
}
