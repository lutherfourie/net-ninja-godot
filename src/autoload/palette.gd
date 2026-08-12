extends Node
## Net Ninja colour system.
##
## Source of truth: docs/NetNinja_Visual_Foundation_v0.2.pdf — "03 / COLOUR SYSTEM".
## Spectral colours signal STATE, never decoration. Screen colour weight target is
## 55% dark neutrals / 25% warm light / 15% character / 5% spectral, so anything
## reaching for VIOLET, MINT or CORAL must justify it semantically.

# --- Core ramp -----------------------------------------------------------------
const MIDNIGHT_INK   := Color("17131f")  ## Primary background
const CHARCOAL_PLUM  := Color("2a2032")  ## Panels / shadows
const HEARTH_CREAM   := Color("f4e7d3")  ## Text / paper
const WARM_AMBER     := Color("e6a45b")  ## Primary CTA
const DUSTY_ROSE     := Color("c87985")  ## Human warmth
const POSSESSED_VIOLET := Color("8c5bc2")  ## Cursed state
const SPECTRAL_MINT  := Color("75d0b1")  ## Success / cleanse
const WARNING_CORAL  := Color("d85f57")  ## Failure / danger

# --- Derived neutrals used by the greybox room ---------------------------------
const INK_DEEP    := Color("100d16")
const PLUM_LIGHT  := Color("372a42")
const WOOD_WARM   := Color("6b4630")
const CREAM_DIM   := Color("c9b79c")

## Wood tones for the floor and furniture. Kept as a small ramp so every prop in
## the room reads as one material family (PDF: "hand-painted materials").
const WOOD := {
	"floor_a": Color("8d5c3c"),
	"floor_b": Color("7d5033"),
	"top":     Color("8a5a3c"),
	"left":    Color("5f3d29"),
	"right":   Color("482e1f"),
}

const FABRIC := {
	"top":   Color("b9ab99"),
	"left":  Color("9b8e7e"),
	"right": Color("7d7264"),
}

## Semantic lookup — prefer this over raw constants in gameplay code so a future
## colour-blind / high-contrast mode can remap one dictionary.
const SEMANTIC := {
	"action":   WARM_AMBER,       ## Amber invites action.
	"cursed":   POSSESSED_VIOLET, ## Violet indicates possession.
	"cleansed": SPECTRAL_MINT,    ## Mint confirms cleansing.
	"danger":   WARNING_CORAL,    ## Coral means danger or loss.
	"human":    DUSTY_ROSE,
	"text":     HEARTH_CREAM,
	"panel":    CHARCOAL_PLUM,
	"bg":       MIDNIGHT_INK,
}


func semantic(key: String) -> Color:
	assert(SEMANTIC.has(key), "Unknown semantic colour: %s" % key)
	return SEMANTIC.get(key, HEARTH_CREAM)


## Shade a base colour for the three visible faces of an isometric box.
## Returns { top, left, right } so every prop is lit from the same direction.
func faces(base: Color) -> Dictionary:
	return {
		"top": base.lightened(0.16),
		"left": base.darkened(0.14),
		"right": base.darkened(0.32),
	}


## Mix toward the room's warm key light. Used by the 2D view to fake baked light
## on props that sit inside a lamp pool.
func warmed(base: Color, amount: float) -> Color:
	return base.lerp(WARM_AMBER, clampf(amount, 0.0, 1.0) * 0.45)
