# Changelog

All notable changes to `SparrowDomain`. This package sits at the root of the
dependency diamond — every release here starts a wave of the release train.

Pre-1.0, **the minor is the breaking bump**. Dependents pin with
`.upToNextMinor(from:)`.

## [Unreleased]

## [0.4.0] — wave 3 · the note, complete

The largest release here. Notes gain everything they need, and rich text
arrives — in a shape that actually compiles for the V2 server.

### Changed — breaking

- **`Note.title` and `body` are now `RichText`**, not `String`.
- `Note` gains `notebookID`, `kind`, `isPinned`, `observedAt`. `notebookID` is
  required, so `Note.init` now needs one.

### Added

- `RichText` — `plain: String` plus an opaque `attributes: Data?`.
- `NoteKind` — `observation` · `sketch` · `voice` · `daily`.
- `NoteDraft` full shape; `NoteEdit` with `observedAt: Date??`.
- `Note.applying(_:at:)`, `plainTitle`, `plainBody`, `happenedAt`.

### Why `RichText` is not `AttributedString`

🧪 **Verified on Swift 6.1.3 and 6.2.4 for Linux:** `AttributedString` exists
but has **no `Codable` conformance**, and the presentation-intent attributes
are absent. A `Note` whose fields were `AttributedString` would not compile for
the server at all — not "would round-trip differently", *would not build*.

This closes open question Q1, four waves before the plan expected an answer.
The design's own stated fallback was "the server treats rich text as opaque
`Data` and never re-encodes it", and that is exactly this shape:

```
   plain       the characters. Always present, on every platform.
   attributes  Apple's encoding of the runs. Opaque elsewhere.
```

🧪 `SparrowDomain` now compiles on Linux (Swift 6.2, module-level) — the first
time that promise has been tested rather than asserted.

### Notes

- Unattributed text stores no blob. Most notes are plain.
- Unreadable attributes fall back to plain text and never throw. Losing
  formatting is a visual regression; losing the note is not something a corrupt
  blob should be able to cause.
- A blob whose characters disagree with `plain` is rejected — trusting it would
  show a person another note's words.
- `NoteKind` raw values are persisted. Renaming a case is a data migration.

## [0.3.0] — wave 2 · notebook writes

Describing a change to a notebook, without performing one. Nothing here touches
storage; that is cold-storage 0.3.0.

### Added

- `NotebookDraft` — `name`, `parentID`, `colorName`.
- `NotebookEdit` — every field optional, `nil` meaning *leave unchanged*.
- `Notebook.applying(_:at:)` — pure edit semantics.

### Notes

- ⚠️ **The nullable fields are doubly optional.** A single optional cannot
  distinguish *leave the parent alone* from *move this to the top level*.
  `nil` leaves, `.some(nil)` clears, `.some(id)` sets.
- **An empty edit returns the notebook completely unchanged, `updatedAt`
  included.** A bumped timestamp on an empty save would look like a real change
  to the sync journal, and V2 would ship a row across the network to say
  nothing happened.
- `NotebookDraft` has no `sortIndex`. Where a new notebook lands among its
  siblings depends on how many there already are, which a caller creating one
  from a Shortcut cannot know. Storage assigns it.

## [0.2.0] — wave 1 · notebook

A place to put notes. Nothing about `Note` changes in this release; the two are
linked in 0.4.0, when `Note` gains `notebookID`.

### Added

- `NotebookID` — a distinct type from `NoteID`, so one cannot be passed where
  the other belongs.
- `Notebook` — `id`, `name`, `parentID`, `colorName`, `sortIndex`,
  `createdAt`, `updatedAt`, plus `isTopLevel` and a sibling ordering.

### Notes

- **`parentID` ships with the first notebook release, not later.** The
  `.notes.folder` schema requires nesting, and adding the field afterwards
  would be a breaking change to a type two repositories store.
- `colorName` is a palette name (`"riverbank"`), never a colour value. The
  domain stays free of anything platform-specific, and the palette can change
  without a migration.

## [0.1.0] — wave 0 · walking skeleton

The first release. Enough of a note to prove the pipeline end to end, and
nothing more.

### Added

- `NoteID` — client-generated `UUID` wrapper. Identity never comes from the
  database, which is what lets two offline devices create notes without
  colliding.
- `Note` — `id`, `title`, `body`, `createdAt`, `updatedAt`, plus `isEmpty`.
- `NoteDraft` — `title`, `body`. Writes are described, not mutated.

### Notes

- `title` and `body` are `String` in this release only. They become
  `AttributedString` in 0.4.0, which the `.notes.note` schema requires.
- Zero package dependencies, and no import beyond `Foundation`.
