extends Node
## Layout, type and component tokens lifted verbatim from the Visual Foundation.
##
## Sources: "04 / LOGO + TYPE", "05 / GRAPHIC LANGUAGE", "06 / MOBILE MENU STRUCTURE".
## Every magic number in the UI should come from here so a design revision is a
## one-file change.

# --- Design canvas -------------------------------------------------------------
const DESIGN_SIZE := Vector2(720, 1280)  ## 720 x 1280 portrait

## Safe margins: functional UI stays inside 6% left/right and 10% top/bottom.
const SAFE_MARGIN_X := 0.06
const SAFE_MARGIN_Y := 0.10

## Menu zones as fractions of screen height (PDF p.7).
const ZONE_SYSTEM_TOP  := 0.10  ## system + safe area
const ZONE_LOGO        := Vector2(0.16, 0.32)
const ZONE_FOCAL       := Vector2(0.32, 0.78)  ## Ami / world focal zone
const ZONE_CTA         := Vector2(0.80, 0.92)

const LOGO_MAX_WIDTH_RATIO := 0.54  ## Logo max 54% of screen width
const LOGO_MIN_WIDTH_PX    := 260.0 ## Minimum digital width of the wordmark

# --- Mobile type scale (px at 720 x 1280) --------------------------------------
const TYPE := {
	"h1": 45,
	"h2": 33,
	"cta": 26,
	"body": 20,
	"meta": 15,
}

## Never render the ruined display face below this size, in paragraphs, or for
## long translated strings.
const RUINED_MIN_SIZE := 32

# --- Component parameters (PDF p.6) --------------------------------------------
const CORNER_CUT := 16.0        ## 12-20 px
const BORDER_WIDTH := 2.5       ## 2-3 px
const ICON_STROKE := 2.5
const CTA_MIN_HEIGHT := 64.0    ## 64-88 px tall
const CTA_MAX_HEIGHT := 88.0
const PRESSED_OFFSET := Vector2(0, 2)
const DISABLED_ALPHA := 0.45
const BUBBLE_PADDING := 24.0

## Shadow: 0 / 8 / 24 / 35%
const SHADOW_OFFSET := Vector2(0, 8)
const SHADOW_BLUR := 24.0
const SHADOW_ALPHA := 0.35

# --- Isometric world -----------------------------------------------------------
## One world unit is 32 px on the pixel grid (PDF p.13: "32 px units").
const PIXELS_PER_UNIT := 32.0


## Scale a design-space length to the current viewport, so the layout holds on
## taller/shorter phones without re-authoring anything.
func scaled(v: float, viewport: Vector2) -> float:
	return v * (viewport.x / DESIGN_SIZE.x)


## Rect of the safe area for a given viewport size.
func safe_rect(viewport: Vector2) -> Rect2:
	var mx := viewport.x * SAFE_MARGIN_X
	var my := viewport.y * SAFE_MARGIN_Y
	return Rect2(Vector2(mx, my), viewport - Vector2(mx, my) * 2.0)


## Convert a (from, to) height-fraction pair into a pixel band.
func zone_rect(zone: Vector2, viewport: Vector2) -> Rect2:
	var mx := viewport.x * SAFE_MARGIN_X
	return Rect2(
		Vector2(mx, viewport.y * zone.x),
		Vector2(viewport.x - mx * 2.0, viewport.y * (zone.y - zone.x))
	)
