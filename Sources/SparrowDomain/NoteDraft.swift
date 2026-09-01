import Foundation

/// Everything needed to create a note.
///
/// Writes are described, not mutated: there is no way to construct a
/// half-formed `Note` and save it later. Identity and timestamps are supplied
/// by the layer that performs the write.
public struct NoteDraft: Hashable, Sendable, Codable {
    public var title: RichText
    public var body: RichText

    /// `nil` means *the default notebook*. FR-1.1 lets a note be captured
    /// without naming one, and storage always has somewhere to put it.
    public var notebookID: NotebookID?

    public var kind: NoteKind
    public var observedAt: Date?

    public init(
        title: RichText = .empty,
        body: RichText = .empty,
        notebookID: NotebookID? = nil,
        kind: NoteKind = .observation,
        observedAt: Date? = nil
    ) {
        self.title = title
        self.body = body
        self.notebookID = notebookID
        self.kind = kind
        self.observedAt = observedAt
    }
}

public extension NoteDraft {
    var isEmpty: Bool { title.isEmpty && body.isEmpty }
}
