import Foundation

/// The identity of a notebook.
///
/// A distinct type from `NoteID` on purpose: a `NotebookID` cannot be passed
/// where a note is expected, and the compiler says so at the call site rather
/// than the database saying nothing at all.
public struct NotebookID: Hashable, Sendable, Codable {
    public let value: UUID

    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}

extension NotebookID: CustomStringConvertible {
    public var description: String { value.uuidString }
}
