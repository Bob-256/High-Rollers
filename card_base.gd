extends PanelContainer

@export var data: CardData
var dragging = false
var original_position: Vector2
# Add these variables to the top of card_base.gd
var hover_scale := Vector2(1.1, 1.1)
var default_scale := Vector2(1.0, 1.0)

func _ready():
	# Connect the mouse signals to these functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if not dragging:
		# Create a smooth scaling animation
		var tween = create_tween()
		tween.tween_property(self, "scale", hover_scale, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		z_index = 5 # Ensure the hovered card is drawn on top of others

func _on_mouse_exited():
	if not dragging:
		# Smoothly return to original size
		var tween = create_tween()
		tween.tween_property(self, "scale", default_scale, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		z_index = 0 # Return to normal layer

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
	
	# NEW LINE: This tells the visual card to show the art you just assigned
	$CardArt.texture = data.card_art

# Update this part in card_base.gd
# Replace your old _input(event) with this:
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Godot already knows the mouse is over the card here!
			dragging = true
			original_position = global_position
			z_index = 10 
		elif dragging:
			dragging = false
			z_index = 0
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
	# If no valid lane or not enough energy, snap back 
	dragging = false
	# Instead of setting global_position, we just let the ffff00
	# HBoxContainer reposition it naturally.ffffff
	position = Vector2.ZERO
	
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
