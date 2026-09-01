import Foundation

/// A label someone attached to notes.
///
/// `id` is derived from `label`, so the two can disagree only if the label was
/// edited without re-deriving — which is why renaming a tag is a new `TagID`
/// and a migration of the notes that used it, not an in-place edit.
public struct Tag: Identifiable, Hashable, Sendable, Codable {
    public typealias ID = TagID

    public let id: TagID
    /// What a person typed, kept as they typed it: `"Field Survey"`.
    public var label: String

    public init(id: TagID, label: String) {
        self.id = id
        self.label = label
    }

    /// Derives both from a label. `nil` when the label has no slug.
    public init?(label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let id = TagID(normalizing: trimmed) else { return nil }
        self.init(id: id, label: trimmed)
    }
}
