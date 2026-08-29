import Foundation
import Testing
@testable import SparrowDomain

@Suite("NoteDraft")
struct NoteDraftTests {
    @Test("Defaults produce an empty draft")
    func defaultsAreEmpty() {
        #expect(NoteDraft().isEmpty)
    }

    @Test("Codable round-trips")
    func codableRoundTrip() throws {
        let original = NoteDraft(title: "Heron", body: "Standing, still.")
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(NoteDraft.self, from: data) == original)
    }
}
