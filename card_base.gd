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

# Connect these to the unique IDs in your Card.tscn 
@onready var cost_label = $"StatLayout/Energy Cost"
@onready var health_label = $StatLayout/Health
@onready var attack_label = $StatLayout/Attack
@onready var ability_label = $AbilityLabel

func setup_card(card_data: CardData):
	data = card_data
	data.init_stats()
	cost_label.text = str(data.energy_cost)
	attack_label.text = str(data.attack)
	health_label.text = str(data.health)
	ability_label.text = data.ability_text
	
	# NEW LINE: This tells the visual card to show the art you just assigned
	$CardArt.texture = data.card_art

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
	# Get the direct space state for 2D physics querying
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true # Detect the DropZone Area2D
	
	var results = space_state.intersect_point(parameters)
	dragging = false
	
	for result in results:
		var lane = result.collider.get_parent() # Area2D is a child of Lane
		if lane.has_method("receive_card") and lane.is_empty():
			# Check if player has enough energy from GameManager
			var gm = get_tree().root.get_node("Main") 
			if gm.player_energy >= data.energy_cost:
				if lane.receive_card(self):
					gm.player_energy -= data.energy_cost
					gm.update_ui()
					dragging = false
					set_process(false) # Stop dragging logic once played
					return

	# If no valid lane or not enough energy, snap back 
	if in_hand:
		_update_layout()
	else:
		global_position = original_position

