# Roadmap

Ordered by what the visual foundation says comes next, and by what each step
de-risks.

## Shipped — v0.1.0

- Godot 4.7 project, 720 × 1280 portrait, GL Compatibility (mobile target).
- Three-layer architecture with a renderer-agnostic core.
- Main menu against the p.7 zone spec, ruined-edge CTA, settings overlay.
- Ami's flat as a walkable isometric room, 30-odd props, real 2D lighting.
- Touch thumb stick, keyboard and gamepad input.
- Reduce-motion and high-contrast toggles.

## Shipped — v0.2.0: the catch loop

The thing v0.1.0 could not answer was whether the game is *fun*. It now has an
answer to argue with. Visual foundation p.11, implemented in order:

- **Slam + spawn.** The cat telegraphs — eyes flash violet, paw lifts — then
  lands, throwing a violet shockwave and a burst of spectral balls.
- **Move + catch.** One-axis drag. Balls fall, collide and stack inside the net
  as real bodies; the near side of the mesh draws over them so they read as
  *inside* it.
- **Dump + cleanse.** Carry a loaded net to the far right and it tips into the
  hooded can, converting the catch into bar progress.
- **Drop limit as the only failure.** Nothing else can lose a contract.

Difficulty is a `CatchRules` resource, so a harder cat is data rather than code.
Cadence and burst size ramp with the bar, which means pressure peaks exactly when
the player is closest to winning. The outcome writes back to
`GameState.possession`, so the flat Ami returns to is visibly better or worse.

### Tuning notes, for whoever plays it next

- Burst spread (58 px) is deliberately narrower than the net mouth (168 px): a
  correctly placed net takes a whole burst. The skill is reading the telegraph,
  not reacting to scatter.
- The 0.52 s telegraph plus ~1.4 s of fall time is the entire reaction budget.
  Shortening either makes the drop limit feel unfair rather than tense.
- A dump trip costs roughly one burst of coverage. That trade — bank now or hold
  for one more catch — is the loop. If it stops being a real decision, raise
  `net_capacity` or lower `cleanse_per_ball` rather than touching the cadence.

## Shipped — v0.3.0: the room editor

Greyboxing stopped being a code edit. F1 in the hub opens an in-game editor on
the live room: click/cycle select, ground drag with 0.05 snap, shift-drag for
height, an inspector for every PropDef field with palette-only swatches and
semantic light presets, snapshot undo, and Ctrl+S straight into
`data/rooms/ami_apartment.json`. The hub and menu load that JSON through
`RoomIO` with the old code builder as fallback. See docs/EDITOR.md.

## Next

**Net play rework (queued, per Luther):** rebuild the catch net in the
"net-ninja" style out of Godot-native physics — a short joint chain of
RigidBody2D segments (PinJoint2D / DampedSpringJoint2D) so the bag genuinely
deforms and swings under load, with restrained damping per PDF p.12 so touch
control stays immediate. `CatchModel` is untouched by design; this is a
`net_body.gd` replacement plus tuning. The fairness rule survives: the *mouth*
of the net stays predictable even while the bag swings.


| | |
| --- | --- |
| **Email + contracts** | The PC panel from p.6 — dark surface, 2 px state border, flat hierarchy. It should pick *which* cat you fight and hand the catch loop a different `CatchRules`. |
| **Cat-alog** | p.10. Same frame, eye line, scale and four-state icon for every portrait. Exorcised in full colour, undiscovered as dark silhouettes. Cleared contracts should be what fills it. |
| **Dialogue** | Bubble component exists (`RuinedShape.bubble` + separate tail); needs a script format and a speaker system. |
| **Ruined display face** | p.5. `wordmark.gd` fakes it procedurally today and is marked accordingly. Commissioning the real face replaces one function. |
| **Room3DView / Catch3DView** | p.12. Stylized low-poly, baked light, shallow perspective camera, 60 fps mid-range. Both core layers are already shaped for it — see ARCHITECTURE.md. The soft cloth net becomes a short joint chain; `CatchModel` does not change. |
| **Ami sprite work** | p.9. Home/off-duty and field/tech outfits; identity lock on hair, eyes, silhouette. `actor_2d.gd` becomes a sprite placer with the same anchor and 1.65-unit height. |

## Known rough edges

- The wordmark is ExtraBold plus procedural damage, not the real face.
- All art is greybox; no sprite pipeline exists yet.
- The catch loop has one contract. There is no cat roster and no reward beyond
  the possession swing.
- The net's lean is cosmetic — the catch mouth never actually rotates. That is
  the right call for fairness, but it will need revisiting when the cloth net
  from p.12 arrives.
- No save system. `GameState` is session-only by design.
- No audio, which is doing the catch loop no favours; impact and capture are
  exactly the moments that want sound.
