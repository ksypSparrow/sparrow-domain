import Foundation

/// A single captured note.
///
/// - Note: `title` and `body` are `String` only for wave 0, which exists to
///   prove the pipeline end to end. They become `AttributedString` in 0.4.0,
///   because the `.notes.note` schema mandates rich text and changing the type
///   of a stored field costs a coordinated release across three repositories.
public struct Note: Identifiable, Hashable, Sendable, Codable {
    public typealias ID = NoteID

    public let id: NoteID
    public var title: String
    public var body: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: NoteID = NoteID(),
        title: String = "",
        body: String = "",
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Note {
    /// A note carrying no content in either field.
    var isEmpty: Bool {
        title.isEmpty && body.isEmpty
    }
}
