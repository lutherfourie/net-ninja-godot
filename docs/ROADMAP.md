# Roadmap

Ordered by what the visual foundation says comes next, and by what each step
de-risks.

## Shipped — v0.1.0 (this prototype)

- Godot 4.7 project, 720 × 1280 portrait, GL Compatibility (mobile target).
- Three-layer architecture with a renderer-agnostic core.
- Main menu against the p.7 zone spec, ruined-edge CTA, settings overlay.
- Ami's flat as a walkable isometric room, 30-odd props, real 2D lighting.
- Proximity interactions that move `GameState.possession` and visibly change the
  room.
- Touch thumb stick, keyboard and gamepad input.
- Reduce-motion and high-contrast toggles.

## Next — v0.2.0: the catch loop

The one thing the prototype cannot yet answer is whether the game is *fun*.
Visual foundation p.11:

- Screen grammar: threat above, catch zone below, trash at the edge.
- Cat paw slam → violet shockwave → spectral ball burst.
- Drag the dangling net; mint balls fall, collide, visibly stack inside it.
- Drag the loaded net to the bin bottom-right; catches convert to bar progress.
- Drop limit as the failure pressure.

Build it in the same shape as the room: a `CatchModel` in `src/core/` (spawn
timing, ball physics, net capacity, fail threshold) with a `Catch2DView`. The
soft-cloth net from p.12 becomes a short joint chain when the 3D pass lands; the
model should not care.

## Then

| | |
| --- | --- |
| **Email + contracts** | The PC panel from p.6 — dark surface, 2 px state border, flat hierarchy. The interaction is already wired; it currently just raises possession. |
| **Cat-alog** | p.10. Same frame, eye line, scale and four-state icon for every portrait. Exorcised in full colour, undiscovered as dark silhouettes. |
| **Dialogue** | Bubble component exists (`RuinedShape.bubble` + separate tail); needs a script format and a speaker system. |
| **Ruined display face** | p.5. `wordmark.gd` fakes it procedurally today and is marked accordingly. Commissioning the real face replaces one function. |
| **Room3DView** | p.12. Stylized low-poly, baked light, shallow perspective camera, 60 fps mid-range. The core layer is already shaped for it — see ARCHITECTURE.md. |
| **Ami sprite work** | p.9. Home/off-duty and field/tech outfits; identity lock on hair, eyes, silhouette. `actor_2d.gd` becomes a sprite placer with the same anchor and 1.65-unit height. |

## Known rough edges

- The wordmark is ExtraBold plus procedural damage, not the real face.
- All room art is greybox; no sprite pipeline exists yet.
- `_screen_anchor()` recomputes the canvas transform per frame while a prompt is
  visible — fine at this scale, worth caching if prompts ever get numerous.
- No save system. `GameState` is session-only by design.
- No audio.
