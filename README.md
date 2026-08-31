# SparrowDomain

The vocabulary of Sparrow FieldNotes: value types shared by every layer.

**Imports `Foundation` and nothing else.** No GRDB, no AppIntents, no SwiftUI,
no package dependencies — which is why it compiles on Linux for the V2 server,
and why it can sit under both `sparrow-cold-storage` and `sparrow-kit` without
creating a cycle.

```
                    ┌──────────────────┐
                    │   sparrow-app    │
                    └────────┬─────────┘
                             ▼
                    ┌──────────────────┐
                    │   sparrow-kit    │
                    └────────┬─────────┘
                             ▼
              ┌──────────────────────────┐
              │  sparrow-cold-storage    │
              └────────────┬─────────────┘
                           ▼
              ┌──────────────────────────┐
              │  sparrow-domain   ◄── you are here
              └──────────────────────────┘
```

## Contents

| Type | Since |
|---|---|
| `NoteID` · `Note` · `NoteDraft` | 0.1.0 |
| `NotebookID` · `Notebook` | 0.2.0 |
| `NotebookDraft` · `NotebookEdit` | 0.3.0 |

## Rules

| | |
|---|---|
| Dependencies | **None. Ever.** |
| Every type | `Sendable`, `Hashable`, `Codable` where it crosses the wire |
| Identifiers | Typed, never bare `UUID` — client-generated, never from the DB |
| Additive by default | A new optional field is cheap; a rename is a wave |

## Build

```bash
swift build && swift test
```

Requires a Swift 6.4 toolchain — the `.iOS(.v27)` platform floor is only
available from `swift-tools-version: 6.4`.

## Documents

Design lives with the lab: `01-Sparrow-FieldNotes/` —
[`contracts.md`](../01-Sparrow-FieldNotes/contracts.md) for the full type
surface, [`plans/sparrow-domain.md`](../01-Sparrow-FieldNotes/plans/sparrow-domain.md)
for the release plan, [`RELEASING.md`](RELEASING.md) for the ritual.
