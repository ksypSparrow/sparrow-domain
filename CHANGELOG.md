# Changelog

All notable changes to `SparrowDomain`. This package sits at the root of the
dependency diamond — every release here starts a wave of the release train.

Pre-1.0, **the minor is the breaking bump**. Dependents pin with
`.upToNextMinor(from:)`.

## [Unreleased]

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
