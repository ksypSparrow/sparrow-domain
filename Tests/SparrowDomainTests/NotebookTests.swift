import Foundation
import Testing
@testable import SparrowDomain

@Suite("Notebook")
struct NotebookTests {
    private static let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeNotebook(
        _ name: String,
        parent: NotebookID? = nil,
        colorName: String? = nil,
        sortIndex: Int = 0
    ) -> Notebook {
        Notebook(
            name: name,
            parentID: parent,
            colorName: colorName,
            sortIndex: sortIndex,
            createdAt: Self.base,
            updatedAt: Self.base
        )
    }

    @Test("A notebook can reference another as its parent")
    func notebooksNest() {
        let parent = makeNotebook("Field Surveys")
        let child = makeNotebook("Wetlands", parent: parent.id)

        #expect(child.parentID == parent.id)
        #expect(parent.isTopLevel)
        #expect(!child.isTopLevel)
    }

    @Test("Codable round-trips, nesting and colour included")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let original = makeNotebook(
            "Wetlands",
            parent: NotebookID(),
            colorName: "riverbank",
            sortIndex: 3
        )

        let decoded = try decoder.decode(
            Notebook.self,
            from: encoder.encode(original)
        )
        #expect(decoded == original)
    }

    @Test("A top-level notebook round-trips with parentID still nil")
    func topLevelRoundTripKeepsNilParent() throws {
        let original = makeNotebook("Inbox")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Notebook.self, from: data)

        #expect(decoded.parentID == nil)
        #expect(decoded.isTopLevel)
    }

    @Test("Identity survives a rename")
    func identityIsStableAcrossEdits() {
        var notebook = makeNotebook("Untitled")
        let id = notebook.id
        notebook.name = "Wetlands"
        notebook.colorName = "riverbank"

        #expect(notebook.id == id)
    }

    @Test("Siblings order by sortIndex, then by name")
    func siblingsOrderPredictably() {
        let notebooks = [
            makeNotebook("Zostera", sortIndex: 1),
            makeNotebook("Alder", sortIndex: 2),
            makeNotebook("Alder Carr", sortIndex: 1),
        ]

        let ordered = notebooks
            .sorted(by: Notebook.orderedBySiblingPosition)
            .map(\.name)

        #expect(ordered == ["Alder Carr", "Zostera", "Alder"])
    }
}
