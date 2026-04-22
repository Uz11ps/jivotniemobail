# Figma → Xcode asset manifest

Maps each Figma source node to the `Assets.xcassets` slot it should land in.
Path conventions use the worktree-relative Xcode asset path:
`ios/DetiZhivotnieApp/Resources/Assets.xcassets/<slot>`.

**Figma file:** `VcYnAfAMMhLuhxOyzTg162`
**How to export manually (until MCP-driven export is stable):**
1. Open the node in Figma Desktop.
2. Select it → right panel "Export" → add PNG @1x, @2x, @3x (or SVG for flat icons).
3. Drop the three PNG files into the matching `<slot>.imageset/` directory.
   Name them `<slot>.png`, `<slot>@2x.png`, `<slot>@3x.png`.
4. Asset catalog is pre-configured to pick them up by scale.

---

## Screen backgrounds / heroes

| Slot | Figma node | Kind | Notes |
|---|---|---|---|
| `splash_animals.imageset` | `1:6669` | PNG 3x (vertical 1170×2532) | Looping video preferred; see `splash_animals.mp4` below for the video alt. |
| `hero_pets.imageset`   | `1:6655` (Pets Category Video) | PNG 3x (~1170×657) | Or category MP4; placed into `CategoryHero`. |
| `hero_farm.imageset`   | Figma: section `2.Cabinet`, "Farm" preview | PNG 3x | Per-category hero illustration. |
| `hero_forest.imageset` | `1:6762` (Forest locked preview) | PNG 3x | Forest 3D illustration used as hero. |
| `hero_sea.imageset`    | *TBD in Figma (sea/ocean category)* | PNG 3x | Fill in once a sea category asset is finalised. |

## Purchase / paywall

| Slot | Figma node | Kind | Notes |
|---|---|---|---|
| `special_offer_logo.imageset`  | Special-offer bubble art inside `1:7006` | PNG 3x, transparent bg | The multicolor "SPECIAL OFFER" bubble lettering. |
| `special_offer_heads.imageset` | Goose/tiger/dolphin trio inside `1:7006` | PNG 3x, transparent bg | Hero row in `SpecialOfferView`. |
| `purchases_empty_tiger.imageset` | Tiger centerpiece inside `1:7571` (Newbie purchases) | PNG 3x, transparent bg | Newbie empty state. |

## Error states

| Slot | Figma node | Kind | Notes |
|---|---|---|---|
| `error_mouse.imageset` | Generic error illustration inside `1:7192` | PNG 3x, transparent bg | Mouse with glasses at laptop. |
| `error_bird.imageset`  | Offline bird inside `1:7192` | PNG 3x, transparent bg | Yellow bird with wifi-off overlay. |

---

## Videos (outside xcassets)

Drop these directly into `ios/DetiZhivotnieApp/Resources/`:

| Filename | Figma source | Notes |
|---|---|---|
| `splash_animals.mp4` | `1:6669` | Looping collage of bear/cow/bird/tiger/cat/rooster. Muted autoplay. |

`SplashView` already tries `Bundle.main.url(forResource: "splash_animals", withExtension: "mp4")` and falls back to the imageset or an SF Symbol if neither is present.

---

## AppIcon

`Assets.xcassets/AppIcon.appiconset/` is pre-created. Drop a 1024×1024 PNG
named `AppIcon.png` inside. Xcode will also accept multi-size sets; this
single-slot form works for iOS 14+.

## Colors (already in code)

All colours live in `Sources/DesignSystem/Colors.swift` via `DS.Color.*`
tokens. No need to duplicate them into `.colorset` folders — keep SwiftUI
views tied to tokens so Figma changes propagate through one edit.

---

## MCP-driven export (when Figma MCP is stable)

Running `get_design_context` with `dirForAssetWrites=docs/figma-assets/<slot>/`
will drop images there. The MCP tends to disconnect on large frames — prefer
*narrow* nodes (the specific illustration frame, not the whole screen).

Known working pattern: call on the smallest enclosing frame that contains
only the vector/raster of interest.
