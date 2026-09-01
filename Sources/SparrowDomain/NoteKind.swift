import Foundation

/// What a note is, which decides how it is presented and which schema it maps
/// to when the app exposes it to the system.
///
/// ⚠️ **The raw values are persisted.** They are written into every row and
/// into every journal payload, so renaming a case is a data migration, not a
/// refactor.
public enum NoteKind: String, Hashable, Sendable, Codable, CaseIterable {
    case observation
    case sketch
    case voice
    case daily
}
