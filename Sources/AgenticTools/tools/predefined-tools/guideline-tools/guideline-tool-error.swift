import Foundation

public enum GuidelineToolError:
    Error,
    Sendable,
    LocalizedError
{
    case emptyQuery
    case invalidArea(String)
    case missingReference
    case unknownGuideline(String)
    case unknownChapter(String)

    public var errorDescription: String? {
        switch self {
        case .emptyQuery:
            "Tool 'find_guidelines' requires a non-empty query."

        case .invalidArea(let area):
            "Unknown guideline area '\(area)'."

        case .missingReference:
            "A non-empty guideline reference is required."

        case .unknownGuideline(let reference):
            "Unknown guideline reference '\(reference)'."

        case .unknownChapter(let reference):
            "Unknown guideline chapter reference '\(reference)'."
        }
    }
}
