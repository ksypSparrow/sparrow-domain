import Foundation
import Testing
@testable import SparrowDomain

@Suite("NoteDraft")
struct NoteDraftTests {
    @Test("Defaults produce an empty, unfiled observation")
    func defaultsAreEmpty() {
        let draft = NoteDraft()
        #expect(draft.isEmpty)
        #expect(draft.notebookID == nil)
        #expect(draft.kind == .observation)
    }

    /// `nil` here means *the default notebook*, which is why storage guarantees
    /// one exists. FR-1.1 lets a note be captured without naming a notebook.
    @Test("An unfiled draft is a valid draft")
    func unfiledDraftIsValid() {
        let draft = NoteDraft(title: "Kingfisher")
        #expect(!draft.isEmpty)
        #expect(draft.notebookID == nil)
    }

    @Test("isEmpty looks at characters, not attributes")
    func emptinessIgnoresAttributes() {
        var blank = AttributedString("")
        blank.inlinePresentationIntent = .stronglyEmphasized
        #expect(NoteDraft(title: RichText(blank)).isEmpty)
    }

    @Test("Codable round-trips with attributes intact")
    func codableRoundTrip() throws {
        var attributed = AttributedString("Heron")
        attributed.inlinePresentationIntent = .stronglyEmphasized

        let original = NoteDraft(
            title: RichText(attributed),
            body: "Standing, still.",
            notebookID: NotebookID(),
            kind: .voice,
            observedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(
            NoteDraft.self, from: encoder.encode(original)
        )
        #expect(decoded == original)
    }
}
