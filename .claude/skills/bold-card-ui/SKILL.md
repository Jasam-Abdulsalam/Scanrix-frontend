---
name: bold-card-ui
description: Scanrix's bold-card visual language for Flutter screens - one solid accent hero card, borderless dark cards with big radii, circular icon buttons, pill buttons with an arrow circle, multi-column stat cards, thick ring gauges, and micro-animations. Use when building, restyling or reviewing any Flutter screen, card, list row, stat block, button or bottom sheet in this app, or when a screen "looks like a default/AI template" and needs a distinctive, polished look.
---

# Bold-card UI (Scanrix, Flutter)

A dark, high-contrast language from modern fitness/health app designs: **near-black page,
borderless charcoal cards, and ONE solid, saturated accent used as a fill** (not as tinted
glows). Shapes are big and soft (24-28 radius, circles, pills). Type is heavy and tight.
**Use the shared widgets in `lib/core/widgets/bold_card.dart`** - don't copy them:
`boldAccent(context)`, `kOnAccent`, `boldCardFill()`, `BoldCard`, `CircleIcon`, `IconTile`,
`Pressable`, `AccentRing`, `StatColumnsCard`/`StatColumnData`, `AccentPillButton`,
`TopNotchClipper`, `measureText`.
Reference screens: `ai_verdict_page.dart` (AI verdict) and `analysis_result_view.dart`
(scan result, product and label-scan variants).
For motion physics (springs, interruptibility, gestures) also follow the `apple-design` skill.

## 1. The rules that make it look designed, not default

1. **One accent per screen, used as a solid fill.** The hero card IS the accent color
   (the theme's brand emerald, `boldAccent(context)` = `colors.neonEmerald`) and does not change with status. Text and icons on it are near-black
   (`Color(0xFF0B0F0C)`), never white. Everything else is charcoal + white + grey.
2. **Status is never told by the card color.** Use three signals together: icon SHAPE
   (check circle / warning triangle / octagon), status color (emerald / amber / red) only on
   a black surface (a black badge circle, a black pill's dot), and words (the title).
   Bright status colors directly on the accent have too little contrast.
3. **No borders, no gradients, no glows, no glassmorphism on cards.** Cards separate from the
   page by fill alone. (Icon tiles are the one exception, see rule 5.) If two dark surfaces are too close in value, lighten the card fill;
   don't add a border.
4. **Big radii, consistent scale:** hero 28, card 24, inner block/callout 20, chip/pill = fully
   round (`20.r`+ or `StadiumBorder`). Bottom sheet top corners 28.
5. **Leading icons are solid "iOS Settings" tiles:** a rounded square (radius 30% of size,
   38 in rows) or a circle (32 in stat columns), filled with the icon's own color as a soft
   top-to-bottom gradient (+8% / -12% HSL lightness), a small same-color shadow, and a
   **dark glyph** (white only on dark colors), glyph = 56% of the tile. Action buttons
   (arrow, refresh) and the hero's verdict badge are plain solid circles (38).
6. **Heavy, tight type.** Display/hero: `w800`, letterSpacing `-0.8`, height `1.05`.
   Card titles: `w700`, `-0.2`. Body: `w400`, height `1.4-1.5`, letterSpacing `0`.
   Labels: secondary grey, `11.5-12sp`, `w500-600`. Numbers: `tabularFigures`.
7. **Hierarchy by fill, size and weight - not by decoration.** Never fix a flat-looking screen
   with shadows or gradients; enlarge the key number, make the hero a solid accent block.
8. **No AI clichés:** no sparkle/stars icon, no purple-blue gradients, no pastel 14%-tint
   icon squares, no glow halos.

## 2. Tokens (dark theme)

| Token | Value | Notes |
| --- | --- | --- |
| Page bg | `colors.background` | near-black |
| Card fill | `Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colors.surface)` | borderless; works in both `AppThemeColors` modes |
| Accent | `boldAccent(context)` = brand `colors.neonEmerald` (follows the theme) | used as a FILL; never a hardcoded color |
| On-accent | `Color(0xFF0B0F0C)` | text/icons on the accent |
| Divider | `Colors.white.withValues(alpha: 0.07-0.08)` | inset after leading icon |
| Chip fill | `Colors.white.withValues(alpha: 0.07)` | pill shaped |
| Secondary text | `colors.secondaryText` | |
| Spacing | page side 16, between sections 12, card padding 18 (rows 14) | all via `.w/.h/.r` |

Always use `flutter_screenutil` units (`.w .h .r .sp`) and `context.colors` - never raw
numbers or hardcoded theme colors (project convention, see CLAUDE.md "Sizing").

## 3. Components (recipes)

**Hero accent card** - the one thing the eye lands on.
```dart
Container(
  padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 20.h),
  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(28.r)),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: smallPill),            // onAccent @10% fill, onAccent text
      circleIcon(bg: onAccent, fg: accent),  // dark circle, accent glyph
    ]),
    SizedBox(height: 14.h),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: bigTitle + dimmedSubtitle), // onAccent, w800 / onAccent @72%
      ringGauge,                                  // dark ring on the accent
    ]),
  ]),
)
```

**Top notch**: the hero card gets a small rounded notch cut into the middle of its top edge
(the "connector tab" of stacked cards): wrap it in
`ClipPath(clipper: TopNotchClipper(radius: 28.r, notchWidth: 56.w, notchDepth: 7.h))`.

**Dark card** - `Container(padding: 18.r, decoration: BoxDecoration(color: cardFill, borderRadius: 24.r))`.
Title inside: white `16sp w700`; optional trailing "View all" text in the accent color.

**Stat columns card** (Calories | Heart rate | Duration style): one dark card,
`IntrinsicHeight` + `Row`, columns `Expanded`, separated by
`VerticalDivider(width: 1, indent: 6.h, endIndent: 6.h)`. Each column: circular icon tile (32, rule 5) ->
big white number (`22sp w800`, tabular) -> grey label (`12sp`). Tappable columns get
`_Pressable`; a zero/empty column is `Opacity(0.4)` and not tappable.

**List row**: leading icon tile (38 rounded square, rule 5) -> title `15sp w700` /
subtitle grey `13sp` -> trailing **solid accent circle with `arrow_forward_rounded`** (38,
on-accent glyph) when the row navigates. Rows inside one card are split by dividers indented
past the icon (`indent: 56.w`).

**Pill button with arrow circle** (primary CTA):
```dart
Container(
  padding: EdgeInsets.fromLTRB(22.w, 6.h, 6.w, 6.h),
  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(30.r)),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Text('Start', style: TextStyle(color: onAccent, fontWeight: FontWeight.w700)),
    SizedBox(width: 12.w),
    circleIcon(icon: Icons.arrow_forward_rounded, bg: onAccent, fg: accent, size: 36.r),
  ]),
)
```
On a dark card, invert it: dark pill (`onAccent`) with white text and an accent arrow circle.

**Ring gauge**: `CustomPainter`, stroke = 11% of size, `StrokeCap.round`, track = foreground
@12%, arc starts at `-pi/2`. Number centered, `w800`, with a small dimmed unit below
("/100", "steps"). On the accent card the ring is dark; on a dark card the ring is accent.

**Segmented pills** (Day / Week / Month): selected = accent fill + on-accent text, others =
transparent + grey text, all `StadiumBorder`, inside a card-fill pill track.

**Number badge**: white or accent circle overlapping a card corner with a heavy number - use
for counts/steps ("3", "9").

**Bottom sheet** for "see all": `showModalBottomSheet(isScrollControlled: true,
useSafeArea: true, showDragHandle: true, backgroundColor: colors.background, shape: top 28)`,
`maxHeight` 75% of screen, content = sheet title row (glyph + `18sp w700`) + one grouped card.

## 4. Layout

- **One screen, at a glance.** Order: hero card -> short text card (clamp 3 lines + "Read
  more") -> stat columns card -> the single most important item as a row -> fine print.
  Long lists go in bottom sheets, not on the page. Keep a `SingleChildScrollView` only as a
  safety net for small phones / large text.
- Fine print (disclaimers) = plain centered grey `11sp` text, no box.
- Every `Row` holding text must survive large text: wrap text in `Flexible`/`Expanded` with
  `maxLines` + ellipsis. Prefer `MainAxisAlignment.spaceBetween` over `Spacer` next to a
  `Flexible` (a `Spacer` would cap the flexible child at half the width).

## 5. Micro-animations (subtle, purposeful)

All driven by one `AnimationController` (~1100 ms) per screen where possible:
- **Staggered entrance:** each section fades in and rises 12 px, start offset `index * 0.07`,
  `Curves.easeOutCubic`, no overshoot.
- **Count-up:** big numbers and the ring fill animate from 0 on entrance (`Interval(0.25, 0.75)`).
- **Press feedback on touch-DOWN:** `AnimatedScale` to `0.96`, 120 ms, back on up/cancel.
- **Haptics:** `HapticFeedback.selectionClick()` on taps that open something,
  `lightImpact()` once when an async result lands. Never on scroll.
- **Expand/collapse:** `AnimatedSize` 280 ms `easeOutCubic`; chevrons `AnimatedRotation`.
- **Reduced motion:** if `MediaQuery.disableAnimationsOf(context)`, jump controllers to the
  end, use `Duration.zero`, and skip scale effects.

## 6. Review checklist

- [ ] Exactly one solid accent block; on-accent content is dark.
- [ ] No borders, gradients, glows or sparkle icons on cards.
- [ ] Radii follow 28 / 24 / 20 / round; leading icons are solid tiles with dark glyphs.
- [ ] Key number is the biggest, heaviest text on the screen.
- [ ] Long content lives in a bottom sheet; the page fits one screen on a 375x812 phone.
- [ ] All sizes use screenutil units; all colors come from `context.colors` or the tokens above.
- [ ] Text rows don't overflow at large text sizes (Flexible + ellipsis).
- [ ] Press scale + haptics on tappables; reduced motion respected.
- [ ] Both themes (`darkGreen`, `blackishReference`) checked.
