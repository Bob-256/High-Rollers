extends CanvasLayer

# ─────────────────────────────────────────
#  HUDTheme.gd
#  Attach to the UI (CanvasLayer) node.
#  Applies casino noir styling entirely in
#  code — no theme editor required.
# ─────────────────────────────────────────

var player_hp_badge: HUDStatBadge
var opponent_hp_badge: HUDStatBadge
var font_serif: Font
var stage_lbl: Label

# ─────────────────────────────────────────
#  HUDStatBadge Nested Class
# ─────────────────────────────────────────
class HUDStatBadge extends Control:
	var value: int = 0
	var label_text: String = ""
	var badge_type: String = ""
	var font_serif: Font
	
	func _ready():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	func _draw():
		var w = size.x
		var h = size.y
		
		# 1. Choose colors based on stat type
		var glow_color: Color
		var core_color: Color
		var border_color: Color
		
		if badge_type == "energy": # Lightning (Blue)
			glow_color = Color(0.12, 0.53, 0.90, 0.4)
			core_color = Color(0.60, 0.85, 1.00)
			border_color = Color(0.12, 0.53, 0.90, 0.6)
		elif badge_type == "player_hp": # Heart (Green)
			glow_color = Color(0.20, 0.85, 0.30, 0.4)
			core_color = Color(0.70, 1.00, 0.80)
			border_color = Color(0.20, 0.85, 0.30, 0.6)
		else: # Opponent HP: Heart (Red)
			glow_color = Color(0.85, 0.20, 0.20, 0.4)
			core_color = Color(1.00, 0.70, 0.70)
			border_color = Color(0.85, 0.20, 0.20, 0.6)
			
		# 2. Draw backing pill stylebox
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.05, 0.03, 0.85) # dark casino felt
		sb.border_color = border_color
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		draw_style_box(sb, Rect2(0, 0, w, h))
		
		# 3. Draw Icon (glowing vector shape)
		if badge_type == "energy":
			# Lightning bolt scaled to 24px height
			var points = PackedVector2Array([
				Vector2(24, 4),
				Vector2(16, 18),
				Vector2(22, 18),
				Vector2(18, 28),
				Vector2(30, 14),
				Vector2(24, 14),
				Vector2(28, 4),
				Vector2(24, 4)
			])
			draw_polyline(points, glow_color, 4.0, true)
			draw_polyline(points, core_color, 1.5, true)
		else:
			# Heart scaled to 22px height
			var points = PackedVector2Array([
				Vector2(22, 11),
				Vector2(17, 6),
				Vector2(12, 11),
				Vector2(22, 27),
				Vector2(32, 11),
				Vector2(27, 6),
				Vector2(22, 11)
			])
			draw_polyline(points, glow_color, 4.0, true)
			draw_polyline(points, core_color, 1.5, true)
			
		# 4. Draw Label
		var col_label = Color(0.83, 0.66, 0.16, 0.8) # gold
		if font_serif:
			draw_string(font_serif, Vector2(42, 20), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_label)
			
			# 5. Draw Value Text with Glow/Outline
			var value_str = str(value)
			var glow_color_solid = Color(glow_color.r, glow_color.g, glow_color.b, 1.0)
			draw_string_outline(font_serif, Vector2(102, 22), value_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, 3, glow_color_solid)
			draw_string(font_serif, Vector2(102, 22), value_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, core_color)


func _ready():
	# Set default clear color to match the casino felt green theme
	RenderingServer.set_default_clear_color(Color(0.039, 0.102, 0.051))
	_apply_hud_theme()


func update_hp_display(p_hp: int, o_hp: int):
	if player_hp_badge:
		player_hp_badge.value = p_hp
		player_hp_badge.queue_redraw()
	if opponent_hp_badge:
		opponent_hp_badge.value = o_hp
		opponent_hp_badge.queue_redraw()


func update_stage_display(stage_num: int, opp_name: String):
	if stage_lbl:
		stage_lbl.text = "STAGE " + str(stage_num) + ": " + opp_name.to_upper()
	if opponent_hp_badge:
		var label = opp_name.to_upper()
		if label.ends_with(" BOT"):
			label = label.replace(" BOT", "")
		if label.length() > 10:
			label = label.substr(0, 9)
		opponent_hp_badge.label_text = label
		opponent_hp_badge.queue_redraw()


func _apply_hud_theme():
	# ── Palette ──────────────────────────────────────────────────
	var col_panel_border := Color(0.722, 0.569, 0.165)   # #b8912a  casino gold
	var col_gold         := Color(0.831, 0.659, 0.165)   # #d4a82a  energy value
	var col_btn_text     := Color(0.910, 0.769, 0.416)   # #e8c46a  button label
	var col_btn_bg       := Color(0.420, 0.067, 0.067)   # #6b1111  crimson
	var col_btn_bg_hover := Color(0.540, 0.090, 0.090)   # lighter on hover
	var col_btn_bg_press := Color(0.300, 0.047, 0.047)   # darker on press
	var col_btn_border   := Color(0.545, 0.102, 0.102)   # #8b1a1a

	# ── Fonts ─────────────────────────────────────────────────────
	font_serif = SystemFont.new()
	font_serif.font_names = PackedStringArray([
		"Georgia", "Palatino Linotype", "Palatino",
		"Book Antiqua", "Times New Roman"
	])
	font_serif.font_weight = 700

	# ── Background panel ──────────────────────────────────────────
	var hud_bg := Panel.new()
	hud_bg.offset_left   = 4.0
	hud_bg.offset_top    = 4.0
	hud_bg.offset_right  = 320.0
	hud_bg.offset_bottom = 140.0 # Fits 3 rows nicely (height 136)

	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.03, 0.08, 0.04, 0.95) # Dark felt green
	panel_box.border_color = col_panel_border
	panel_box.set_border_width_all(2) # Thick gold border looks premium
	panel_box.set_corner_radius_all(8)
	hud_bg.add_theme_stylebox_override("panel", panel_box)

	add_child(hud_bg)
	move_child(hud_bg, 0)   # draw behind badges and button

	# ── Stage & Opponent Label ────────────────────────────────────
	stage_lbl = Label.new()
	stage_lbl.name = "StageLabel"
	stage_lbl.text = "STAGE 1: NOVICE GAMBLER"
	stage_lbl.offset_left = 19.0
	stage_lbl.offset_top = 15.0
	stage_lbl.offset_right = 305.0
	stage_lbl.offset_bottom = 37.0
	stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_lbl.add_theme_font_override("font", font_serif)
	stage_lbl.add_theme_font_size_override("font_size", 11)
	stage_lbl.add_theme_color_override("font_color", col_panel_border) # Casino Gold
	add_child(stage_lbl)

	# ── Energy Display (Label) ────────────────────────────────────
	# We style it to hide the standard text, and connect the draw signal
	# to draw the lightning badge in its place.
	var energy_lbl: Label = $EnergyDisplay
	energy_lbl.offset_left = 19.0
	energy_lbl.offset_top = 47.0
	energy_lbl.offset_right = 155.0
	energy_lbl.offset_bottom = 79.0
	energy_lbl.pivot_offset = Vector2(68, 16) # Center for scaling animation
	energy_lbl.add_theme_color_override("font_color", Color(0, 0, 0, 0)) # Make default text invisible
	if not energy_lbl.draw.is_connected(_on_energy_display_draw):
		energy_lbl.draw.connect(_on_energy_display_draw)

	# ── Score progress bar ────────────────────────────────────────
	if has_node("ProgressBar"):
		$ProgressBar.visible = false

	# ── HP badges ─────────────────────────────────────────────────
	player_hp_badge = HUDStatBadge.new()
	player_hp_badge.name = "PlayerHPBadge"
	player_hp_badge.badge_type = "player_hp"
	player_hp_badge.label_text = "PLAYER"
	player_hp_badge.font_serif = font_serif
	player_hp_badge.value = 20
	player_hp_badge.offset_left = 19.0
	player_hp_badge.offset_top = 89.0
	player_hp_badge.offset_right = 155.0
	player_hp_badge.offset_bottom = 121.0
	add_child(player_hp_badge)

	opponent_hp_badge = HUDStatBadge.new()
	opponent_hp_badge.name = "OpponentHPBadge"
	opponent_hp_badge.badge_type = "opponent_hp"
	opponent_hp_badge.label_text = "DEALER"
	opponent_hp_badge.font_serif = font_serif
	opponent_hp_badge.value = 20
	opponent_hp_badge.offset_left = 169.0
	opponent_hp_badge.offset_top = 89.0
	opponent_hp_badge.offset_right = 305.0
	opponent_hp_badge.offset_bottom = 121.0
	add_child(opponent_hp_badge)

	# ── End Turn button ───────────────────────────────────────────
	var btn: Button = $EndTurnButton
	btn.text = "End Turn"
	btn.offset_left = 169.0
	btn.offset_top = 47.0
	btn.offset_right = 305.0
	btn.offset_bottom = 79.0

	var _make_btn_box = func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(1)
		s.set_corner_radius_all(6)
		s.content_margin_left   = 10.0
		s.content_margin_right  = 10.0
		s.content_margin_top    = 4.0
		s.content_margin_bottom = 4.0
		return s

	btn.add_theme_stylebox_override("normal",  _make_btn_box.call(col_btn_bg,       col_btn_border))
	btn.add_theme_stylebox_override("hover",   _make_btn_box.call(col_btn_bg_hover, col_panel_border))  # gold border on hover
	btn.add_theme_stylebox_override("pressed", _make_btn_box.call(col_btn_bg_press, col_btn_border))
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())   # no focus rect

	btn.add_theme_font_override("font", font_serif)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color",         col_btn_text)
	btn.add_theme_color_override("font_hover_color",   col_gold)
	btn.add_theme_color_override("font_pressed_color", col_btn_text)


func _on_energy_display_draw():
	var energy_lbl = $EnergyDisplay
	var text_val = energy_lbl.text
	var value = 0
	if "Energy: " in text_val:
		value = int(text_val.replace("Energy: ", ""))
		
	var w = energy_lbl.size.x
	var h = energy_lbl.size.y
	
	# Colors
	var glow_color = Color(0.12, 0.53, 0.90, 0.4)
	var core_color = Color(0.60, 0.85, 1.00)
	var border_color = Color(0.12, 0.53, 0.90, 0.6)
	
	# Backing Pill
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.03, 0.85)
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	energy_lbl.draw_style_box(sb, Rect2(0, 0, w, h))
	
	# Lightning bolt scaled to 24px height
	var points = PackedVector2Array([
		Vector2(24, 4),
		Vector2(16, 18),
		Vector2(22, 18),
		Vector2(18, 28),
		Vector2(30, 14),
		Vector2(24, 14),
		Vector2(28, 4),
		Vector2(24, 4)
	])
	energy_lbl.draw_polyline(points, glow_color, 4.0, true)
	energy_lbl.draw_polyline(points, core_color, 1.5, true)
	
	# Draw Label
	var col_label = Color(0.83, 0.66, 0.16, 0.8) # gold
	if font_serif:
		energy_lbl.draw_string(font_serif, Vector2(42, 20), "ENERGY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_label)
		
		# Draw Value Text with Glow/Outline
		var value_str = str(value)
		var glow_color_solid = Color(glow_color.r, glow_color.g, glow_color.b, 1.0)
		energy_lbl.draw_string_outline(font_serif, Vector2(102, 22), value_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, 3, glow_color_solid)
		energy_lbl.draw_string(font_serif, Vector2(102, 22), value_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, core_color)
