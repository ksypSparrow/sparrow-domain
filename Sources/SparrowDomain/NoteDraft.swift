import Foundation

/// Everything needed to create a note.
///
/// Writes are described, not mutated: there is no way to construct a
/// half-formed `Note` and save it later. Timestamps and identity are supplied
/// by the layer that performs the write, not by the caller.
public struct NoteDraft: Hashable, Sendable, Codable {
    public var title: String
    public var body: String

    public init(title: String = "", body: String = "") {
        self.title = title
        self.body = body
    }
}

public extension NoteDraft {
    var isEmpty: Bool {
        title.isEmpty && body.isEmpty
    }
}
