import Foundation

/// What a note is, which decides how it is presented and which schema it maps
/// to when the app exposes it to the system.
///
/// ⚠️ **The raw values are persisted.** They are written into every row and
/// into every journal payload, so renaming a case is a data migration, not a
/// refactor.
/// ⚠️ `@frozen`: this set is closed, and adding a case is a **major** version
/// bump rather than something consumers absorb silently.
///
/// Without it, a consumer built against the resilient binary gets
/// `@unknown default` instead of an exhaustiveness error — so a new case
/// arrives at runtime as whatever that default picked. Two switches were
/// already degraded that way: `ColdStorage.FilterCompiler.orderClause`, whose
/// fallback silently disagrees with `NoteSort.orders(_:before:)`, and
/// `NoteEntity`'s kind mapping, whose comment promised a compile error it no
/// longer produced.
@frozen
public enum NoteKind: String, Hashable, Sendable, Codable, CaseIterable {
    case observation
    case sketch
    case voice
    case daily
}
