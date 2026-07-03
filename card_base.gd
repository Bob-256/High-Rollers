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
	if not dragging and in_hand:
		is_hovered = true
		_update_layout()

func _on_mouse_exited():
	if not dragging and in_hand:
		is_hovered = false
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
	
	# Rich detailed tooltip on hover
	tooltip_text = data.card_name + "\n" + \
		"Energy: " + str(data.energy_cost) + " | Attack: " + str(data.attack) + " | Health: " + str(data.health) + "\n\n" + \
		data.ability_text
	
	_apply_fonts_and_styles()
	$StatOverlay.queue_redraw()

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
						set_process(false)
						return
				else:
					main_node.show_warning_message("Not enough energy! Needs " + str(data.energy_cost))

	# If no valid lane or not enough energy, snap back 
	if in_hand:
		_update_layout()
	else:
		global_position = original_position
