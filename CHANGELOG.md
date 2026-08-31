# Changelog

All notable changes to `SparrowDomain`. This package sits at the root of the
dependency diamond — every release here starts a wave of the release train.

Pre-1.0, **the minor is the breaking bump**. Dependents pin with
`.upToNextMinor(from:)`.

## [Unreleased]

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
