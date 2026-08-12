# Style guide — implementation notes

Condensed from `NetNinja_Visual_Foundation_v0.2.pdf`, annotated with where each
rule lives in code. The PDF is the source of truth; this file is the map.

## Tone

70% cozy / 20% mischievous / 10% uncanny. Build warmth first, layer possession on
top. Ami stays readable, capable and human — never swallowed by the effects.

In code this shows up as: the room is fully furnished and lit before any spectral
colour appears, `GameState.possession` starts at 0.35 rather than 1.0, and the
only things that react to possession are the PC, the wall shadow and Miso's eyes
(`reacts_to_possession` on `PropDef`).

## Colour → `src/autoload/palette.gd`

| Token | Hex | Meaning |
| --- | --- | --- |
| `MIDNIGHT_INK` | `#17131F` | Primary background |
| `CHARCOAL_PLUM` | `#2A2032` | Panels / shadows |
| `HEARTH_CREAM` | `#F4E7D3` | Text / paper |
| `WARM_AMBER` | `#E6A45B` | Primary CTA — **amber invites action** |
| `DUSTY_ROSE` | `#C87985` | Human warmth |
| `POSSESSED_VIOLET` | `#8C5BC2` | **Violet indicates possession** |
| `SPECTRAL_MINT` | `#75D0B1` | **Mint confirms cleansing** |
| `WARNING_CORAL` | `#D85F57` | **Coral means danger or loss** |

Screen weight target: 55% dark neutrals, 25% warm light, 15% character, 5%
spectral. Spectral colour is scarce on purpose — reach for `Palette.semantic()`
and if no semantic key fits, the colour is wrong.

`Palette.faces()` derives the three isometric face shades from one base so every
prop in the room is lit from the same direction.

## Type → `src/ui/fonts.gd`, `src/autoload/tokens.gd`

| Role | Face | Used for |
| --- | --- | --- |
| Display | Custom ruined *(not yet cut)* | Logo, demon names, supernatural reveals |
| Headings | Nunito Sans ExtraBold | Section titles, button labels |
| UI + body | Nunito Sans SemiBold | Buttons, dialogue, menus, contracts |
| Tech data | Space Mono Medium | Emails, timestamps, IDs **only** |

Scale at 720 × 1280 — H1 42–48, H2 30–36, CTA 24–28, body 18–22, metadata 14–16.
`Tokens.TYPE` holds the midpoints.

Never render the ruined face below 32 px, in paragraphs, or for long translated
strings. `Tokens.RUINED_MIN_SIZE` enforces the floor in `wordmark.gd`.

## Components → `src/ui/ruined_shape.gd`

| Parameter | Value | Token |
| --- | --- | --- |
| Corner cut | 12–20 px | `Tokens.CORNER_CUT` (16) |
| Border | 2–3 px | `Tokens.BORDER_WIDTH` (2.5) |
| Icon stroke | 2.5 px | `Tokens.ICON_STROKE` |
| Shadow | 0 / 8 / 24 / 35% | `Tokens.SHADOW_*` |
| Pressed | move 2 px down | `Tokens.PRESSED_OFFSET` |
| Disabled | 45% opacity | `Tokens.DISABLED_ALPHA` |
| CTA height | 64–88 px | `Tokens.CTA_MIN_HEIGHT` / `MAX` |
| Bubble padding | 24 px | `Tokens.BUBBLE_PADDING` |

Pair every cozy cue with one cursed cue: parchment warmth against ruined corners
and cat-ear peaks. Dialogue bubbles use a **separate tail** and never bake text
into the shape — `RuinedShape.bubble_tail()` exists for exactly this reason.

## Menu layout → `src/scenes/main_menu.gd`

```
 0–10%    system + safe area
16–32%    logo zone          — max 54% screen width, min 260 px
32–78%    Ami / world focal
80–92%    CTA zone           — one primary action
```

Safe margins: 6% left/right, 10% top/bottom (`Tokens.safe_rect()`). Background
fills every aspect ratio; only non-essential room detail may crop. Logo, button
and settings are separate UI layers over a responsive background illustration —
which here is the live room scene, not a still.

## Guardrails

**Always**

- Establish warm, believable home life before adding the curse.
- Keep Ami, cats and primary actions readable at thumbnail size.
- Use violet, mint and coral only when their state meaning applies.
- Match 2D character lighting to the dominant room light.
- Leave safe-area space before adding decorative detail.
- Build text, tails, badges and effects as separate layers.

**Never**

- Generic Halloween imagery, gore, skull piles, satanic clichés.
- Bright neon on every object.
- Ruined typography for body copy, emails or long dialogue.
- Tiny scratches, noise and grunge that vanish on mobile.
- More than one equally strong primary action on a screen.
- 2D art that ignores the camera angle or room lighting.

## Pixel baseline (for the art pass, not yet in code)

32 px units · 2–4 px outline · nearest-neighbour import · integer scaling · no
anti-aliasing. `Tokens.PIXELS_PER_UNIT` is already 32, and the project's default
texture filter is set to nearest so imported sprites stay crisp.
