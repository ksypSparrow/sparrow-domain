import Foundation
import Testing
@testable import SparrowDomain

@Suite("NoteID")
struct NoteIDTests {
    @Test("Two default-initialised identifiers are distinct")
    func defaultInitialiserIsUnique() {
        let ids = Set((0..<1_000).map { _ in NoteID() })
        #expect(ids.count == 1_000)
    }

    @Test("Wrapping the same UUID yields equal identifiers")
    func equalityFollowsTheWrappedValue() {
        let uuid = UUID()
        #expect(NoteID(uuid) == NoteID(uuid))
    }

    @Test("Codable round-trips")
    func codableRoundTrip() throws {
        let original = NoteID()
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(NoteID.self, from: data) == original)
    }
}
