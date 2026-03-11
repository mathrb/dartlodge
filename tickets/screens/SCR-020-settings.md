# SCR-020 — Settings Page

**Route:** `/settings`
**File:** `lib/features/settings/presentation/pages/settings_page.dart`

---

## Design Principles

- **P4 — Clean form layout, no decoration:** Section headers and rows provide all necessary structure. No card containers, no borders, no visual noise.

---

## Layout Anatomy

```
┌─────────────────────────────┐
│  AppBar: "Settings"      ←  │
├─────────────────────────────┤
│                             │
│  THEME                      │  ← section header
│  ─────────────────────────  │  ← implicit — no visual divider needed
│  System default     [●]     │  ← row: label left, toggle right (default ON)
│  Dark Mode          [ ]     │  ← row: label left, toggle right (default OFF)
│                             │
│  ABOUT                      │  ← section header
│  ─────────────────────────  │
│  Version              1.0.0 │  ← row: label left, value right (not tappable)
│  Open Source Licenses   →   │  ← row: tappable, trailing chevron
│                             │
└─────────────────────────────┘
```

**Zone descriptions:**

- **AppBar:** Back arrow returns to Home. Title "Settings". No overflow menu.
- **THEME section:** Section header label, then two setting rows. "System default" toggles `ThemeMode.system` (follows device dark/light mode setting). "Dark Mode" toggles `ThemeMode.dark` (always dark regardless of device setting). Only one can be active at a time — these behave as a pair of radio options, but implemented as toggle switches for visual consistency.
- **ABOUT section:** Section header label, then two rows. "Version" shows the app version string (read-only, not tappable). "Open Source Licenses" is tappable and opens the Flutter `LicensePage`.

---

## Typography

| Element | Token | Color |
|---|---|---|
| AppBar title "Settings" | `textHeadingMedium` (DM Sans SemiBold 20sp) | `colorOnBackground` |
| Section header (THEME, ABOUT) | `textLabelMedium` (DM Sans Medium 12sp, ALL CAPS) | `colorOnSurfaceVariant` |
| Setting row label | `textBodyLarge` (DM Sans Regular 16sp) | `colorOnBackground` |
| Setting row description / value | `textBodySmall` (DM Sans Regular 12sp) | `colorOnSurfaceVariant` |
| "Open Source Licenses" trailing chevron | — | `colorOnSurfaceVariant` |
| Version value | `textBodySmall` | `colorOnSurfaceVariant` |

---

## Colors

| Element | Token |
|---|---|
| Screen background | `colorBackground` |
| Section header text | `colorOnSurfaceVariant` |
| Section header background | `colorBackground` (no distinct background — just padding) |
| Setting row background | `colorBackground` |
| Row bottom divider | none (spacing only) |
| Toggle switch active track | `colorPrimary` |
| Toggle switch inactive track | `colorOutlineVariant` |
| Toggle switch thumb | `colorOnPrimary` (active) / `colorOnSurfaceVariant` (inactive) |
| Trailing chevron | `colorOnSurfaceVariant` |

---

## Section Header Styling

Each section header is a label with:
- Top padding: `space6` (24dp) from the previous section or AppBar.
- Bottom padding: `space1` (4dp) before the first row.
- Horizontal padding: `space4` (16dp).
- No background, no border, no separator line.
- Text: `textLabelMedium colorOnSurfaceVariant`, ALL CAPS.

---

## Setting Row Styling

Each setting row:
- Minimum height: 56dp.
- Horizontal padding: `space4` (16dp).
- Vertical padding: `space3` (12dp) top and bottom.
- Layout: label text left-aligned and vertically centered; control or value right-aligned.
- No divider lines between rows within a section.
- No card or border on individual rows.

---

## THEME Section Behavior

**Implementation note:** The app supports three `ThemeMode` values:
- `ThemeMode.system` — follows device dark/light mode preference (default).
- `ThemeMode.light` — always light.
- `ThemeMode.dark` — always dark.

**Presented to the user as:**
- "System default" toggle: when ON, `ThemeMode.system` is active. Toggling OFF switches to the last manual selection.
- "Dark Mode" toggle: when ON, `ThemeMode.dark` is active. When OFF, `ThemeMode.light` is active (if "System default" is also OFF).

**Mutual exclusion rule:**
- When "System default" is turned ON: "Dark Mode" toggle is disabled (grayed at 38% opacity, with Tooltip "Using system setting").
- When "System default" is turned OFF: "Dark Mode" toggle becomes active. The user can then toggle dark mode on or off independently.
- Default state on first launch: "System default" is ON; "Dark Mode" is disabled.

**Toggle switch tap targets:**
- Minimum 48×48dp tap target centered on the switch widget.
- The entire row is tappable (not just the switch) — tapping anywhere on the row toggles the switch.

---

## ABOUT Section

**Version row:**
- Label: "Version"
- Value: app version string read from package metadata at runtime (e.g. "1.0.0+42" or just "1.0.0"). `textBodySmall colorOnSurfaceVariant`, right-aligned.
- Not tappable. No ripple.

**Open Source Licenses row:**
- Label: "Open Source Licenses"
- Trailing: chevron icon `colorOnSurfaceVariant`
- Tappable — minimum 56dp height; ripple `colorOnSurface` at 12% opacity.
- Tap navigates to the Flutter built-in `LicensePage` (standard system page).

---

## Interactions

- **"System default" row:** Full-row tap target toggles the "System default" switch. If turning ON: restores `ThemeMode.system` and disables "Dark Mode" row. If turning OFF: enables "Dark Mode" row; switches to `ThemeMode.light` by default (user then uses "Dark Mode" toggle to go dark).
- **"Dark Mode" row:** Full-row tap target toggles dark/light mode (only active when "System default" is OFF). Disabled (38% opacity, no ripple) when "System default" is ON.
- **"Version" row:** No tap handler. No ripple.
- **"Open Source Licenses" row:** Tap opens `LicensePage`. This is a system page — no custom design required.
- **Back button:** Returns to Home.

---

## Edge Cases

- **No loading or async state:** All theme preferences are synchronous (stored in shared preferences or similar; reads are synchronous at app start). The page renders immediately.
- **Version string unavailable:** If the package metadata cannot be read, show "—" as the version value.
- **Theme persistence:** The selected `ThemeMode` must persist across app restarts. Stored in shared preferences or equivalent local storage.

---

## Special Notes

- **Accessed exclusively via gear icon (⚙) on Home page.** Not linked from any other screen.
- **No data persistence settings, no account settings, no backend configuration** at this stage of the product. The Settings page is intentionally minimal.
- **ThemeMode.system as default:** The app ships with `ThemeMode.system` as the default — it respects the user's device dark/light mode setting out of the box.
- **Row height:** 56dp minimum (larger than the 48dp minimum tap target — the extra height provides visual breathing room in a settings list).
- **No dividers between rows:** Section headers and spacing provide sufficient visual grouping.
- Page horizontal margin: `space4` (16dp).
- Bottom safe area: `space16` (64dp).
