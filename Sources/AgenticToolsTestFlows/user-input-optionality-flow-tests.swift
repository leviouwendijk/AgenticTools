import Agentic
import AgenticTools
import TestFlows

extension AgenticToolsFlowTesting {
    static func runUserInputOptionality()
        throws -> [TestFlowDiagnostic]
    {
        let required = try UserInputRequest(
            prompt: "Required."
        )

        try Expect.equal(
            required.requirement,
            .required,
            "user-input requests default to required"
        )

        var rejectedRequiredSkip = false

        do {
            _ = try UserInputResponse(
                .skip,
                for: required
            )
        } catch UserInputError.requiredInputCannotBeSkipped {
            rejectedRequiredSkip = true
        }

        try Expect.equal(
            rejectedRequiredSkip,
            true,
            "required user input cannot be skipped"
        )

        let optional = try ClarifyWithUserToolInput(
            prompt: "Optional.",
            requirement: .optional,
            input: .multi_choice(
                .init(
                    choices: [
                        .init(
                            id: "one",
                            label: "One",
                            value: "one"
                        ),
                    ]
                )
            )
        ).request()

        try Expect.equal(
            optional.requirement,
            .optional,
            "clarify_with_user preserves optional request semantics"
        )

        let skipped = try UserInputResponse(
            .skip,
            for: optional
        )

        try Expect.equal(
            skipped.outcome,
            .skipped,
            "optional user input supports explicit skip"
        )

        let answeredEmptySelection = try UserInputResponse(
            answer: .multi_choice(
                .init(
                    choiceIDs: []
                )
            ),
            for: optional
        )

        try Expect.equal(
            answeredEmptySelection.outcome,
            .answered(
                .multi_choice(
                    .init(
                        choiceIDs: []
                    )
                )
            ),
            "zero selections remains an answer rather than becoming skip"
        )

        let optionalText = try UserInputRequest(
            prompt: "Optional text.",
            requirement: .optional,
            input: .text(
                .init(
                    constraint: .init(
                        allowsEmpty: true
                    )
                )
            )
        )

        let answeredEmptyText = try UserInputResponse(
            answer: .text(
                ""
            ),
            for: optionalText
        )

        try Expect.equal(
            answeredEmptyText.outcome,
            .answered(
                .text(
                    ""
                )
            ),
            "answered empty text remains distinct from skip when allowed"
        )

        let form = try UserInputRequest(
            prompt: "Profile.",
            input: .form(
                .init(
                    fields: [
                        .init(
                            id: "required",
                            label: "Required"
                        ),
                        .init(
                            id: "optional",
                            label: "Optional",
                            requirement: .optional
                        ),
                    ]
                )
            )
        )

        var rejectedMissingRequiredField = false

        do {
            _ = try UserInputResponse(
                answer: .form(
                    .init(
                        values: [:]
                    )
                ),
                for: form
            )
        } catch UserInputError.missingRequiredField(let id)
            where id == "required"
        {
            rejectedMissingRequiredField = true
        }

        try Expect.equal(
            rejectedMissingRequiredField,
            true,
            "forms reject omitted required fields"
        )

        let formResponse = try UserInputResponse(
            answer: .form(
                .init(
                    values: [
                        "required": " value ",
                    ]
                )
            ),
            for: form
        )

        try Expect.equal(
            formResponse.outcome,
            .answered(
                .form(
                    .init(
                        values: [
                            "required": "value",
                        ]
                    )
                )
            ),
            "forms allow optional fields to be omitted without fabricating empty values"
        )

        return [
            .field(
                "required_skip_rejected",
                String(rejectedRequiredSkip)
            ),
            .field(
                "optional_skip",
                String(skipped.isSkipped)
            ),
            .field(
                "missing_required_field_rejected",
                String(rejectedMissingRequiredField)
            ),
        ]
    }
}
