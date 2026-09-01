import Foundation

/// How a list of notes is ordered.
public struct NoteSort: Hashable, Sendable {
    public enum Field: String, Hashable, Sendable, CaseIterable {
        case updated
        case created
        /// When the observation happened, falling back to creation for notes
        /// that never claimed a moment — `Note.happenedAt`.
        case observed
        case title
    }

    public enum Order: String, Hashable, Sendable, CaseIterable {
        case ascending
        case descending
    }

    public let field: Field
    public let order: Order

    public init(field: Field, order: Order) {
        self.field = field
        self.order = order
    }

    /// The default almost everywhere: most recently edited first.
    public static let mostRecent = NoteSort(field: .updated, order: .descending)
}

public extension NoteSort {
    /// Orders two notes, ties broken by identifier.
    ///
    /// The tiebreak is not cosmetic. Two notes saved in the same second sort
    /// arbitrarily without it, and a list that reshuffles between reads looks
    /// like a bug in whatever drew it.
    func orders(_ a: Note, before b: Note) -> Bool {
        let ascending = switch field {
        case .updated:
            (a.updatedAt, a.id.value.uuidString)
                < (b.updatedAt, b.id.value.uuidString)
        case .created:
            (a.createdAt, a.id.value.uuidString)
                < (b.createdAt, b.id.value.uuidString)
        case .observed:
            (a.happenedAt, a.id.value.uuidString)
                < (b.happenedAt, b.id.value.uuidString)
        case .title:
            (a.plainTitle.lowercased(), a.id.value.uuidString)
                < (b.plainTitle.lowercased(), b.id.value.uuidString)
        }
        return order == .ascending ? ascending : !ascending
    }
}
