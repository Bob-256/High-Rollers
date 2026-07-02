extends PanelContainer

@export var data: CardData
var dragging = false
var original_position: Vector2
var hover_scale := Vector2(1.1, 1.1)
var default_scale := Vector2(1.0, 1.0)

var hand_position := Vector2.ZERO
var hand_rotation := 0.0
var in_hand := true
var is_hovered := false

func _ready():
	# Connect the mouse signals to these functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	$StatOverlay.draw.connect(_on_stat_overlay_draw)

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
	
	var start_x = 10
	var line_len = 8
	var spacing = 3
	
	# Neon stat colors
	var blue_glow = Color(0.12, 0.53, 0.90, 0.35)
	var blue_core = Color(0.60, 0.85, 1.00)
	
	var red_glow = Color(0.95, 0.20, 0.20, 0.35)
	var red_core = Color(1.00, 0.70, 0.70)
	
	var green_glow = Color(0.20, 0.85, 0.30, 0.35)
	var green_core = Color(0.70, 1.00, 0.80)
	
	# Draw Energy (Blue) - Row 1
	var y_energy = 12
	for i in range(max(0, data.energy_cost)):
		var x = start_x + i * (line_len + spacing)
		$StatOverlay.draw_line(Vector2(x, y_energy), Vector2(x + line_len, y_energy), blue_glow, 5.0)
		$StatOverlay.draw_line(Vector2(x, y_energy), Vector2(x + line_len, y_energy), blue_core, 2.0)
		
	# Draw Attack (Red) - Row 2
	var y_attack = 22
	for i in range(max(0, data.attack)):
		var x = start_x + i * (line_len + spacing)
		$StatOverlay.draw_line(Vector2(x, y_attack), Vector2(x + line_len, y_attack), red_glow, 5.0)
		$StatOverlay.draw_line(Vector2(x, y_attack), Vector2(x + line_len, y_attack), red_core, 2.0)
		
	# Draw Health (Green) - Row 3
	var y_health = 32
	for i in range(max(0, data.health)):
		var x = start_x + i * (line_len + spacing)
		$StatOverlay.draw_line(Vector2(x, y_health), Vector2(x + line_len, y_health), green_glow, 5.0)
		$StatOverlay.draw_line(Vector2(x, y_health), Vector2(x + line_len, y_health), green_core, 2.0)

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

