import Foundation

/// A partial change to a note. Every field is optional, and `nil` means
/// *leave this alone*.
///
/// ⚠️ **`observedAt` is doubly optional**, for the reason `NotebookEdit`'s
/// `parentID` is:
///
/// ```
///    observedAt = nil          leave the moment alone
///    observedAt = .some(nil)   clear it — this note is not about a moment
///    observedAt = .some(date)  set it
/// ```
public struct NoteEdit: Hashable, Sendable {
    public var title: RichText?
    public var body: RichText?
    public var notebookID: NotebookID?
    public var kind: NoteKind?
    public var isPinned: Bool?
    public var observedAt: Date??

    public init(
        title: RichText? = nil,
        body: RichText? = nil,
        notebookID: NotebookID? = nil,
        kind: NoteKind? = nil,
        isPinned: Bool? = nil,
        observedAt: Date?? = nil
    ) {
        self.title = title
        self.body = body
        self.notebookID = notebookID
        self.kind = kind
        self.isPinned = isPinned
        self.observedAt = observedAt
    }
}

public extension NoteEdit {
    /// An edit that names no fields at all.
    var isEmpty: Bool {
        title == nil && body == nil && notebookID == nil && kind == nil
            && isPinned == nil && observedAt == nil
    }
}

public extension Note {
    /// Returns a copy with `edit` applied.
    ///
    /// An edit that names no fields returns the note **completely** unchanged,
    /// `updatedAt` included. A bumped timestamp on an empty save would look
    /// like a real change to the sync journal, and V2 would ship a row across
    /// the network to say nothing happened.
    func applying(_ edit: NoteEdit, at date: Date) -> Note {
        guard !edit.isEmpty else { return self }

        var updated = self
        if let title = edit.title { updated.title = title }
        if let body = edit.body { updated.body = body }
        if let notebookID = edit.notebookID { updated.notebookID = notebookID }
        if let kind = edit.kind { updated.kind = kind }
        if let isPinned = edit.isPinned { updated.isPinned = isPinned }
        if let observedAt = edit.observedAt { updated.observedAt = observedAt }
        updated.updatedAt = date
        return updated
    }
}
