import Foundation

/// A stable, human-readable identifier for a tag: `"wetland-survey"`.
///
/// Unlike `NoteID` and `NotebookID`, a tag's identity **is** its text. Two
/// people typing "Field Survey" and "field survey" on different devices must
/// end up with the same tag, and no coordination is available to make that
/// happen — so the identity has to be derivable from the label alone.
public struct TagID: Hashable, Sendable, Codable {
    public let slug: String

    /// Accepts a slug that is already normalised, and rejects anything else.
    ///
    /// Validity is defined as *normalising it changes nothing*. That keeps one
    /// definition rather than two: there is no separate list of legal
    /// characters that could drift from what `init(normalizing:)` produces.
    public init?(slug: String) {
        guard let normalized = TagID.normalize(slug), normalized == slug else {
            return nil
        }
        self.slug = slug
    }

    /// Derives an identifier from what a person typed.
    ///
    /// ⚠️ **Failable, unlike the sketch in `contracts.md`.** A label with no
    /// letters or digits — `"!!!"`, `"🐦"`, `"   "` — has no slug, and a
    /// non-failable initialiser would have to invent one or return something
    /// unusable. Both push validation into every caller, which is the same
    /// argument that made `defaultNotebook()` non-optional: decide once, here.
    public init?(normalizing label: String) {
        guard let slug = TagID.normalize(label) else { return nil }
        self.slug = slug
    }

    /// Folds diacritics, lowercases, and joins the remaining runs of letters
    /// and digits with hyphens.
    ///
    /// Diacritic folding matches what the search index does, so a note tagged
    /// `"Herón"` is found by someone typing `"heron"` — the two would
    /// otherwise disagree about the same word.
    ///
    /// - Returns: `nil` when nothing survives.
    static func normalize(_ label: String) -> String? {
        let folded = label.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: nil
        )
        let parts = folded
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { $0.lowercased() }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: "-")
    }
}

extension TagID: CustomStringConvertible {
    public var description: String { slug }
}
