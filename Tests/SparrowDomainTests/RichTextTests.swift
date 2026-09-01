import Foundation
import Testing
@testable import SparrowDomain

@Suite("RichText")
struct RichTextTests {
    private func emphasised(_ string: String, bold word: String) -> AttributedString {
        var text = AttributedString(string)
        if let range = text.range(of: word) {
            text[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return text
    }

    @Test("Rich text survives the round trip with attributes intact")
    func attributesSurviveTheRoundTrip() throws {
        let original = emphasised(
            "Kingfisher on the north bank",
            bold: "Kingfisher"
        )

        let restored = RichText(original).attributedString()

        #expect(restored == original)
        #expect(restored.runs.contains(where: {
            $0.inlinePresentationIntent != nil
        }))
    }

    @Test("Plain text is always present, attributes or not")
    func plainIsAlwaysThere() {
        let rich = RichText(emphasised("Kingfisher here", bold: "Kingfisher"))
        let flat = RichText(plain: "Kingfisher here")

        #expect(rich.plain == "Kingfisher here")
        #expect(flat.plain == "Kingfisher here")
        #expect(rich.attributes != nil)
        #expect(flat.attributes == nil)
    }

    /// Unattributed text pays nothing. Most notes are plain, and a blob per
    /// note would be a row's worth of bytes to say "no formatting".
    @Test("Text with no attributes stores no blob")
    func plainTextCostsNothing() {
        #expect(RichText(AttributedString("no attributes")).attributes == nil)
    }

    /// Losing formatting is a visual regression; losing the note is not
    /// something a corrupt blob should be able to cause.
    @Test("Unreadable attributes fall back to plain text, never throw")
    func corruptAttributesDegradeGracefully() {
        let corrupt = RichText(
            plain: "Kingfisher",
            attributes: Data("not json".utf8)
        )

        #expect(corrupt.attributedString() == AttributedString("Kingfisher"))
    }

    /// A blob whose characters disagree with `plain` is not this note's text.
    /// Trusting it would show a person someone else's words.
    @Test("Attributes that disagree with the plain text are rejected")
    func mismatchedAttributesAreRejected() throws {
        let other = try JSONEncoder().encode(AttributedString("Heron"))
        let mismatched = RichText(plain: "Kingfisher", attributes: other)

        #expect(mismatched.attributedString() == AttributedString("Kingfisher"))
    }

    /// The attribute blob is a plain JSON array of alternating text and
    /// attribute dictionaries, not an opaque archive. A reader that does not
    /// understand an attribute can still see every character.
    @Test("The attribute blob is transparent JSON")
    func encodedFormIsReadable() throws {
        let rich = RichText(
            emphasised("Kingfisher on the north bank", bold: "Kingfisher")
        )
        let json = String(data: try #require(rich.attributes), encoding: .utf8)

        #expect(json?.hasPrefix("[\"Kingfisher\"") == true)
        #expect(json?.contains("north bank") == true)
    }

    @Test("Empty and plain text survive the trip too")
    func edgeCasesRoundTrip() {
        for text in [AttributedString(""), AttributedString("no attributes")] {
            #expect(RichText(text).attributedString() == text)
        }
    }

    @Test("Multiple attribute runs are preserved in order")
    func manyRunsSurvive() {
        var text = AttributedString("one two three")
        if let first = text.range(of: "one") {
            text[first].inlinePresentationIntent = .stronglyEmphasized
        }
        if let last = text.range(of: "three") {
            text[last].inlinePresentationIntent = .emphasized
        }

        let restored = RichText(text).attributedString()
        #expect(restored == text)
        #expect(restored.runs.count == text.runs.count)
    }

    @Test("RichText itself round-trips through Codable")
    func codableRoundTrip() throws {
        let original = RichText(
            emphasised("Kingfisher on the north bank", bold: "Kingfisher")
        )
        let data = try JSONEncoder().encode(original)

        #expect(try JSONDecoder().decode(RichText.self, from: data) == original)
    }

    @Test("A string literal makes plain text")
    func stringLiteralIsPlain() {
        let text: RichText = "Kingfisher"
        #expect(text.plain == "Kingfisher")
        #expect(text.attributes == nil)
    }
}
