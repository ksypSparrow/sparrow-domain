import Foundation

/// A partial change to a notebook. Every field is optional, and `nil` means
/// *leave this alone*.
///
/// ⚠️ **The nullable fields are doubly optional, and that is deliberate.** A
/// single optional cannot distinguish *leave unchanged* from *clear it*:
///
/// ```
///    parentID = nil          leave the parent alone
///    parentID = .some(nil)   move this notebook to the top level
///    parentID = .some(id)    reparent it under `id`
/// ```
///
/// Ugly at the declaration, correct at the call site — and the alternative is
/// a separate `clearsParent: Bool` for every nullable field, which is the same
/// information with more ways to contradict itself.
/// ⚠️ **Deliberately not `Codable`.** The doubly-optional fields do not
/// survive JSON: `.some(nil)` encodes as `null` and decodes back as `nil`, so
/// "clear this field" would silently become "leave it alone". 🧪 Verified on
/// Swift 6.4.
///
/// Nothing needs to encode an edit — the journal carries the *resulting*
/// entity, not the instruction that produced it — so the conformance is
/// omitted rather than papered over with a custom coder.
public struct NotebookEdit: Hashable, Sendable {
    public var name: String?
    public var parentID: NotebookID??
    public var colorName: String??
    public var sortIndex: Int?

    public init(
        name: String? = nil,
        parentID: NotebookID?? = nil,
        colorName: String?? = nil,
        sortIndex: Int? = nil
    ) {
        self.name = name
        self.parentID = parentID
        self.colorName = colorName
        self.sortIndex = sortIndex
    }
}

public extension NotebookEdit {
    /// An edit that names no fields at all.
    var isEmpty: Bool {
        name == nil && parentID == nil && colorName == nil && sortIndex == nil
    }
}

public extension Notebook {
    /// Returns a copy with `edit` applied.
    ///
    /// An edit that names no fields returns the notebook **completely**
    /// unchanged, `updatedAt` included. A bumped timestamp on an empty save
    /// would look like a real change to the sync journal, and V2 would ship a
    /// row across the network to say nothing happened.
    func applying(_ edit: NotebookEdit, at date: Date) -> Notebook {
        guard !edit.isEmpty else { return self }

        var updated = self
        if let name = edit.name { updated.name = name }
        if let parentID = edit.parentID { updated.parentID = parentID }
        if let colorName = edit.colorName { updated.colorName = colorName }
        if let sortIndex = edit.sortIndex { updated.sortIndex = sortIndex }
        updated.updatedAt = date
        return updated
    }
}
