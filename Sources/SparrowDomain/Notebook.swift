import Foundation

/// A place to put notes.
///
/// - Note: `parentID` is here from the first release that has notebooks at all,
///   because the `.notes.folder` schema requires nesting. Adding it later would
///   be a breaking change to a type two repositories store.
public struct Notebook: Identifiable, Hashable, Sendable, Codable {
    public typealias ID = NotebookID

    public let id: NotebookID
    public var name: String

    /// Notebooks nest. `nil` means this one sits at the top level.
    public var parentID: NotebookID?

    /// A name from the app's palette, not a colour value. Storing
    /// `"riverbank"` rather than `#3A7D44` keeps the domain free of anything
    /// platform-specific, and lets the palette change without a migration.
    public var colorName: String?

    /// Where this notebook sits among its siblings. Lower sorts first.
    public var sortIndex: Int

    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: NotebookID = NotebookID(),
        name: String,
        parentID: NotebookID? = nil,
        colorName: String? = nil,
        sortIndex: Int = 0,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.parentID = parentID
        self.colorName = colorName
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Notebook {
    /// A notebook with no parent sits at the root of the tree.
    var isTopLevel: Bool { parentID == nil }

    /// Sibling ordering: `sortIndex` first, then name, so two notebooks that
    /// share an index still order predictably instead of arbitrarily.
    static func orderedBySiblingPosition(_ a: Notebook, _ b: Notebook) -> Bool {
        (a.sortIndex, a.name) < (b.sortIndex, b.name)
    }
}
