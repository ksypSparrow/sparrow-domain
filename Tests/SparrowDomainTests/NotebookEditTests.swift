import Foundation
import Testing
@testable import SparrowDomain

@Suite("NotebookEdit")
struct NotebookEditTests {
    private static let created = Date(timeIntervalSince1970: 1_700_000_000)
    private static let edited = Date(timeIntervalSince1970: 1_700_003_600)

    private func makeNotebook(
        name: String = "Wetlands",
        parent: NotebookID? = nil,
        colorName: String? = "riverbank",
        sortIndex: Int = 2
    ) -> Notebook {
        Notebook(
            name: name,
            parentID: parent,
            colorName: colorName,
            sortIndex: sortIndex,
            createdAt: Self.created,
            updatedAt: Self.created
        )
    }

    // MARK: The empty edit

    @Test("An empty edit changes nothing at all")
    func emptyEditChangesNothing() {
        let original = makeNotebook()
        #expect(NotebookEdit().isEmpty)
        #expect(original.applying(NotebookEdit(), at: Self.edited) == original)
    }

    /// The timestamp is the part that is easy to get wrong. A bumped
    /// `updatedAt` on an empty save looks like a real change to the journal,
    /// and V2 would ship a row across the network to say nothing happened.
    @Test("An empty edit does not bump updatedAt")
    func emptyEditDoesNotTouchTheTimestamp() {
        let original = makeNotebook()
        let result = original.applying(NotebookEdit(), at: Self.edited)

        #expect(result.updatedAt == Self.created)
    }

    // MARK: Partial edits

    @Test("A partial edit changes only the fields it names")
    func partialEditTouchesOnlyNamedFields() {
        let original = makeNotebook()
        let result = original.applying(
            NotebookEdit(name: "Saltmarsh"),
            at: Self.edited
        )

        #expect(result.name == "Saltmarsh")
        #expect(result.colorName == original.colorName)
        #expect(result.parentID == original.parentID)
        #expect(result.sortIndex == original.sortIndex)
    }

    @Test("A real edit does bump updatedAt, and never createdAt")
    func realEditBumpsTheTimestamp() {
        let original = makeNotebook()
        let result = original.applying(
            NotebookEdit(sortIndex: 9),
            at: Self.edited
        )

        #expect(result.updatedAt == Self.edited)
        #expect(result.createdAt == Self.created)
    }

    @Test("Identity survives every edit")
    func identityIsStable() {
        let original = makeNotebook()
        let result = original.applying(
            NotebookEdit(name: "Renamed", sortIndex: 4),
            at: Self.edited
        )

        #expect(result.id == original.id)
    }

    // MARK: The double optional

    @Test("nil leaves the parent alone")
    func nilParentLeavesItAlone() {
        let parent = NotebookID()
        let original = makeNotebook(parent: parent)

        let result = original.applying(NotebookEdit(name: "x"), at: Self.edited)
        #expect(result.parentID == parent)
    }

    @Test("some(nil) moves the notebook to the top level")
    func someNilClearsTheParent() {
        let original = makeNotebook(parent: NotebookID())

        let result = original.applying(
            NotebookEdit(parentID: .some(nil)),
            at: Self.edited
        )
        #expect(result.parentID == nil)
        #expect(result.isTopLevel)
    }

    @Test("some(id) reparents the notebook")
    func someIDReparents() {
        let original = makeNotebook()
        let newParent = NotebookID()

        let result = original.applying(
            NotebookEdit(parentID: newParent),
            at: Self.edited
        )
        #expect(result.parentID == newParent)
    }

    @Test("The same three cases hold for colour")
    func colourFollowsTheSameRules() {
        let original = makeNotebook(colorName: "riverbank")

        let untouched = original.applying(NotebookEdit(name: "x"), at: Self.edited)
        let cleared = original.applying(NotebookEdit(colorName: .some(nil)), at: Self.edited)
        let changed = original.applying(NotebookEdit(colorName: "saltmarsh"), at: Self.edited)

        #expect(untouched.colorName == "riverbank")
        #expect(cleared.colorName == nil)
        #expect(changed.colorName == "saltmarsh")
    }

    /// Clearing a field is not the same as naming no field, and an edit that
    /// only clears something must still count as an edit.
    @Test("An edit that only clears a field is not empty")
    func clearingIsNotEmptiness() {
        let clearing = NotebookEdit(colorName: .some(nil))
        #expect(!clearing.isEmpty)

        let original = makeNotebook(colorName: "riverbank")
        #expect(original.applying(clearing, at: Self.edited).updatedAt == Self.edited)
    }

    @Test("Every field is independently settable")
    func fieldsAreIndependent() {
        let original = makeNotebook()
        let parent = NotebookID()
        let result = original.applying(
            NotebookEdit(
                name: "Everything",
                parentID: parent,
                colorName: .some(nil),
                sortIndex: 7
            ),
            at: Self.edited
        )

        #expect(result.name == "Everything")
        #expect(result.parentID == parent)
        #expect(result.colorName == nil)
        #expect(result.sortIndex == 7)
    }
}

@Suite("NotebookDraft")
struct NotebookDraftTests {
    @Test("Defaults leave a top-level, uncoloured notebook")
    func defaultsAreMinimal() {
        let draft = NotebookDraft(name: "Wetlands")
        #expect(draft.parentID == nil)
        #expect(draft.colorName == nil)
    }

    @Test("Codable round-trips")
    func codableRoundTrip() throws {
        let original = NotebookDraft(
            name: "Wetlands",
            parentID: NotebookID(),
            colorName: "riverbank"
        )
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(NotebookDraft.self, from: data) == original)
    }
}
