import AgenticExecution
import AgenticTools
import TestFlows

extension AgenticToolsFlowTesting {
    static func runGuidelineToolsProgressiveDisclosure()
        async throws -> [TestFlowDiagnostic]
    {
        let index =
            try await GuidelineIndexTool()
                .call(
                    .init(),
                    context: .init()
                )

        try Expect.equal(
            index.chapters.isEmpty,
            false,
            "guideline index returns chapters"
        )

        let chapter =
            index.chapters[0]

        try Expect.equal(
            chapter.guidelines.isEmpty,
            false,
            "guideline index returns body-free guideline references and titles"
        )

        let indexedGuideline =
            chapter.guidelines[0]

        let search =
            try await FindGuidelinesTool()
                .call(
                    .init(
                        query:
                            indexedGuideline.reference,
                        maximumResults: 1
                    ),
                    context: .init()
                )

        try Expect.equal(
            search.matches.first?.reference,
            Optional(
                indexedGuideline.reference
            ),
            "exact guideline reference ranks first"
        )

        let detail =
            try await ReadGuidelineTool()
                .call(
                    .init(
                        reference:
                            indexedGuideline.reference
                    ),
                    context: .init()
                )

        try Expect.equal(
            detail.reference,
            indexedGuideline.reference,
            "full guideline read preserves exact reference"
        )

        try Expect.equal(
            detail.explanation.isEmpty,
            false,
            "full guideline read materializes explanation content"
        )

        let chapterDetail =
            try await ReadGuidelineChapterTool()
                .call(
                    .init(
                        reference:
                            chapter.reference
                    ),
                    context: .init()
                )

        try Expect.equal(
            chapterDetail.guidelineCount,
            chapter.guidelineCount,
            "chapter read returns the full summary-level guideline set"
        )

        return [
            .field(
                "chapter",
                chapter.reference
            ),
            .field(
                "guideline",
                indexedGuideline.reference
            ),
            .field(
                "search-count",
                String(
                    search.count
                )
            ),
        ]
    }

    static func runGuidelineToolsSearchBounds()
        async throws -> [TestFlowDiagnostic]
    {
        let defaultInput =
            FindGuidelinesToolInput(
                query: "execution"
            )

        let oversizedInput =
            FindGuidelinesToolInput(
                query: "execution",
                maximumResults: 999
            )

        let undersizedInput =
            FindGuidelinesToolInput(
                query: "execution",
                maximumResults: 0
            )

        try Expect.equal(
            defaultInput.resultLimit,
            5,
            "guideline search defaults to five results"
        )

        try Expect.equal(
            oversizedInput.resultLimit,
            8,
            "guideline search caps results at eight"
        )

        try Expect.equal(
            undersizedInput.resultLimit,
            1,
            "guideline search keeps a positive lower bound"
        )

        let structure =
            try await GuidelineIndexTool()
                .call(
                    .init(
                        area: "structure"
                    ),
                    context: .init()
                )

        try Expect.equal(
            structure.chapters.allSatisfy {
                $0.area == "structure"
            },
            true,
            "guideline index area filter is exact"
        )

        return [
            .field(
                "default-limit",
                String(
                    defaultInput.resultLimit
                )
            ),
            .field(
                "maximum-limit",
                String(
                    oversizedInput.resultLimit
                )
            ),
            .field(
                "structure-chapters",
                String(
                    structure.chapterCount
                )
            ),
        ]
    }
}
