import Foundation

/// What to look for. The type that keeps SQL out of the service layer.
///
/// ⚠️ **Expressible as data, always.** Every field is a value a Shortcut could
/// have filled in. If a case ever needs a closure it belongs in storage
/// instead — a filter carrying behaviour cannot be compiled into a query,
/// logged, or sent to the V2 server.
public struct NoteFilter: Hashable, Sendable, Codable {
    /// Free text. Matched by the **search index**, never by `matchesFields`.
    public var text: String?
    public var notebookID: NotebookID?
    /// Empty means *any kind*, not *no kinds*.
    public var kinds: Set<NoteKind>

    /// Empty means *any tags*. A non-empty set requires the note to carry
    /// **all** of them — "tagged wetlands and survey" is the useful question,
    /// and "either" is expressible as two searches.
    public var tagIDs: Set<TagID>
    public var createdWithin: DateInterval?
    public var updatedWithin: DateInterval?
    public var isPinned: Bool?

    public init(
        text: String? = nil,
        notebookID: NotebookID? = nil,
        kinds: Set<NoteKind> = [],
        tagIDs: Set<TagID> = [],
        createdWithin: DateInterval? = nil,
        updatedWithin: DateInterval? = nil,
        isPinned: Bool? = nil
    ) {
        self.text = text
        self.notebookID = notebookID
        self.kinds = kinds
        self.tagIDs = tagIDs
        self.createdWithin = createdWithin
        self.updatedWithin = updatedWithin
        self.isPinned = isPinned
    }

    /// The empty filter: everything matches.
    public static var all: NoteFilter { NoteFilter() }
}

public extension NoteFilter {
    /// True when this filter constrains nothing.
    var isEmpty: Bool { self == .all }

    /// Whether answering this filter needs the search index.
    ///
    /// Storage uses it to decide whether to consult FTS at all — a filter with
    /// no text is a plain query over the note table.
    var requiresTextSearch: Bool {
        guard let text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether `note` satisfies every field **except `text`**.
    ///
    /// ⚠️ **Deliberately not named `matches`.** Free text is matched by the
    /// search index, whose tokenisation and diacritic folding this cannot
    /// reproduce — and should not try to. A second, subtly different text
    /// matcher is exactly the bug that made the in-memory store disagree with
    /// SQLite about `"Herón"`.
    ///
    /// This exists so there is **one** definition of what the structural
    /// fields mean. An in-memory store can use it directly, and a SQL compiler
    /// can be checked against it.
    func matchesFields(of note: Note) -> Bool {
        if let notebookID, note.notebookID != notebookID { return false }
        if !kinds.isEmpty, !kinds.contains(note.kind) { return false }
        if !tagIDs.isEmpty, !tagIDs.isSubset(of: Set(note.tagIDs)) {
            return false
        }
        if let isPinned, note.isPinned != isPinned { return false }
        if let createdWithin, !createdWithin.contains(note.createdAt) {
            return false
        }
        if let updatedWithin, !updatedWithin.contains(note.updatedAt) {
            return false
        }
        return true
    }
}
