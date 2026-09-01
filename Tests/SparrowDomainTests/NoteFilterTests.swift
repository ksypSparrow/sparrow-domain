import Foundation
import Testing
@testable import SparrowDomain

@Suite("NoteFilter")
struct NoteFilterTests {
    private static let base = Date(timeIntervalSince1970: 1_700_000_000)
    private let notebook = NotebookID()

    private func makeNote(
        title: String = "Kingfisher",
        in notebook: NotebookID? = nil,
        kind: NoteKind = .observation,
        pinned: Bool = false,
        created: TimeInterval = 0,
        updated: TimeInterval = 0
    ) -> Note {
        Note(
            title: RichText(plain: title),
            notebookID: notebook ?? self.notebook,
            kind: kind,
            isPinned: pinned,
            createdAt: Self.base.addingTimeInterval(created),
            updatedAt: Self.base.addingTimeInterval(updated)
        )
    }

    @Test("The empty filter is .all, and constrains nothing")
    func emptyFilterIsAll() {
        #expect(NoteFilter() == .all)
        #expect(NoteFilter.all.isEmpty)
        #expect(NoteFilter.all.matchesFields(of: makeNote()))
    }

    /// Shortcuts may use these as dictionary keys, so equality has to be
    /// structural and stable.
    @Test("Hashable holds across every field")
    func hashableHolds() {
        let interval = DateInterval(start: Self.base, duration: 3_600)
        let a = NoteFilter(
            text: "heron", notebookID: notebook, kinds: [.sketch, .voice],
            createdWithin: interval, updatedWithin: interval, isPinned: true
        )
        let b = NoteFilter(
            text: "heron", notebookID: notebook, kinds: [.voice, .sketch],
            createdWithin: interval, updatedWithin: interval, isPinned: true
        )

        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(Set([a, b]).count == 1)
    }

    @Test("Differing filters are not equal")
    func differingFiltersDiffer() {
        #expect(NoteFilter(isPinned: true) != NoteFilter(isPinned: false))
        #expect(NoteFilter(kinds: [.sketch]) != NoteFilter(kinds: [.voice]))
        #expect(NoteFilter(text: "a") != NoteFilter(text: "b"))
    }

    @Test("Codable round-trips")
    func codableRoundTrip() throws {
        let original = NoteFilter(
            text: "heron", notebookID: notebook, kinds: [.sketch],
            createdWithin: DateInterval(start: Self.base, duration: 60),
            isPinned: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(
            NoteFilter.self, from: encoder.encode(original)
        )
        #expect(decoded == original)
    }

    // MARK: Every field, independently

    @Test("notebookID selects one notebook")
    func notebookFieldMatches() {
        let other = NotebookID()
        let filter = NoteFilter(notebookID: notebook)

        #expect(filter.matchesFields(of: makeNote()))
        #expect(!filter.matchesFields(of: makeNote(in: other)))
    }

    /// Empty means *any kind*, not *no kinds*. The other reading would make
    /// `.all` match nothing, which is the opposite of what it says.
    @Test("An empty kinds set means any kind")
    func emptyKindsMeansAny() {
        let filter = NoteFilter(kinds: [])
        for kind in NoteKind.allCases {
            #expect(filter.matchesFields(of: makeNote(kind: kind)))
        }
    }

    @Test("kinds accepts any of the named kinds")
    func kindsMatchesAnyNamed() {
        let filter = NoteFilter(kinds: [.sketch, .voice])

        #expect(filter.matchesFields(of: makeNote(kind: .sketch)))
        #expect(filter.matchesFields(of: makeNote(kind: .voice)))
        #expect(!filter.matchesFields(of: makeNote(kind: .observation)))
    }

    @Test("isPinned distinguishes both ways", arguments: [true, false])
    func pinnedFieldMatches(pinned: Bool) {
        let filter = NoteFilter(isPinned: pinned)

        #expect(filter.matchesFields(of: makeNote(pinned: pinned)))
        #expect(!filter.matchesFields(of: makeNote(pinned: !pinned)))
    }

    @Test("createdWithin bounds by creation, not by edit")
    func createdWithinBounds() {
        let filter = NoteFilter(
            createdWithin: DateInterval(start: Self.base, duration: 3_600)
        )

        #expect(filter.matchesFields(of: makeNote(created: 60, updated: 999_999)))
        #expect(!filter.matchesFields(of: makeNote(created: 7_200)))
    }

    @Test("updatedWithin bounds by edit, not by creation")
    func updatedWithinBounds() {
        let filter = NoteFilter(
            updatedWithin: DateInterval(start: Self.base, duration: 3_600)
        )

        #expect(filter.matchesFields(of: makeNote(created: -999_999, updated: 60)))
        #expect(!filter.matchesFields(of: makeNote(updated: 7_200)))
    }

    @Test("Fields combine as AND")
    func fieldsCombineAsAnd() {
        let filter = NoteFilter(kinds: [.sketch], isPinned: true)

        #expect(filter.matchesFields(of: makeNote(kind: .sketch, pinned: true)))
        #expect(!filter.matchesFields(of: makeNote(kind: .sketch, pinned: false)))
        #expect(!filter.matchesFields(of: makeNote(kind: .voice, pinned: true)))
    }

    // MARK: Text is the index's business

    /// `matchesFields` is named that way so nobody expects it to search. A
    /// second, subtly different text matcher is exactly the bug that made the
    /// in-memory store disagree with SQLite about "Herón".
    @Test("matchesFields ignores text entirely")
    func textIsNotMatchedHere() {
        let filter = NoteFilter(text: "albatross")
        #expect(filter.matchesFields(of: makeNote(title: "Kingfisher")))
    }

    @Test("requiresTextSearch is false for absent or blank text",
          arguments: [nil, "", "   ", "\n"])
    func blankTextNeedsNoIndex(text: String?) {
        #expect(!NoteFilter(text: text).requiresTextSearch)
    }

    @Test("requiresTextSearch is true for real text")
    func realTextNeedsTheIndex() {
        #expect(NoteFilter(text: "heron").requiresTextSearch)
    }
}

@Suite("NoteSort")
struct NoteSortTests {
    private static let base = Date(timeIntervalSince1970: 1_700_000_000)
    private let notebook = NotebookID()

    private func makeNote(
        _ title: String,
        created: TimeInterval = 0,
        updated: TimeInterval = 0,
        observed: TimeInterval? = nil
    ) -> Note {
        Note(
            title: RichText(plain: title),
            notebookID: notebook,
            observedAt: observed.map(Self.base.addingTimeInterval),
            createdAt: Self.base.addingTimeInterval(created),
            updatedAt: Self.base.addingTimeInterval(updated)
        )
    }

    @Test("mostRecent is updated, descending")
    func mostRecentIsUpdatedDescending() {
        #expect(NoteSort.mostRecent.field == .updated)
        #expect(NoteSort.mostRecent.order == .descending)
    }

    @Test("Sorting by each field, ascending", arguments: NoteSort.Field.allCases)
    func everyFieldSortsAscending(field: NoteSort.Field) {
        let sort = NoteSort(field: field, order: .ascending)
        let first = makeNote("A", created: 0, updated: 0, observed: 0)
        let second = makeNote("B", created: 60, updated: 60, observed: 60)

        #expect(sort.orders(first, before: second))
        #expect(!sort.orders(second, before: first))
    }

    @Test("Descending reverses ascending", arguments: NoteSort.Field.allCases)
    func descendingReverses(field: NoteSort.Field) {
        let up = NoteSort(field: field, order: .ascending)
        let down = NoteSort(field: field, order: .descending)
        let a = makeNote("A", created: 0, updated: 0, observed: 0)
        let b = makeNote("B", created: 60, updated: 60, observed: 60)

        #expect(up.orders(a, before: b))
        #expect(down.orders(b, before: a))
    }

    @Test("Sorting by observed falls back to creation")
    func observedFallsBackToCreated() {
        let sort = NoteSort(field: .observed, order: .ascending)
        // No observation, created early. Observed late.
        let unwitnessed = makeNote("A", created: 0)
        let witnessed = makeNote("B", created: 0, observed: 60)

        #expect(sort.orders(unwitnessed, before: witnessed))
    }

    @Test("Title sorting ignores case")
    func titleSortIgnoresCase() {
        let sort = NoteSort(field: .title, order: .ascending)
        #expect(sort.orders(makeNote("alder"), before: makeNote("Zostera")))
        #expect(sort.orders(makeNote("Alder"), before: makeNote("zostera")))
    }

    /// Two notes saved in the same second sort arbitrarily without a
    /// tiebreak, and a list that reshuffles between reads looks like a bug in
    /// whatever drew it.
    @Test("Ties break on identifier, so ordering is total")
    func tiesBreakDeterministically() {
        let sort = NoteSort.mostRecent
        let a = makeNote("Same", updated: 0)
        let b = makeNote("Same", updated: 0)

        // Exactly one direction is true, and it does not change between calls.
        #expect(sort.orders(a, before: b) != sort.orders(b, before: a))
        #expect(sort.orders(a, before: b) == sort.orders(a, before: b))
    }
}
