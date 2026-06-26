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

var name_label: Label
var cost_label: Label
var health_label: Label
var attack_label: Label
var ability_label: Label

func setup_card(card_data: CardData):
	data = card_data
	
	name_label = get_node("HBox/ContentVBox/NameLabel")
	cost_label = get_node("HBox/ContentVBox/StatsHBox/Energy Cost")
	health_label = get_node("HBox/ContentVBox/StatsHBox/Health")
	attack_label = get_node("HBox/ContentVBox/StatsHBox/Attack")
	ability_label = get_node("HBox/ContentVBox/AbilityLabel")
	
	name_label.text = data.card_name
	cost_label.text = "E: " + str(data.energy_cost)
	attack_label.text = "A: " + str(data.attack)
	health_label.text = "H: " + str(data.health)
	ability_label.text = data.ability_text
	get_node("HBox/ArtContainer/CardArt").texture = data.card_art
	
	_apply_fonts_and_styles()

func _apply_fonts_and_styles():
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	serif.font_weight = 700
	
	name_label.add_theme_font_override("font", serif)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	ability_label.add_theme_font_size_override("font_size", 9)
	ability_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	cost_label.add_theme_font_override("font", serif)
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.add_theme_color_override("font_color", Color(0.831, 0.659, 0.165)) # casino gold
	
	attack_label.add_theme_font_override("font", serif)
	attack_label.add_theme_font_size_override("font_size", 10)
	attack_label.add_theme_color_override("font_color", Color(0.753, 0.224, 0.169)) # dealer red
	
	health_label.add_theme_font_override("font", serif)
	health_label.add_theme_font_size_override("font_size", 10)
	health_label.add_theme_color_override("font_color", Color(0.165, 0.659, 0.29)) # green
	
	var panel_box = StyleBoxFlat.new()
	panel_box.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	panel_box.set_border_width_all(1)
	
	var name_lower = data.card_name.to_lower()
	if "jackpot" in name_lower:
		panel_box.border_color = Color(0.831, 0.659, 0.165)
		panel_box.set_border_width_all(2)
	elif "pit boss" in name_lower or "high roller" in name_lower:
		panel_box.border_color = Color(0.7, 0.7, 0.75)
		panel_box.set_border_width_all(2)
	else:
		panel_box.border_color = Color(0.25, 0.25, 0.25)
		
	panel_box.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", panel_box)

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

