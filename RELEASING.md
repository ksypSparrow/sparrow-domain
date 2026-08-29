# Releasing SparrowDomain

This package is the root of the diamond. Nothing upstream ever blocks a release
here — and every release forces a coordinated bump in **both** middle layers.

## Before you tag

**Design the whole wave in the workspace first.** With all four packages local
in `Sparrow.xcworkspace`, iterate until the interfaces are right. Tagging a
type you have not yet called from `sparrow-kit` is how a four-step train
becomes a four-step retreat.

## The ritual

```
   1  swift test — green
   2  CHANGELOG.md entry naming the wave
   3  git tag vX.Y.Z && git push --tags
   4  notify: sparrow-cold-storage, sparrow-kit
```

## Gate for every release

```
   ✓  swift build && swift test
   ✓  swift build -Xswiftc -strict-concurrency=complete
   ✓  xcodebuild -scheme SparrowDomain -destination 'generic/platform=iOS'
   ✓  zero .package(...) entries in Package.swift
   ✓  no import beyond Foundation anywhere in Sources/
```

The last two are the ones that matter. They are what keeps this package
buildable on Linux for the V2 server.

## Version policy

| Stage | Breaking | Additive | Fix |
|---|---|---|---|
| `0.x` — during the build | **minor** | minor | patch |
| `1.x` — after release | major | minor | patch |

**Never re-tag.** SwiftPM caches by tag; a moved tag builds differently on
different machines.

## Downstream

```
   sparrow-domain vX.Y.Z tagged
        │
        ├──► sparrow-cold-storage   bump · resolve · implement · tag
        └──► sparrow-kit            bump · resolve · implement · tag
                                    (only after cold-storage tags)
```

Bump both dependents in the same session. The window where `cold-storage` sits
on domain 0.4.0 while `kit` is still on 0.3.0 is the window where resolution
fails, or something compiles against a combination nobody tested.
