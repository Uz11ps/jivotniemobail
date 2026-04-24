# Xcode setup

The iOS project is **generated** by [xcodegen](https://github.com/yonaskolb/XcodeGen)
from [`ios/project.yml`](project.yml). Don't hand-edit the `.xcodeproj` —
tweak the YAML and regenerate.

## Prerequisites

- Xcode 15+ (Swift 5.9, iOS 16 deployment target)
- xcodegen: `brew install xcodegen`

## First build

```bash
cd ios
xcodegen generate             # produces DetiZhivotnieApp.xcodeproj
open DetiZhivotnieApp.xcodeproj
```

Xcode will resolve Firebase + Lottie Swift packages on first build
(~1–3 min on a fresh machine). Then ⌘R on any iPhone simulator
(iPhone 15 recommended — matches the Figma 390×844 frames).

## Firebase configuration

You need `GoogleService-Info.plist` for a live backend. A template is at
[`ios/GoogleService-Info.plist.example`](GoogleService-Info.plist.example).
Copy it to `ios/DetiZhivotnieApp/GoogleService-Info.plist` (gitignored)
with real values from the Firebase console. Without it, Firebase calls
fail silently and the category list will be empty — the UI still renders
with SF Symbol fallbacks.

## After structural changes

If you **add or remove a source folder**, regenerate:

```bash
cd ios && xcodegen generate
```

Xcode picks up the new project on next focus. You do **not** need to
regenerate when adding/removing files inside existing folders — the
YAML references folders, not individual files.

## Assets.xcassets

Location: [`ios/DetiZhivotnieApp/Resources/Assets.xcassets/`](DetiZhivotnieApp/Resources/Assets.xcassets).

Every slot is pre-created with a valid `Contents.json`. Dropping PNGs
(`splash_animals.imageset/splash_animals@2x.png`, etc.) makes them
appear automatically — the views already use `UIImage(named:)` checks
and fall back to SF Symbols when the slot is empty.

See [`docs/figma-assets/MANIFEST.md`](../docs/figma-assets/MANIFEST.md)
for the Figma-node → asset-slot mapping.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Cannot find 'Lottie' in scope` or `No such module 'FirebaseFirestore'` | Let package resolution finish. If stuck: *File → Packages → Reset Package Caches*, then ⌘B. |
| App crashes on launch with a Firebase error | Missing `GoogleService-Info.plist`. See Firebase section above. |
| `.pbxproj` merge conflicts after rebase | `cd ios && xcodegen generate` and stage the regenerated file. |
| Info.plist "Multiple commands produce" | You've added a custom Info.plist to the target while `GENERATE_INFOPLIST_FILE` stayed on. The YAML sets it to `NO` and points at the checked-in plist — regenerate. |

## Why xcodegen?

Raw `.pbxproj` XML conflicts on every PR and drifts between developers.
`project.yml` is ~50 lines of YAML that always produces the same project,
so diffs are small and reviewable. The `.xcodeproj` lives in git (commits
cheaply; xcodegen output is deterministic) but is treated as generated:
edit the YAML, regenerate, commit both.

