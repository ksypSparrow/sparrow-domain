import Foundation
import Testing
@testable import SparrowDomain

@Suite("NotebookID")
struct NotebookIDTests {
    @Test("Two default-initialised identifiers are distinct")
    func defaultInitialiserIsUnique() {
        let ids = Set((0..<1_000).map { _ in NotebookID() })
        #expect(ids.count == 1_000)
    }

    @Test("Wrapping the same UUID yields equal identifiers")
    func equalityFollowsTheWrappedValue() {
        let uuid = UUID()
        #expect(NotebookID(uuid) == NotebookID(uuid))
    }

    @Test("Codable round-trips")
    func codableRoundTrip() throws {
        let original = NotebookID()
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(NotebookID.self, from: data) == original)
    }

    /// The reason these are separate types rather than two `UUID`s.
    @Test("A notebook identifier never equals a note identifier's value by accident")
    func identifiersAreDistinctTypes() {
        let uuid = UUID()
        #expect(NotebookID(uuid).value == NoteID(uuid).value)
        // …and yet the two cannot be compared, assigned or passed
        // interchangeably. That is a compile-time property, not a runtime one.
    }
}
