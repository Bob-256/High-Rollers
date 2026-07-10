extends PanelContainer

@export var data: CardData
var dragging = false
var original_position: Vector2
var hover_scale := Vector2(2.0, 2.0)
var default_scale := Vector2(1.0, 1.0)

var hand_position := Vector2.ZERO
var hand_rotation := 0.0
var in_hand := true
var is_hovered := false
var active_tooltip: CardTooltip = null

var label_font: Font

func _ready():
	# Connect the mouse signals to these functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	$StatOverlay.draw.connect(_on_stat_overlay_draw)
	
	label_font = SystemFont.new()
	label_font.font_names = PackedStringArray(["Sans-Serif", "Arial", "Helvetica"])
	label_font.font_weight = 700

func _on_mouse_entered():
	if not dragging:
		is_hovered = true
		if in_hand:
			_update_layout()

func _on_mouse_exited():
	if not dragging:
		is_hovered = false
		if in_hand:
			_update_layout()

func set_hand_targets(pos: Vector2, rot: float):
	hand_position = pos
	hand_rotation = rot
	in_hand = true
	if not dragging:
		_update_layout()

func _update_layout():
	if not in_hand or dragging:
		return
		
	var target_pos = hand_position
	var target_rot = hand_rotation
	var target_scale = default_scale
	var target_z = 0
	
	if is_hovered:
		target_rot = 0.0
		target_scale = hover_scale
		target_pos.y -= 45.0
		target_z = 5
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", target_rot, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	z_index = target_z

func setup_card(card_data: CardData):
	data = card_data
	pivot_offset = Vector2(70, 95)
	
	get_node("CardArt").texture = data.card_art
	
	# Clear static tooltip so we can use dynamic _get_tooltip()
	tooltip_text = ""
	
	_apply_fonts_and_styles()
	$StatOverlay.queue_redraw()

func _get_tooltip(_at_position: Vector2) -> String:
	return ""

func _apply_fonts_and_styles():
	var panel_box = StyleBoxFlat.new()
	panel_box.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	panel_box.set_border_width_all(1)
	
	var name_lower = data.card_name.to_lower()
	if "jackpot" in name_lower:
		panel_box.border_color = Color(0.831, 0.659, 0.165) # gold
		panel_box.set_border_width_all(2)
	elif "pit boss" in name_lower or "high roller" in name_lower:
		panel_box.border_color = Color(0.7, 0.7, 0.75) # silver
		panel_box.set_border_width_all(2)
	else:
		panel_box.border_color = Color(0.25, 0.25, 0.25)
		
	panel_box.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", panel_box)

func _on_stat_overlay_draw():
	if data == null:
		return
	
	# Draw background badge pills for contrast
	draw_stat_badge(Vector2(10, 10), data.energy_cost, "energy")
	draw_stat_badge(Vector2(10, 28), data.attack, "attack")
	draw_stat_badge(Vector2(10, 46), data.health, "health")

func draw_stat_badge(pos: Vector2, value: int, type: String):
	# Draw backing pill
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.05, 0.7)
	sb.set_corner_radius_all(4)
	$StatOverlay.draw_style_box(sb, Rect2(pos.x - 4, pos.y - 2, 44, 16))
	
	# Core/glow colors
	var glow_color: Color
	var core_color: Color
	
	if type == "energy": # Lightning (Blue)
		glow_color = Color(0.12, 0.53, 0.90, 0.4)
		core_color = Color(0.60, 0.85, 1.00)
		
		# Draw Lightning Bolt
		var points = PackedVector2Array([
			Vector2(pos.x + 6, pos.y + 0),
			Vector2(pos.x + 2, pos.y + 7),
			Vector2(pos.x + 5, pos.y + 7),
			Vector2(pos.x + 3, pos.y + 12),
			Vector2(pos.x + 9, pos.y + 5),
			Vector2(pos.x + 6, pos.y + 5),
			Vector2(pos.x + 8, pos.y + 0),
			Vector2(pos.x + 6, pos.y + 0)
		])
		$StatOverlay.draw_polyline(points, glow_color, 3.5, true)
		$StatOverlay.draw_polyline(points, core_color, 1.5, true)
		
	elif type == "attack": # Sword (Red)
		glow_color = Color(0.95, 0.20, 0.20, 0.4)
		core_color = Color(1.00, 0.70, 0.70)
		
		# Draw Sword
		# Blade
		$StatOverlay.draw_line(Vector2(pos.x + 5, pos.y + 0), Vector2(pos.x + 5, pos.y + 8), glow_color, 3.5)
		$StatOverlay.draw_line(Vector2(pos.x + 5, pos.y + 0), Vector2(pos.x + 5, pos.y + 8), core_color, 1.5)
		# Guard
		$StatOverlay.draw_line(Vector2(pos.x + 2, pos.y + 8), Vector2(pos.x + 8, pos.y + 8), glow_color, 3.5)
		$StatOverlay.draw_line(Vector2(pos.x + 2, pos.y + 8), Vector2(pos.x + 8, pos.y + 8), core_color, 1.5)
		# Handle
		$StatOverlay.draw_line(Vector2(pos.x + 5, pos.y + 8), Vector2(pos.x + 5, pos.y + 12), glow_color, 3.5)
		$StatOverlay.draw_line(Vector2(pos.x + 5, pos.y + 8), Vector2(pos.x + 5, pos.y + 12), core_color, 1.5)
		
	else: # Health (Green)
		glow_color = Color(0.20, 0.85, 0.30, 0.4)
		core_color = Color(0.70, 1.00, 0.80)
		
		# Draw Heart
		var points = PackedVector2Array([
			Vector2(pos.x + 5, pos.y + 3),
			Vector2(pos.x + 2.5, pos.y + 0.5),
			Vector2(pos.x + 0, pos.y + 3),
			Vector2(pos.x + 5, pos.y + 11),
			Vector2(pos.x + 10, pos.y + 3),
			Vector2(pos.x + 7.5, pos.y + 0.5),
			Vector2(pos.x + 5, pos.y + 3)
		])
		$StatOverlay.draw_polyline(points, glow_color, 3.5, true)
		$StatOverlay.draw_polyline(points, core_color, 1.5, true)

	# Draw "xValue"
	$StatOverlay.draw_string(label_font, Vector2(pos.x + 15, pos.y + 10), "x" + str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.95, 0.95))

# Update this part in card_base.gd
func _gui_input(event):
	if not in_hand:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			original_position = global_position
			z_index = 10 
			rotation = 0.0
			scale = Vector2.ONE
		elif dragging:
			dragging = false
			z_index = 0
			check_drop()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() - size / 2.0
		update_drag_hand_reorder()
	
	_update_tooltip_state()

func update_drag_hand_reorder():
	if not in_hand:
		return
	var hand_node = get_parent()
	if not hand_node or hand_node.name != "PlayerHand":
		return
		
	var mouse_pos = get_global_mouse_position()
	# Only reorder if dragging near or inside the hand area vertically
	if mouse_pos.y < 350.0:
		return
		
	var cards = hand_node.get_children()
	var current_idx = get_index()
	
	var target_idx = 0
	for i in range(cards.size()):
		if cards[i] == self:
			continue
		var card_center_x = cards[i].global_position.x + cards[i].size.x / 2.0
		if mouse_pos.x > card_center_x:
			target_idx += 1
			
	if target_idx != current_idx:
		hand_node.move_child(self, target_idx)

func check_drop():
	dragging = false
	var mouse_pos = get_global_mouse_position()
	
	var main_node = get_tree().root.get_node("Main")
	var board_node = main_node.get_node("Board")
	var lanes = board_node.get_children()
	
	for lane in lanes:
		if lane.get_global_rect().has_point(mouse_pos):
			if lane.has_method("receive_card") and lane.is_empty():
				if main_node.player_energy >= data.energy_cost:
					if lane.receive_card(self):
						main_node.player_energy -= data.energy_cost
						main_node.cards_played_this_turn += 1
						main_node.update_ui()
						if main_node.has_method("animate_energy_change"):
							main_node.animate_energy_change()
						dragging = false
						# Keep process active for tooltip updates
						return
				else:
					main_node.show_warning_message("Not enough energy! Needs " + str(data.energy_cost))

	# If no valid lane or not enough energy, snap back 
	if in_hand:
		_update_layout()
	else:
		global_position = original_position


func _exit_tree():
	_hide_tooltip()


func _update_tooltip_state():
	var should_show = false
	if not dragging and is_hovered:
		var mouse_pos = get_local_mouse_position()
		if mouse_pos.x >= 0.0 and mouse_pos.x <= 60.0 and mouse_pos.y >= 0.0 and mouse_pos.y <= 70.0:
			var is_any_card_dragging = false
			var main_node = get_tree().root.get_node_or_null("Main")
			if main_node:
				var hand_node = main_node.get_node_or_null("UI/PlayerHand")
				if hand_node:
					for card in hand_node.get_children():
						if card.get("dragging"):
							is_any_card_dragging = true
							break
			if not is_any_card_dragging:
				should_show = true
				
	if should_show:
		if active_tooltip == null:
			_show_tooltip()
		else:
			_position_tooltip()
	else:
		if active_tooltip != null:
			_hide_tooltip()


func _show_tooltip():
	if data == null:
		return
		
	active_tooltip = CardTooltip.new(data.card_name, data.energy_cost, data.attack, data.health, data.ability_text)
	
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_node("UI"):
		main_node.get_node("UI").add_child(active_tooltip)
	else:
		get_tree().root.add_child(active_tooltip)
		
	_position_tooltip()


func _position_tooltip():
	if active_tooltip == null:
		return
		
	active_tooltip.reset_size()
	
	var tooltip_w = active_tooltip.size.x
	var tooltip_h = active_tooltip.size.y
	
	var card_global_pos = global_position
	var card_w = size.x * scale.x
	
	# Position centered above the card, 12px gap
	var tx = card_global_pos.x + (card_w - tooltip_w) / 2.0
	var ty = card_global_pos.y - tooltip_h - 12.0
	
	var screen_w = get_viewport_rect().size.x
	var screen_h = get_viewport_rect().size.y
	
	tx = clamp(tx, 10.0, screen_w - tooltip_w - 10.0)
	ty = clamp(ty, 10.0, screen_h - tooltip_h - 10.0)
	
	active_tooltip.global_position = Vector2(tx, ty)


func _hide_tooltip():
	if active_tooltip != null:
		active_tooltip.queue_free()
		active_tooltip = null


# ─────────────────────────────────────────
#  CardTooltip Nested Class
# ─────────────────────────────────────────
class CardTooltip extends PanelContainer:
	func _init(card_name: String, energy: int, attack: int, health: int, ability_text: String):
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.03, 0.08, 0.04, 0.95) # Dark casino felt
		sb.border_color = Color(0.72, 0.57, 0.17) # Gold
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		add_theme_stylebox_override("panel", sb)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		add_child(vbox)
		
		var font_serif = SystemFont.new()
		font_serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
		font_serif.font_weight = 700
		
		# Title (Gold, Serif)
		var title_lbl = Label.new()
		title_lbl.text = card_name
		title_lbl.add_theme_font_override("font", font_serif)
		title_lbl.add_theme_font_size_override("font_size", 13)
		title_lbl.add_theme_color_override("font_color", Color(0.83, 0.66, 0.16))
		vbox.add_child(title_lbl)
		
		# Stats (Beige, Serif)
		var stats_lbl = Label.new()
		stats_lbl.text = "Energy: %d | Atk: %d | HP: %d" % [energy, attack, health]
		stats_lbl.add_theme_font_override("font", font_serif)
		stats_lbl.add_theme_font_size_override("font_size", 10)
		stats_lbl.add_theme_color_override("font_color", Color(0.91, 0.77, 0.42))
		vbox.add_child(stats_lbl)
		
		# Divider
		var divider = ColorRect.new()
		divider.custom_minimum_size = Vector2(0, 1)
		divider.color = Color(0.72, 0.57, 0.17, 0.3)
		vbox.add_child(divider)
		
		# Ability (Italic Georgia, White)
		if not ability_text.is_empty():
			var ability_lbl = Label.new()
			ability_lbl.text = ability_text
			ability_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			ability_lbl.custom_minimum_size = Vector2(176, 0)
			
			var font_italic = SystemFont.new()
			font_italic.font_names = PackedStringArray(["Georgia", "Times New Roman"])
			font_italic.font_italic = true
			
			ability_lbl.add_theme_font_override("font", font_italic)
			ability_lbl.add_theme_font_size_override("font_size", 10)
			ability_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
			vbox.add_child(ability_lbl)
