extends CanvasLayer

# ─────────────────────────────────────────
#  HUDTheme.gd
#  Attach to the UI (CanvasLayer) node.
#  Applies casino noir styling entirely in
#  code — no theme editor required.
# ─────────────────────────────────────────

var player_hp_lbl: Label
var opponent_hp_lbl: Label

func _ready():
	# Set default clear color to match the casino felt green theme
	RenderingServer.set_default_clear_color(Color(0.039, 0.102, 0.051))
	_apply_hud_theme()

func update_hp_display(p_hp: int, o_hp: int):
	if player_hp_lbl:
		player_hp_lbl.text = "Player HP: " + str(p_hp)
	if opponent_hp_lbl:
		opponent_hp_lbl.text = "Opponent HP: " + str(o_hp)

func _apply_hud_theme():
	# ── Palette ──────────────────────────────────────────────────
	var col_panel_bg     := Color(0.051, 0.122, 0.071)   # #0d1f12  felt green
	var col_panel_border := Color(0.722, 0.569, 0.165)   # #b8912a  casino gold
	var col_gold         := Color(0.831, 0.659, 0.165)   # #d4a82a  energy value
	var col_btn_text     := Color(0.910, 0.769, 0.416)   # #e8c46a  button label
	var col_score_fill   := Color(0.753, 0.224, 0.169)   # #c0392b  dealer red
	var col_score_track  := Color(0.039, 0.102, 0.051)   # #0a1a0d  track bg
	var col_track_border := Color(0.165, 0.290, 0.180)   # #2a4a2e  track rim
	var col_btn_bg       := Color(0.420, 0.067, 0.067)   # #6b1111  crimson
	var col_btn_bg_hover := Color(0.540, 0.090, 0.090)   # lighter on hover
	var col_btn_bg_press := Color(0.300, 0.047, 0.047)   # darker on press
	var col_btn_border   := Color(0.545, 0.102, 0.102)   # #8b1a1a

	# ── Fonts ─────────────────────────────────────────────────────
	# Serif — used for numeric values and the button label
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray([
		"Georgia", "Palatino Linotype", "Palatino",
		"Book Antiqua", "Times New Roman"
	])
	serif.font_weight = 700

	# ── Background panel ──────────────────────────────────────────
	# Sits behind all HUD elements; sized to wrap them with a 6 px margin.
	var hud_bg := Panel.new()
	hud_bg.offset_left   = 4.0
	hud_bg.offset_top    = 4.0
	hud_bg.offset_right  = 320.0
	hud_bg.offset_bottom = 122.0

	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = col_panel_bg
	panel_box.border_color = col_panel_border
	panel_box.set_border_width_all(1)
	panel_box.set_corner_radius_all(5)
	hud_bg.add_theme_stylebox_override("panel", panel_box)

	add_child(hud_bg)
	move_child(hud_bg, 0)   # draw behind labels, bar, and button

	# ── Energy label ──────────────────────────────────────────────
	var energy_lbl: Label = $EnergyDisplay
	energy_lbl.add_theme_font_override("font", serif)
	energy_lbl.add_theme_font_size_override("font_size", 20)
	energy_lbl.add_theme_color_override("font_color", col_gold)

	# ── Score progress bar ────────────────────────────────────────
	if has_node("ProgressBar"):
		$ProgressBar.visible = false

	# ── HP displays ───────────────────────────────────────────────
	player_hp_lbl = Label.new()
	player_hp_lbl.name = "PlayerHP"
	player_hp_lbl.text = "Player HP: 20"
	player_hp_lbl.offset_left = 10.0
	player_hp_lbl.offset_top = 45.0
	player_hp_lbl.offset_right = 150.0
	player_hp_lbl.offset_bottom = 75.0
	player_hp_lbl.add_theme_font_override("font", serif)
	player_hp_lbl.add_theme_font_size_override("font_size", 15)
	player_hp_lbl.add_theme_color_override("font_color", col_gold)
	add_child(player_hp_lbl)

	opponent_hp_lbl = Label.new()
	opponent_hp_lbl.name = "OpponentHP"
	opponent_hp_lbl.text = "Opponent HP: 20"
	opponent_hp_lbl.offset_left = 160.0
	opponent_hp_lbl.offset_top = 45.0
	opponent_hp_lbl.offset_right = 310.0
	opponent_hp_lbl.offset_bottom = 75.0
	opponent_hp_lbl.add_theme_font_override("font", serif)
	opponent_hp_lbl.add_theme_font_size_override("font_size", 15)
	opponent_hp_lbl.add_theme_color_override("font_color", col_score_fill) # dealer red
	add_child(opponent_hp_lbl)

	# ── End Turn button ───────────────────────────────────────────
	var btn: Button = $EndTurnButton
	btn.text = "End Turn"

	var _make_btn_box = func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(1)
		s.set_corner_radius_all(4)
		s.content_margin_left   = 10.0
		s.content_margin_right  = 10.0
		s.content_margin_top    = 7.0
		s.content_margin_bottom = 7.0
		return s

	btn.add_theme_stylebox_override("normal",  _make_btn_box.call(col_btn_bg,       col_btn_border))
	btn.add_theme_stylebox_override("hover",   _make_btn_box.call(col_btn_bg_hover, col_panel_border))  # gold border on hover
	btn.add_theme_stylebox_override("pressed", _make_btn_box.call(col_btn_bg_press, col_btn_border))
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())   # no focus rect

	btn.add_theme_font_override("font", serif)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color",         col_btn_text)
	btn.add_theme_color_override("font_hover_color",   col_gold)
	btn.add_theme_color_override("font_pressed_color", col_btn_text)
