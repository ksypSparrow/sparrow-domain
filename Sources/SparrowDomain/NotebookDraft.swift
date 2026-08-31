import Foundation

/// Everything needed to create a notebook.
///
/// - Note: There is no `sortIndex`. Where a new notebook lands among its
///   siblings depends on how many there already are, and a caller creating one
///   from a Shortcut has no way to know that. Storage assigns it.
public struct NotebookDraft: Hashable, Sendable, Codable {
    public var name: String
    public var parentID: NotebookID?
    public var colorName: String?

    public init(
        name: String,
        parentID: NotebookID? = nil,
        colorName: String? = nil
    ) {
        self.name = name
        self.parentID = parentID
        self.colorName = colorName
    }
}
