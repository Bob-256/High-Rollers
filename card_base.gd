extends Node2D

@export var data: CardData
var dragging = false
var original_position: Vector2

# Connect these to the unique IDs in your Card.tscn 
@onready var cost_label = $"StatLayout/Energy Cost"
@onready var health_label = $StatLayout/Health
@onready var attack_label = $StatLayout/Attack
@onready var ability_label = $AbilityLabel

func setup_card(card_data: CardData):
	data = card_data
	cost_label.text = str(data.energy_cost)
	attack_label.text = str(data.attack)
	health_label.text = str(data.health)
	ability_label.text = data.ability_text

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_viewport().get_mouse_position().distance_to(global_position) < 50:
			dragging = true
			original_position = global_position
		elif dragging:
			dragging = false
			check_drop()

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()

func check_drop():
	# Get the direct space state for 2D physics querying
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true # Detect the DropZone Area2D
	
	var results = space_state.intersect_point(parameters)
	
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
	global_position = original_position
