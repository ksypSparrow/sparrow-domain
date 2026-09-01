import Foundation
import Testing
@testable import SparrowDomain

@Suite("TagID · normalising")
struct TagIDNormalisingTests {
    @Test("Field Survey becomes field-survey")
    func theWorkedExample() {
        #expect(TagID(normalizing: "Field Survey")?.slug == "field-survey")
    }

    @Test("Case is folded", arguments: [
        "wetlands", "Wetlands", "WETLANDS", "WeTlAnDs",
    ])
    func caseIsFolded(label: String) {
        #expect(TagID(normalizing: label)?.slug == "wetlands")
    }

    /// The same folding the search index uses. Without it, a note tagged
    /// "Herón" would be untaggable by someone typing "heron" — and the two
    /// halves of the app would disagree about the same word.
    @Test("Diacritics fold the way search does", arguments: [
        ("Herón", "heron"),
        ("naïve survey", "naive-survey"),
        ("Zostera marina", "zostera-marina"),
    ])
    func diacriticsFold(label: String, expected: String) {
        #expect(TagID(normalizing: label)?.slug == expected)
    }

    @Test("Punctuation and whitespace become single hyphens", arguments: [
        ("field  survey", "field-survey"),
        ("field/survey", "field-survey"),
        ("field, survey", "field-survey"),
        ("  field survey  ", "field-survey"),
        ("field---survey", "field-survey"),
        ("#wetlands", "wetlands"),
    ])
    func punctuationCollapses(label: String, expected: String) {
        #expect(TagID(normalizing: label)?.slug == expected)
    }

    @Test("Digits survive")
    func digitsSurvive() {
        #expect(TagID(normalizing: "Survey 2026")?.slug == "survey-2026")
    }

    /// The property the whole design rests on: two people typing the same
    /// thing differently, on devices that have never met, get the same tag.
    @Test("Labels that mean the same thing produce the same identifier")
    func equivalentLabelsCollide() {
        let variants = [
            "Field Survey", "field survey", "FIELD  SURVEY",
            "field-survey", "  Field, Survey  ",
        ]
        let ids = Set(variants.compactMap { TagID(normalizing: $0) })
        #expect(ids.count == 1)
    }

    @Test("Different labels stay different")
    func differentLabelsDiffer() {
        #expect(TagID(normalizing: "wetlands") != TagID(normalizing: "uplands"))
    }

    // MARK: Nothing to normalise

    /// ⚠️ Failable, unlike the sketch in `contracts.md`. A label with no
    /// letters or digits has no slug, and a non-failable initialiser would
    /// have to invent one or return something unusable — both of which push
    /// validation into every caller.
    @Test("A label with nothing to normalise has no identifier",
          arguments: ["", "   ", "!!!", "---", "🐦", "\n\t"])
    func unslugableLabelsFail(label: String) {
        #expect(TagID(normalizing: label) == nil)
    }

    // MARK: Validation

    @Test("A normalised slug is accepted", arguments: [
        "wetlands", "field-survey", "survey-2026", "a",
    ])
    func validSlugsAreAccepted(slug: String) {
        #expect(TagID(slug: slug)?.slug == slug)
    }

    /// Validity is *normalising it changes nothing*, so there is no separate
    /// list of legal characters to drift from what normalisation produces.
    @Test("Anything not already normalised is rejected", arguments: [
        "Wetlands", "field survey", "field_survey", "-wetlands",
        "wetlands-", "field--survey", "", "herón", "🐦",
    ])
    func unnormalisedSlugsAreRejected(slug: String) {
        #expect(TagID(slug: slug) == nil)
    }

    @Test("Normalising is idempotent", arguments: [
        "Field Survey", "  Herón!  ", "survey---2026", "wetlands",
    ])
    func normalisingIsIdempotent(label: String) throws {
        let once = try #require(TagID(normalizing: label))
        let twice = try #require(TagID(normalizing: once.slug))
        #expect(once == twice)
        // …which is exactly what makes the validity rule self-consistent.
        #expect(TagID(slug: once.slug) == once)
    }

    @Test("Codable round-trips")
    func codableRoundTrip() throws {
        let original = try #require(TagID(normalizing: "Field Survey"))
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(TagID.self, from: data) == original)
    }
}

@Suite("Tag")
struct TagTests {
    @Test("A tag keeps the label as typed and derives the identifier")
    func labelIsKeptIdentifierIsDerived() throws {
        let tag = try #require(Tag(label: "Field Survey"))
        #expect(tag.label == "Field Survey")
        #expect(tag.id.slug == "field-survey")
    }

    @Test("Surrounding whitespace is trimmed from the label too")
    func labelIsTrimmed() throws {
        #expect(try #require(Tag(label: "  Wetlands  ")).label == "Wetlands")
    }

    @Test("A label with no slug makes no tag")
    func unslugableLabelMakesNoTag() {
        #expect(Tag(label: "🐦") == nil)
        #expect(Tag(label: "   ") == nil)
    }

    @Test("Two spellings of one tag share an identifier but keep their labels")
    func spellingsShareIdentity() throws {
        let first = try #require(Tag(label: "Field Survey"))
        let second = try #require(Tag(label: "field survey"))

        #expect(first.id == second.id)
        #expect(first.label != second.label)
    }
}

@Suite("Tags on notes")
struct NoteTagTests {
    private let notebook = NotebookID()
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeNote(tags: [TagID]) -> Note {
        Note(
            title: "Kingfisher",
            notebookID: notebook,
            tagIDs: tags,
            createdAt: Self.now,
            updatedAt: Self.now
        )
    }

    @Test("Tag order is preserved")
    func orderIsPreserved() throws {
        let wetlands = try #require(TagID(normalizing: "wetlands"))
        let survey = try #require(TagID(normalizing: "survey"))

        #expect(makeNote(tags: [survey, wetlands]).tagIDs == [survey, wetlands])
    }

    /// An edit replaces the whole set. Merging inside `applying` would make
    /// the same edit produce different results depending on what it was
    /// applied to — which is not what "describe the change" means.
    @Test("An edit replaces the tags rather than merging them")
    func editReplacesTags() throws {
        let old = try #require(TagID(normalizing: "old"))
        let new = try #require(TagID(normalizing: "new"))
        let note = makeNote(tags: [old])

        let updated = note.applying(
            NoteEdit(tagIDs: [new]), at: Self.now.addingTimeInterval(60)
        )
        #expect(updated.tagIDs == [new])
    }

    @Test("An edit naming no tags leaves them alone")
    func nilTagsLeavesThemAlone() throws {
        let tag = try #require(TagID(normalizing: "kept"))
        let note = makeNote(tags: [tag])

        let updated = note.applying(
            NoteEdit(isPinned: true), at: Self.now.addingTimeInterval(60)
        )
        #expect(updated.tagIDs == [tag])
    }

    @Test("An edit can clear every tag")
    func editCanClearTags() throws {
        let note = makeNote(tags: [try #require(TagID(normalizing: "gone"))])

        let updated = note.applying(
            NoteEdit(tagIDs: []), at: Self.now.addingTimeInterval(60)
        )
        #expect(updated.tagIDs.isEmpty)
    }

    // MARK: Filtering

    @Test("An empty tag set in a filter matches any note")
    func emptyTagSetMatchesAnything() throws {
        let note = makeNote(tags: [try #require(TagID(normalizing: "wetlands"))])
        #expect(NoteFilter(tagIDs: []).matchesFields(of: note))
        #expect(NoteFilter.all.matchesFields(of: makeNote(tags: [])))
    }

    /// "Tagged wetlands **and** survey" is the useful question. "Either" is
    /// expressible as two searches; "both" is not expressible any other way.
    @Test("A filter requires every tag it names")
    func filterRequiresEveryTag() throws {
        let wetlands = try #require(TagID(normalizing: "wetlands"))
        let survey = try #require(TagID(normalizing: "survey"))
        let both = makeNote(tags: [wetlands, survey])
        let one = makeNote(tags: [wetlands])

        let filter = NoteFilter(tagIDs: [wetlands, survey])
        #expect(filter.matchesFields(of: both))
        #expect(!filter.matchesFields(of: one))
    }

    @Test("A note with extra tags still matches")
    func extraTagsAreFine() throws {
        let wetlands = try #require(TagID(normalizing: "wetlands"))
        let extra = try #require(TagID(normalizing: "extra"))

        #expect(
            NoteFilter(tagIDs: [wetlands])
                .matchesFields(of: makeNote(tags: [wetlands, extra]))
        )
    }

    @Test("A note round-trips with its tags")
    func codableRoundTrip() throws {
        let original = makeNote(tags: [
            try #require(TagID(normalizing: "wetlands")),
            try #require(TagID(normalizing: "survey")),
        ])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(
            try decoder.decode(Note.self, from: encoder.encode(original))
                == original
        )
    }
}
