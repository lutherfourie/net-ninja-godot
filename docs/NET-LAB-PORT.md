# The net-lab port ledger

Source: `lutherfourie/net-lab` (`packages/core/config.ts` + `netCatcher.ts`,
read 2026-08-12). This file is the honest record of what was ported, what was
adapted for physics, and what was deliberately left behind — in net-lab's own
language, this is an **Untwinned Port** and this ledger is its fidelity debt.

## Ported 1:1 (constants carry their lab key names in `net_lab_rules.gd`)

- Fill-weighted follow: `net.followLerpEmpty/Full` (pointer rates 36/12 s⁻¹)
  as exponential convergence; weight = fill·√fill (`net.weightCurvePow` 1.5).
- Capacity 6 + full bounce (`net.capacity`, `net.fullBounce.enabled`).
- Facing model: `net.facingEaseAlpha`, pour-zone authority
  (`net.pour.facingEaseAlpha`, slow gate 0.35), weighted self-righting
  (`net.facing.weightedSelfRight`, rate 2.2), clamp-up (`net.facing.clampUp`),
  catch-carry window (`net.catch.speedCarryMs` 250, `minSpeed` 0 per the
  owner's 2026-07-11 call — the gate is one constant away).
- Pour gates verbatim: `net.pour.downSpeed/downSpeedFull/heightAbove/
  faceDownY/strokeTipY/xCapture`. Pour is the only emptying verb — enforced
  structurally by clamp-up, exactly as in the lab.
- World: bin at `world.binX/binY`, gravity −9.5 wu/s², wall restitution 0.7,
  item radius 0.22 wu, telegraph base 0.38 s, touch offset 1.15 wu.
- Tempo director (M1 flow-channel DDA): all `tempo.*` keys in `catch_model.gd`
  — compress on mastery, ease after drops, neutral deadband.
- Magnet assist `net.magnet.*` (radius 0.9 wu, strength 7 wu/s²) — **ON here**
  though OFF in the lab: see Adapted.

## Adapted for a physical net (each annotated at the code site)

| Lab behaviour | Physical translation | Why |
| --- | --- | --- |
| `tryRimBounce` torus maths | Real rim/bag colliders + PhysicsMaterial | Godot has the solver the lab lacked; juggling emerges |
| `tryCatch` mouth-plane sweep | Bag-interior Area2D entry = the catch | Entering the interior *is* crossing the plane |
| `held[]` glued to net pos | Capture-on-entry: balls freeze and ride the rig | A loose cargo was ejected by every braking stroke; the lab glued held items too (`item.pos.copy(this.pos)`) |
| `webDeflect` full bounce | The LID: a mouth collider engaged at capacity | Taut webbing, made literal — and visible |
| Pour splices the array | Pour unfreezes the haul; gravity pours it | The one place the port is *more* honest than the lab |
| Facing vector lerp+normalize | Angular ease | The lab's form is degenerate for an axis-aligned stroke — `(0,y).normalized()` snaps back; bots and pours hit it |
| — | Tip-rate caps (6 / 3 rad/s) | A bag swung 180° in 0.15 s slings its haul; p.12's "restrained damping" as rotation |
| — | Load-scaled speed caps (2600→950 px/s) | "Empty = fast ninja hands, full = lumbering", physically |
| `restPose.mode` "hold" (default) | "level" ON | An idle physical mouth aimed sideways deflects everything; the lab's virtual catch didn't care |
| `net.magnet.enabled` false | true | The lab's 120° catch cone (`net.catch.coneDeg`) vs ~65° effective physical acceptance — the magnet restores the difference |

## Left behind (later slices, in the lab's own priority language)

Knives / parry / net-break, charms, heaping (flag OFF in the lab), the juggle
ladder's scoring rungs, temper, spike, sweep policies and the ceremony FSM
(walk→anticipate→telegraph→push — our CatchModel keeps its simpler slam clock,
now tempo-shaped). Each of these is a `CatchModel`/`CatchRules` conversation,
not a net conversation — the rig will not need to change.

## Engine scar tissue (read before touching net_rig.gd)

`sync_to_physics` on AnimatableBody2D discards node-transform writes made from
`_physics_process` AND `_process` on this build — the net silently never moves
(v0.2's rail net shipped with this bug; the smoke harness caught it). A
velocity-driven RigidBody2D fought the solver. What works: sync OFF, plain
per-tick transform writes, thick bag walls, CCD on the balls.

## Testing

`godot --headless --path . res://tools/net_smoke.tscn` — a seeded, persona-style
bot on the same input seam as a finger (writes `NetRig.target`, nothing else):
catch under the telegraph, carry, pour over the can. The slam schedule is
seeded but Godot physics is not bit-deterministic across runs, so the gate
checks SOLVABILITY, not balance: held ≥ 2 (multi-catch works), banked ≥ 2
(pour works), and survive-or-progress (≥ 0.45 bar if lost). Exit code 0/1.
Every one of those thresholds maps to a failure this gate caught during the
port: the never-moving net, the un-tippable vertical pour, the cargo ejections.
Best observed bot run: held 4, banked 9, cleansed 0.67 in 42 s. Balance
verdicts stay with human play — in net-lab language, a Feel Claim.
