# Xcode setup

This repo ships the iOS source as a **Swift Package** (`ios/Package.swift`).
There is no checked-in `.xcodeproj` — it lives only on each developer's
machine, and it's `.gitignore`'d. You create it once, locally.

Two options, pick one.

---

## Option A — fastest: new Xcode iOS App that depends on the package

Recommended when you want a real iOS App target (Info.plist, entitlements,
AppIcon, IAP, push notifications, etc.).

1. **Open Xcode** → `File → New → Project…`
   • iOS → **App** → Next
   • Product Name: `DetiZhivotnieApp`
   • Team: *your team*
   • Interface: **SwiftUI**, Language: **Swift**, Storage: **None**
   • Include Tests: optional
   • Save at `ios/App/` (next to `Package.swift`).

2. **Delete Xcode's generated files** inside the new project:
   • `ContentView.swift`
   • `DetiZhivotnieAppApp.swift`
   • `Assets.xcassets`
   (The real copies live in `ios/DetiZhivotnieApp/`.)

3. **Add our existing sources** — drag these folders from Finder into the
   new Xcode project navigator (choose *Create groups*, check the app
   target):
   • `ios/DetiZhivotnieApp/DetiZhivotnieAppApp.swift`
   • `ios/DetiZhivotnieApp/ContentView.swift`
   • `ios/DetiZhivotnieApp/Sources/` (whole tree)
   • `ios/DetiZhivotnieApp/Resources/Assets.xcassets`

4. **Replace generated Info.plist** with `ios/DetiZhivotnieApp/Info.plist`.

5. **Add Swift Package dependencies** (`File → Add Package Dependencies…`):
   • `https://github.com/firebase/firebase-ios-sdk` — pick
     `FirebaseFirestore`, `FirebaseStorage`, `FirebaseAuth`,
     `FirebaseAnalytics`, `FirebaseFunctions`
   • `https://github.com/airbnb/lottie-ios` — pick `Lottie`

6. **Firebase config**: copy `ios/GoogleService-Info.plist.example` →
   `ios/App/DetiZhivotnieApp/GoogleService-Info.plist` and paste real
   values (App Store Connect / Firebase console). Add the file to the app
   target (target membership checked).

7. **Capabilities**:
   • In-App Purchase — on.
   • Push Notifications — on if you ship remote notifications.

8. **Deployment target** — iOS 16.0 (matches `Package.swift`).

9. **Build & run** (⌘R) on any iPhone simulator (e.g. iPhone 15).

Everything under `ios/DetiZhivotnieApp/Sources/**` is already structured
per feature folder and uses the DS tokens in `Sources/DesignSystem/`.

---

## Option B — SwiftPM-only (browse, no run)

Useful for a quick code review:

```bash
open ios/Package.swift
```

Xcode opens the package in a workspace. You can browse, build the library,
and run Previews on individual SwiftUI views (`#Preview {}` blocks). You
can't `⌘R` into the simulator because there's no app target here.

---

## Why isn't the .xcodeproj checked in?

Historic reasons + repo-level `.gitignore` (`xcuserdata/`, `*.xcworkspace`,
etc.). Check with the team before committing one — prefer XcodeGen or a
template rather than a raw `project.pbxproj` if you want future diff
friendliness.
