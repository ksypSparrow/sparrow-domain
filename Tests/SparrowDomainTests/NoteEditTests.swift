import Foundation
import Testing
@testable import SparrowDomain

@Suite("NoteEdit")
struct NoteEditTests {
    private static let created = Date(timeIntervalSince1970: 1_700_000_000)
    private static let edited = Date(timeIntervalSince1970: 1_700_003_600)
    private static let observed = Date(timeIntervalSince1970: 1_699_900_000)

    private func makeNote(observedAt: Date? = nil) -> Note {
        Note(
            title: "Kingfisher",
            body: "North bank",
            notebookID: NotebookID(),
            observedAt: observedAt,
            createdAt: Self.created,
            updatedAt: Self.created
        )
    }

    @Test("An empty edit changes nothing, timestamp included")
    func emptyEditChangesNothing() {
        let original = makeNote()
        #expect(NoteEdit().isEmpty)

        let result = original.applying(NoteEdit(), at: Self.edited)
        #expect(result == original)
        #expect(result.updatedAt == Self.created)
    }

    @Test("A partial edit changes only the fields it names")
    func partialEditTouchesOnlyNamedFields() {
        let original = makeNote()
        let result = original.applying(NoteEdit(isPinned: true), at: Self.edited)

        #expect(result.isPinned)
        #expect(result.title == original.title)
        #expect(result.kind == original.kind)
        #expect(result.updatedAt == Self.edited)
    }

    // MARK: The double optional

    @Test("nil leaves observedAt alone")
    func nilLeavesTheMoment() {
        let original = makeNote(observedAt: Self.observed)
        let result = original.applying(NoteEdit(isPinned: true), at: Self.edited)

        #expect(result.observedAt == Self.observed)
    }

    @Test("some(nil) clears observedAt")
    func someNilClearsTheMoment() {
        let original = makeNote(observedAt: Self.observed)
        let result = original.applying(
            NoteEdit(observedAt: .some(nil)),
            at: Self.edited
        )

        #expect(result.observedAt == nil)
    }

    @Test("some(date) sets observedAt")
    func someDateSetsTheMoment() {
        let original = makeNote()
        let result = original.applying(
            NoteEdit(observedAt: Self.observed),
            at: Self.edited
        )

        #expect(result.observedAt == Self.observed)
    }

    @Test("An edit that only clears observedAt is not empty")
    func clearingIsNotEmptiness() {
        #expect(!NoteEdit(observedAt: .some(nil)).isEmpty)
    }

    @Test("Identity and createdAt survive every edit")
    func identityIsStable() {
        let original = makeNote()
        let result = original.applying(
            NoteEdit(title: "Renamed", kind: .sketch, isPinned: true),
            at: Self.edited
        )

        #expect(result.id == original.id)
        #expect(result.createdAt == Self.created)
    }
}

@Suite("Note")
struct NoteRichTextTests {
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Plain projections match the attributed content")
    func plainProjectionsMatch() {
        var attributed = AttributedString("Kingfisher")
        attributed.inlinePresentationIntent = .stronglyEmphasized

        let note = Note(
            title: RichText(attributed),
            body: "North bank, 40 minutes.",
            notebookID: NotebookID(),
            createdAt: Self.now,
            updatedAt: Self.now
        )

        #expect(note.plainTitle == "Kingfisher")
        #expect(note.plainBody == "North bank, 40 minutes.")
    }

    @Test("A note with attributes in both fields round-trips")
    func codableRoundTrip() throws {
        var attributed = AttributedString("North bank at dawn")
        if let range = attributed.range(of: "dawn") {
            attributed[range].inlinePresentationIntent = .emphasized
        }
        let original = Note(
            title: "Kingfisher",
            body: RichText(attributed),
            notebookID: NotebookID(),
            kind: .sketch,
            isPinned: true,
            observedAt: Self.now.addingTimeInterval(-3_600),
            createdAt: Self.now,
            updatedAt: Self.now
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(
            Note.self, from: encoder.encode(original)
        )
        #expect(decoded == original)
    }

    @Test("isEmpty looks at characters, not attributes")
    func emptinessIgnoresAttributes() {
        var blank = AttributedString("")
        blank.inlinePresentationIntent = .stronglyEmphasized

        let note = Note(
            title: RichText(blank),
            body: "",
            notebookID: NotebookID(),
            createdAt: Self.now,
            updatedAt: Self.now
        )
        #expect(note.isEmpty)
    }

    @Test("happenedAt prefers the observation, then creation")
    func happenedAtFallsBack() {
        let observed = Self.now.addingTimeInterval(-7_200)
        let notebook = NotebookID()

        let witnessed = Note(
            notebookID: notebook, observedAt: observed,
            createdAt: Self.now, updatedAt: Self.now
        )
        let unwitnessed = Note(
            notebookID: notebook,
            createdAt: Self.now, updatedAt: Self.now
        )

        #expect(witnessed.happenedAt == observed)
        #expect(unwitnessed.happenedAt == Self.now)
    }
}

@Suite("NoteKind")
struct NoteKindTests {
    /// These strings are written into every row and every journal payload.
    /// Renaming a case is a data migration, not a refactor.
    @Test("Raw values are the stable strings storage relies on")
    func rawValuesAreStable() {
        #expect(NoteKind.observation.rawValue == "observation")
        #expect(NoteKind.sketch.rawValue == "sketch")
        #expect(NoteKind.voice.rawValue == "voice")
        #expect(NoteKind.daily.rawValue == "daily")
        #expect(NoteKind.allCases.count == 4)
    }

    @Test("Every case round-trips through Codable")
    func codableRoundTrip() throws {
        for kind in NoteKind.allCases {
            let data = try JSONEncoder().encode(kind)
            #expect(try JSONDecoder().decode(NoteKind.self, from: data) == kind)
        }
    }
}
