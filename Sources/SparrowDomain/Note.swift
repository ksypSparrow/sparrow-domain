import Foundation

/// A single captured note.
public struct Note: Identifiable, Hashable, Sendable, Codable {
    public typealias ID = NoteID

    public let id: NoteID

    /// Rich text, not `String`.
    ///
    /// The `.notes.note` schema mandates formatting, and it is what preserves
    /// what the Shortcuts *Use Model* action produces. `RichText` carries the
    /// characters and the attributes separately so this type still compiles
    /// for the V2 server — see `RichText`.
    public var title: RichText
    public var body: RichText

    public var notebookID: NotebookID

    /// An array, not a set: the order a person added tags is the order they
    /// should see them. Uniqueness is the writer's job — the service dedupes
    /// before saving.
    public var tagIDs: [TagID]

    public var kind: NoteKind
    public var isPinned: Bool

    /// When the observation happened, which may precede `createdAt` by hours —
    /// a note written up in the evening about a bird seen at dawn.
    public var observedAt: Date?

    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: NoteID = NoteID(),
        title: RichText = .empty,
        body: RichText = .empty,
        notebookID: NotebookID,
        tagIDs: [TagID] = [],
        kind: NoteKind = .observation,
        isPinned: Bool = false,
        observedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.notebookID = notebookID
        self.tagIDs = tagIDs
        self.kind = kind
        self.isPinned = isPinned
        self.observedAt = observedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Note {
    var plainTitle: String { title.plain }
    var plainBody: String { body.plain }

    /// A note carrying no content in either field.
    var isEmpty: Bool { plainTitle.isEmpty && plainBody.isEmpty }

    /// When this note is *about*, which is what a timeline should order by.
    /// Falls back to creation for notes that never claimed a moment.
    var happenedAt: Date { observedAt ?? createdAt }
}
