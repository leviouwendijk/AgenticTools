import Guidelines

public struct GuidelineToolSummary:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let area: String
    public let chapterReference: String
    public let chapterTitle: String
    public let title: String
    public let summary: String

    public init(
        reference: String,
        area: String,
        chapterReference: String,
        chapterTitle: String,
        title: String,
        summary: String
    ) {
        self.reference = reference
        self.area = area
        self.chapterReference = chapterReference
        self.chapterTitle = chapterTitle
        self.title = title
        self.summary = summary
    }

    init(
        guideline: Guideline,
        chapter: GuidelineChapter
    ) {
        self.init(
            reference: guideline.reference,
            area: guideline.area.rawValue,
            chapterReference: chapter.reference,
            chapterTitle: chapter.title,
            title: guideline.title,
            summary: guideline.summary
        )
    }
}
