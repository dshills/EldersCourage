extends RefCounted

const OUTER_MARGIN := 12
const PANEL_PADDING := 12
const SECTION_GAP := 8
const BUTTON_GAP := 8
const TILE_GAP := 9

const FONT_HEADER := 24
const FONT_SECTION := 17
const FONT_BODY := 14
const FONT_BUTTON := 14
const FONT_SUBTLE := 12

static func color(token: String) -> Color:
	match token:
		"deep_background":
			return Color(0.048, 0.041, 0.035)
		"panel_dark":
			return Color(0.075, 0.058, 0.044)
		"panel_deep":
			return Color(0.055, 0.046, 0.038, 0.98)
		"panel_parchment":
			return Color(0.58, 0.45, 0.27)
		"section_parchment":
			return Color(0.68, 0.53, 0.32)
		"border_gold":
			return Color(0.66, 0.48, 0.22)
		"border_muted":
			return Color(0.36, 0.27, 0.16)
		"text_primary":
			return Color(0.94, 0.86, 0.68)
		"text_secondary":
			return Color(0.72, 0.62, 0.43)
		"text_dark":
			return Color(0.19, 0.12, 0.065)
		"text_heading":
			return Color(0.96, 0.80, 0.42)
		"danger":
			return Color(0.72, 0.22, 0.12)
		"success":
			return Color(0.22, 0.52, 0.28)
		"magic":
			return Color(0.22, 0.46, 0.68)
		"curse":
			return Color(0.55, 0.22, 0.62)
		"disabled_fill":
			return Color(0.09, 0.075, 0.06)
		"disabled_border":
			return Color(0.34, 0.28, 0.20)
		"disabled_text":
			return Color(0.58, 0.50, 0.36)
		_:
			return Color.WHITE

static func stylebox(fill: Color, border: Color, border_width: int = 2, radius: int = 6, padding: int = PANEL_PADDING) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_top = padding
	box.content_margin_right = padding
	box.content_margin_bottom = padding
	return box
