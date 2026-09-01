import Foundation

/// Rich text, stored so that a phone and a Linux server can both handle it.
///
/// ⚠️ **This is not `AttributedString`, and that is deliberate.**
/// 🧪 Verified on Swift 6.1 for Linux: `AttributedString` exists there but has
/// **no `Codable` conformance**, and the presentation-intent attributes are
/// absent too. A `Note` whose fields were `AttributedString` would not compile
/// for the V2 server at all — not "would round-trip differently", would not
/// build.
///
/// So rich text travels as two parts:
///
/// ```
///    plain       the characters. Always present, on every platform.
///    attributes  Apple's encoding of the runs. Opaque elsewhere.
/// ```
///
/// A server moves `attributes` through untouched and never re-encodes it,
/// which is exactly the fallback the design anticipated. `plain` is what
/// search matches, what a list row draws, and what survives if the attribute
/// format ever changes.
public struct RichText: Hashable, Sendable, Codable {
    /// The characters, with every attribute dropped.
    public let plain: String

    /// Platform-specific encoding of the attribute runs, or `nil` when the
    /// text carries none. Treat as opaque unless you produced it.
    public let attributes: Data?

    public init(plain: String, attributes: Data? = nil) {
        self.plain = plain
        self.attributes = attributes
    }

    public static let empty = RichText(plain: "")

    public var isEmpty: Bool { plain.isEmpty }
}

extension RichText: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(plain: value)
    }
}

extension RichText: CustomStringConvertible {
    public var description: String { plain }
}

// MARK: - AttributedString bridging

/// Available where `AttributedString` is `Codable` — every Apple platform.
/// The V2 server compiles the rest of this file and simply never calls these.
#if canImport(Darwin)
public extension RichText {
    init(_ text: AttributedString) {
        let plain = String(text.characters)
        // Only pay for the attribute blob when there is something to keep.
        // Comparing against a plain construction is the cheapest honest test:
        // if they are equal, every run is unattributed.
        let hasAttributes = text != AttributedString(plain)
        self.init(
            plain: plain,
            attributes: hasAttributes ? try? JSONEncoder().encode(text) : nil
        )
    }

    /// The attributed form, or plain text if the attributes cannot be read.
    ///
    /// Never throws. Losing formatting is a visual regression; losing the note
    /// is not something a reader should be able to cause.
    func attributedString() -> AttributedString {
        guard let attributes,
              let decoded = try? JSONDecoder()
                .decode(AttributedString.self, from: attributes),
              String(decoded.characters) == plain
        else {
            return AttributedString(plain)
        }
        return decoded
    }
}
#endif
