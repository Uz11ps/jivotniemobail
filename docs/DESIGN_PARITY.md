# Design Parity — Figma → iOS (1:1)

**Figma source of truth:** https://www.figma.com/design/VcYnAfAMMhLuhxOyzTg162/Untitled
**Target platform:** iOS / SwiftUI (`ios/DetiZhivotnieApp/`)
**Design system location:** `ios/DetiZhivotnieApp/Sources/DesignSystem/`

---

## Design system status

| Token group | Status | File |
|---|---|---|
| Color palettes (Neutral + 7 hues × 10 shades) | ✅ Done | `DesignSystem/Colors.swift` |
| Semantic colors (Fill, Label, Icon, Button, Background, Category…) | ✅ Done | `DesignSystem/Colors.swift` |
| Typography (22 styles, SF Pro Rounded) | ✅ Done | `DesignSystem/Typography.swift` |
| Spacing / gaps (12 tokens: 2–56pt) | ✅ Done | `DesignSystem/Spacing.swift` |
| Corner radii (9 tokens) | ✅ Done | `DesignSystem/Radius.swift` |
| Icon sizes (S/M/L/XL) | ✅ Done | `DesignSystem/Radius.swift` |
| Assets (illustrations, icons, SVGs) | ⬜ TODO | `Assets.xcassets/` |
| SF Pro Rounded rendering | ✅ Native via `.fontDesign(.rounded)` | no bundling |

---

## Figma sections → iOS screens

Status legend: ⬜ not started · 🟡 in progress · ✅ pixel-perfect

### Design system (reference only — not implemented as screens)
- `[Atoms] Main page` (0:335)
- `[Atoms] Neutrals` (0:664)
- `[Molecules] Main page` ×2 (0:1303, 0:1528)
- `[Molecules] Neutrals` (0:1573)
- `[Organisms] Main page` (0:1788)
- `[Organisms] Parent cabinet` (0:1951)
- `[Organisms] Neutral components` (0:1761)
- `Tokens` (0:2137) — extracted into code

### Main flow
| # | Figma section | Node ID | iOS file (target) | Status |
|---|---|---|---|---|
| 1 | 0. Main flow (Splash → Notifications → Main → Animal card) | `1:6649` | `OnboardingView.swift`, `SplashView.swift` (new) | ⬜ |
| 2 | 1. Buy categories | `1:6753` | `PurchaseView.swift` | ⬜ |
| 3 | 1.1 Categories content | `1:8009` | `CategoryGridView.swift`, `AnimalDetailView.swift` | ⬜ |

### Cabinet (Parent settings)
| # | Figma section | Node ID | iOS file (target) | Status |
|---|---|---|---|---|
| 4 | 2. Cabinet (root) | `1:7067` | `ProfileView.swift` | ⬜ |
| 5 | 2.1.1 Favorite categories & animals, newbie state | `1:7213` | `ProfileView.swift` (empty state) | ⬜ |
| 6 | 2.1.2 Buy button | `1:7820` | `ProfileView.swift` (CTA) | ⬜ |
| 7 | 2.1.3 After using categories | `1:7889` | `ProfileView.swift` (populated state) | ⬜ |
| 8 | 2.2.1 Sections sequence | `1:7304` | `CategoryOrderView.swift` | ⬜ |
| 9 | 2.3.1 Language | `1:7487` | `LanguagePickerView.swift` | ⬜ |
| 10 | 2.4.1 My purchases. Newbie user | `1:7571` | `PurchasesView.swift` (empty) | ⬜ |
| 11 | 2.4.2 My purchases. Profi user | `1:7707` | `PurchasesView.swift` (populated) | ⬜ |
| 12 | 2.5.1 Rate app | `1:7638` | `RateAppView.swift` (new) | ⬜ |

### Error states
| # | Figma section | Node ID | iOS file (target) | Status |
|---|---|---|---|---|
| 13 | 3. Error states | `1:7192` | `ErrorView.swift` (new) | ⬜ |

---

## Process per screen

1. `get_screenshot` on the section node → save under `docs/figma/<nodeId>.png`
2. `get_design_context` on the specific screen frame → reference code + metadata
3. Identify which existing SwiftUI view maps to it (or mark "needs new file")
4. Rewrite the view using `DS.Color.*`, `DS.Font.*`, `DS.Gap.*`, `DS.Radius.*`
5. Run in Simulator (iPhone 15, iOS 17) → screenshot
6. Side-by-side vs Figma → log deltas → iterate until ✅

## Known gaps before we start refactoring screens

- [x] SF Pro Rounded — using native `Font.system(..., design: .rounded)`, no bundling needed.
- [ ] `Assets.xcassets` doesn't exist yet — illustrations (animals, backgrounds) must be exported from Figma at @1x/@2x/@3x.
- [ ] `AssetService` currently loads backgrounds dynamically from Firebase Storage — OK for production animals/categories, but onboarding/splash illustrations should be bundled.
- [ ] Emoji placeholders (🐾, 🎵, 🚀) need to be replaced with real assets or SF Symbols per design.

---

_Generated 2026-04-22 via Figma Dev Mode MCP._
