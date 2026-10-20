# MassMates — Visual Identity

*Modern, minimal, calm. A quiet space for shared devotion. Written for designers and AI coding agents: every value here is a token to implement, not a suggestion to reinterpret.*

---

## 1. Principles

1. **Quiet first.** Whitespace is part of the prayer. If a screen feels busy, remove something before adding something.
2. **Sacred text gets a serif; everything else stays out of its way.** Scripture and liturgy are set like a book. Controls are set like an app.
3. **The season whispers.** The liturgical color is a small tint on a neutral app, never a theme takeover.
4. **Encouragement, not pressure.** Visuals for streaks and rankings are soft and warm. No red alerts, no guilt.
5. **Ads are guests.** Sponsored content follows the same quiet system and is always clearly labeled.

---

## 2. Color

### 2.1 Neutrals (always present)

| Token | Light | Dark | Use |
| :-- | :-- | :-- | :-- |
| `bg` | `#FAF8F5` | `#121110` | App background (warm off-white / warm near-black) |
| `surface` | `#FFFFFF` | `#1B1A18` | Cards, sheets |
| `surfaceMuted` | `#F2EFEA` | `#242220` | Inputs, chips, quiet fills |
| `line` | `#E7E3DC` | `#33302C` | Hairline dividers, card borders |
| `textPrimary` | `#1C1B19` | `#F3F0EA` | Body, headings |
| `textSecondary` | `#6B665E` | `#A9A39A` | Captions, metadata |
| `textTertiary` | `#9A948A` | `#7A746B` | Placeholders (never for essential info) |

### 2.2 Liturgical tint (one active at a time)

The tint is used **only** for: the Today header accent, the streak ring, the primary button, the selected tab icon, progress bars, and small highlights. It is never a full-screen background.

| Season token | Light `tint` | Dark `tint` | `tintSoft` (10–14% wash, light / dark) | Typical days |
| :-- | :-- | :-- | :-- | :-- |
| `green` | `#4C7A5B` | `#7FB08E` | `#E9F1EB` / `#1C2A20` | Ordinary Time |
| `purple` | `#6A4C8C` | `#B49AD6` | `#EFEAF4` / `#262034` | Advent, Lent |
| `white` | `#9C8247` | `#D2B976` | `#F4EFE2` / `#2C2719` | Christmas, Easter, feasts of the Lord and Mary |
| `red` | `#A33F43` | `#E08A8D` | `#F5E9E9` / `#321D1E` | Pentecost, martyrs, Palm Sunday, Good Friday |
| `rose` | `#C2677F` | `#E7A0B3` | `#F7ECEF` / `#331F26` | Gaudete, Laetare (twice a year) |

Rules:
- `white` season uses a muted gold so it remains visible on a light background. Never use pure white as a tint.
- Text on a filled `tint` button uses `onTint`: `#FFFFFF` in light mode, `#121110` in dark mode. Verify contrast ≥ 4.5:1 in a unit test; adjust the tint if a pair fails.
- Tint transitions between seasons animate over 400 ms (disabled with Reduce Motion).
- Season is never the *only* signal: always pair color with the season name label ("Lent", "Easter Time").

### 2.3 Functional colors

| Token | Light | Dark | Use |
| :-- | :-- | :-- | :-- |
| `success` | `#3F7D58` | `#7CC096` | Check-in completed |
| `warning` | `#B7791F` | `#E3B25A` | Gentle nudges |
| `danger` | `#B3382E` | `#E5857D` | Destructive actions only (delete account, leave group) |
| `sponsored` | `#6B665E` | `#A9A39A` | "Patrocinado" label text on native ads |

---

## 3. Typography

**Pairing:** serif for liturgy and Scripture, sans for UI.

| Role | Family | Notes |
| :-- | :-- | :-- |
| Sacred text (readings, psalm, Gospel, prayers, fruit-of-prayer quotes) | **New York** (system serif, `.design(.serif)`) | Free, ships with iOS, supports Dynamic Type. Optional upgrade: *Source Serif 4* (OFL) |
| Display headings on Today and onboarding | New York, Semibold | Sparingly: one per screen |
| UI (navigation, buttons, lists, chat, metadata) | **SF Pro** (system) | Default `.body`, `.headline` styles |
| Numerals (streak, counters) | SF Pro Rounded, Medium | Soft, friendly figures |

### Type scale (all via Dynamic Type; sizes are the default category)

| Token | Font | Size / Line | Weight | Use |
| :-- | :-- | :-- | :-- | :-- |
| `display` | New York | 34 / 40 | Semibold | Onboarding titles, season name |
| `title` | SF Pro | 24 / 30 | Semibold | Screen titles |
| `headline` | SF Pro | 17 / 22 | Semibold | Card titles, group names |
| `body` | SF Pro | 17 / 24 | Regular | General text, chat |
| `scripture` | New York | 19 / 30 | Regular | Readings and prayers (generous leading, max measure ≈ 60 characters) |
| `scriptureEmphasis` | New York Italic | 19 / 30 | Regular | Psalm refrain, quotes |
| `callout` | SF Pro | 15 / 20 | Regular | Secondary info |
| `caption` | SF Pro | 12 / 16 | Medium | Metadata, labels |
| `numeral` | SF Pro Rounded | 28 / 32 | Medium | Streak count, goal progress |

Rules: support up to AX5 Dynamic Type; never truncate Scripture; left-aligned, never justified; no all-caps except tiny `caption` labels with +4% tracking.

---

## 4. Layout, Shape & Elevation

- **Grid:** 4 pt base. Spacing tokens: `4, 8, 12, 16, 24, 32, 48`.
- **Screen margins:** 20 pt horizontal. Reading screens (Gospel, Timer): 24 pt and max content width 560 pt on iPad.
- **Radius:** cards `16`, buttons `14`, chips `999` (pill), sheets `24` top corners, avatars full circle.
- **Elevation:** prefer **borders over shadows**. Cards: `surface` + 1 pt `line` border. Only floating elements (the `+` check-in button, toasts) get a shadow: `0 6 20 rgba(0,0,0,0.10)` light, none in dark (use a lighter surface instead).
- **Density:** generous. Minimum row height 56 pt; minimum tap target 44×44 pt.
- **Dividers:** hairlines only, inset to the text edge.

---

## 5. Iconography & Imagery

- **Icons:** SF Symbols, *regular* weight, monochrome, `textSecondary` by default and `tint` when selected. Keep a custom set only for things SF Symbols lacks (rosary, chalice, monstrance), drawn on a 24 pt grid with a 1.75 pt stroke and rounded caps to match.
- **Practice icons:** one consistent line style for the eight practices (Rosary, Mass, Gospel, Adoration, Mental Prayer, Spiritual Reading, Fasting, Confession). Confession carries a small lock badge to signal "private".
- **Photography (check-in proof):** shown in rounded rectangles (radius 12), no filters, no overlay text. Strip EXIF before upload.
- **Illustration:** minimal line illustrations at 1.5 pt, one color (`textSecondary`) plus `tintSoft` fill, used only in empty states and onboarding.
- **No stock religious imagery** in UI chrome. Sacred art may appear only in content (e.g., saint of the day), with proper licensing.

---

## 6. Components

| Component | Spec |
| :-- | :-- |
| **Primary button** | Filled `tint`, `onTint` text, radius 14, height 52, `headline` label, full width in modals |
| **Secondary button** | `surfaceMuted` fill, `textPrimary` label |
| **Text button** | `tint` label, no fill |
| **Card** | `surface`, 1 pt `line` border, radius 16, padding 16 |
| **Today header** | `bg` with a `tintSoft` wash fading to `bg`; season name in `display`, saint of the day in `callout`; streak ring in `tint` |
| **Streak ring** | 2.5 pt stroke, `tint` on `line` track, `numeral` in the center. Missed day = ring stays quiet, no red |
| **Check-in card (Feed)** | Avatar, name, practice icon + label, optional photo, "fruit of prayer" in `scriptureEmphasis`, reaction row (Amen, United in Prayer) |
| **Reaction button** | Pill, `surfaceMuted`; active = `tintSoft` fill + `tint` icon |
| **Progress bar** | 8 pt height, pill, `tint` on `surfaceMuted` |
| **Tab bar** | System tab bar, selected `tint`, central `+` is a floating 56 pt circle with `tint` fill |
| **Chips (practices)** | Pill, `surfaceMuted`; selected = `tintSoft` + 1 pt `tint` border |
| **Toast** | `surface`, radius 14, floating shadow, auto-dismiss 3 s |
| **Empty state** | Line illustration + `headline` + one-sentence `callout` + one text or secondary button |

### Scripture / reading screen
Background `bg`, 24 pt margins, `scripture` style, 1 pt-thick `tint` rule above the reading title, reading reference in `caption` `textSecondary`. **No ads, no banners, no tinted washes** here or on the Prayer Timer.

### Prayer Timer
Centered circular progress in `tint` (thin 4 pt stroke), time in `numeral` at 56 pt, nothing else on screen. Dark mode default suggestion for evening use.

---

## 7. Ads (visual rules)

- **Native ads** reuse the Card spec exactly, plus a `caption` label "Patrocinado" in `sponsored` color at top-left of the card and a subtle `surfaceMuted` background to separate from check-ins.
- **Banner (320×50)** sits on `surfaceMuted` with a 1 pt top `line`, never overlapping content or the tab bar.
- **Interstitial and rewarded** are provider-rendered; our wrapper screens (reward intro, "thanks" confirmation) follow Primary button and Card specs.
- **Direct sponsorships** use the same Card with a partner logo slot (max height 28 pt) and the "Patrocinado" label.
- Never use `tint` to make an ad look like content, and never place an ad adjacent to Confession entries.

---

## 8. Motion

| Moment | Motion | Duration / curve |
| :-- | :-- | :-- |
| Screen transitions | Native `NavigationStack` push / sheet | System |
| Season tint change | Cross-fade | 400 ms ease-in-out |
| Check-in success | Streak ring fills + soft checkmark | 600 ms spring (damping 0.85) |
| Goal reached | Gentle radial glow in `tintSoft`, no confetti | 900 ms |
| Reaction tap | Scale 1.0 → 1.08 → 1.0 | 200 ms |
| Skeleton loaders | Slow shimmer on `surfaceMuted` | 1.4 s loop |

All motion respects **Reduce Motion** (replace with cross-fade or instant). Haptics: light impact on check-in, soft on reactions; none on timer ticks.

---

## 9. Voice & Microcopy (visual-adjacent)

- Calm, warm, brief. Portuguese (pt-BR) first, informal-respectful.
- Streak language: encouraging ("Mais um dia em oração"), never punishing. Missed days: "Recomece hoje, com leveza."
- Use sentence case everywhere. No exclamation marks in sacred contexts (Gospel, Timer, Intentions).

---

## 10. Accessibility

- Contrast ≥ 4.5:1 for text, ≥ 3:1 for icons and the tint on non-text UI.
- Support Dynamic Type through AX5, Bold Text, Increase Contrast (swap `line` and `tint` to higher-contrast variants), Reduce Motion, and VoiceOver (label every icon-only control).
- Color is never the only carrier of meaning (season name, state labels, icons).
- Tap targets ≥ 44×44 pt.

---

## 11. App Icon & Brand Mark (placeholder direction)

*To be refined; see open questions.*

- **Concept:** a simple, abstract mark in a single color on a warm off-white tile; light and dark variants.
- **Default tile:** `bg` (`#FAF8F5`) with a `tint`-colored mark, using Ordinary Time green as the default.
- **Alternate icons** (Settings, rewarded unlock): one per season, same mark, tile color swapped to the season `tint`.
- **Wordmark:** "MassMates" in New York Semibold, tight tracking (−1%), sentence-case "M" capitals as written.

---

## 12. Implementation Notes (SwiftUI)

```swift
// Core/DesignSystem/Theme.swift
enum LiturgicalColor: String, CaseIterable { case green, purple, white, red, rose }

struct Theme {
    let season: LiturgicalColor
    var tint: Color        // from asset catalog: "tint/<season>"
    var tintSoft: Color    // from asset catalog: "tintSoft/<season>"
    var onTint: Color
}

extension Font {
    static let scripture = Font.system(size: 19, design: .serif)
    static let numeral   = Font.system(size: 28, weight: .medium, design: .rounded)
}
```

**Agent rules**
1. Never hard-code hex values in views; use tokens from `Core/DesignSystem`.
2. Every season color pair has a unit test for contrast against `bg`, `surface` and `onTint`.
3. Every component has a `#Preview` showing all five seasons in light, dark and AX3 Dynamic Type.
4. Ad views are built only from design-system components; never style them ad hoc.
5. If a screen needs a value not in this file, add the token here first, then use it.

---

## 13. Do / Don't

| Do | Don't |
| :-- | :-- |
| Let whitespace separate sections | Add dividers and boxes everywhere |
| Use the tint on 1–3 elements per screen | Fill backgrounds with the season color |
| Set Scripture in the serif at comfortable size | Mix fonts inside a reading |
| Use soft encouragement for streaks | Use red or warning styling for missed days |
| Label ads clearly | Blend ads into check-in cards |
