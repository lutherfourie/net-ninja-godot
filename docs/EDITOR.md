# Room editor

Press **F1** in the room hub. The live flat flips into edit mode; **F1** (or
Esc, or the PLAY button) saves and flips back. What you edit is the same
`RoomModel` the game plays, rendered by the same `Room2DView` — there is no
"editor look" that lies to you.

## Where rooms live now

Rooms are JSON in `data/rooms/`, loaded through `RoomIO`:

```
user://rooms/<id>.json     runtime saves in exported builds (override)
res://data/rooms/<id>.json the repo copy — what the editor writes on a dev machine
src/core/rooms/<id>.gd     the code builder, kept as fallback and first version
```

Saving on a dev machine writes straight into the repo and deletes any stale
`user://` override, so `git diff data/rooms/ami_apartment.json` *is* the layout
review. If a builder changes, regenerate its JSON with:

```bash
godot --headless --path . res://tools/export_rooms.tscn --quit-after 60
```

## Controls

| Input | Action |
| --- | --- |
| Left click | Select (smallest footprint wins on overlap) |
| Quick click again | Cycle through overlapping props |
| Drag | Move on the ground plane, snapped to 0.05 units |
| Shift + drag | Raise / lower (origin Y) |
| Arrow keys | Nudge on world X/Z by 0.1 (Shift = 0.5) |
| R / F | Raise / lower by 0.1 |
| `,` / `.` | Step through the prop list — reaches wall art and shelves the ground pick cannot |
| Delete / Backspace | Delete selection |
| Ctrl+D | Duplicate selection |
| Ctrl+Z | Undo (snapshot stack, 60 deep) |
| Ctrl+S | Save |
| S | Move the spawn point to the mouse |
| Tab | Toggle the inspector panel |
| G | Toggle the unit grid / walk-rect / spawn overlay |
| L | Toggle the night lighting grade (judge base colours in flat light) |
| Mouse wheel | Zoom |
| Right / middle drag | Pan |
| F1 / Esc | Save (if dirty) and play the room |

## The inspector

Everything on a `PropDef` is editable: kind and decal (cycle), position and size
(steppers), base and accent colour (a swatch grid of the palette — the editor
deliberately offers *only* on-brand colours), blocks/possessed flags, light
presets (amber / violet / mint / window-blue, matching the semantic colour
rules) with energy, radius and offset, and the interaction id, label and radius.

Renaming a prop's id is the one structural edit — it rebuilds the view, since
ids key the renderer's node and light tables.

## What it deliberately does not do yet

Walk-rects and room bounds are hand-edited in the JSON for now — they change
rarely and the grid overlay makes the current ones visible while you work.
There is no multi-select, and no editing of rooms other than the flat until a
second room exists to edit.
