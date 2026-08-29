import Foundation
import Testing
@testable import SparrowDomain

@Suite("Note")
struct NoteTests {
    @Test("Codable round-trips with second-level date fidelity")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let original = Note(
            title: "Kingfisher",
            body: "Perched on the north bank, 40 minutes.",
            createdAt: created,
            updatedAt: created.addingTimeInterval(60)
        )

        let decoded = try decoder.decode(
            Note.self,
            from: encoder.encode(original)
        )
        #expect(decoded == original)
    }

    @Test("Identity is independent of content")
    func identityIsStableAcrossEdits() {
        let now = Date()
        var note = Note(title: "Draft", createdAt: now, updatedAt: now)
        let id = note.id
        note.title = "Revised"
        #expect(note.id == id)
    }

    @Test("isEmpty requires both fields empty", arguments: [
        ("", "", true),
        ("Kingfisher", "", false),
        ("", "north bank", false),
        ("Kingfisher", "north bank", false),
    ])
    func emptinessRequiresBothFields(
        title: String,
        body: String,
        expected: Bool
    ) {
        let now = Date()
        let note = Note(title: title, body: body, createdAt: now, updatedAt: now)
        #expect(note.isEmpty == expected)
    }
}
