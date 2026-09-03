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
/// ⚠️ **Deliberately not `Codable`.** The doubly-optional fields do not
/// survive JSON: `.some(nil)` encodes as `null` and decodes back as `nil`, so
/// "clear this field" would silently become "leave it alone". 🧪 Verified on
/// Swift 6.4.
///
/// Nothing needs to encode an edit — the journal carries the *resulting*
/// entity, not the instruction that produced it — so the conformance is
/// omitted rather than papered over with a custom coder.
public struct NoteEdit: Hashable, Sendable {
    public var title: RichText?
    public var body: RichText?
    public var notebookID: NotebookID?

    /// The whole set, replaced. There is no "add one tag" here — an edit
    /// describes the state it wants, and a caller that means "add" reads the
    /// current tags first. Merging inside `applying` would make the same edit
    /// produce different results depending on what it was applied to.
    public var tagIDs: [TagID]?

    public var kind: NoteKind?
    public var isPinned: Bool?
    public var observedAt: Date??

    public init(
        title: RichText? = nil,
        body: RichText? = nil,
        notebookID: NotebookID? = nil,
        tagIDs: [TagID]? = nil,
        kind: NoteKind? = nil,
        isPinned: Bool? = nil,
        observedAt: Date?? = nil
    ) {
        self.title = title
        self.body = body
        self.notebookID = notebookID
        self.tagIDs = tagIDs
        self.kind = kind
        self.isPinned = isPinned
        self.observedAt = observedAt
    }
}

public extension NoteEdit {
    /// An edit that names no fields at all.
    var isEmpty: Bool {
        title == nil && body == nil && notebookID == nil && tagIDs == nil
            && kind == nil && isPinned == nil && observedAt == nil
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
        if let tagIDs = edit.tagIDs { updated.tagIDs = tagIDs }
        if let kind = edit.kind { updated.kind = kind }
        if let isPinned = edit.isPinned { updated.isPinned = isPinned }
        if let observedAt = edit.observedAt { updated.observedAt = observedAt }
        updated.updatedAt = date
        return updated
    }
}
