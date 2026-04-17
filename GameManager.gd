extends Node2D
@onready var deck_manager = $DeckManager
var current_turn: int = 1
var player_energy: int = 1
var player_score: int = 0
const MAX_ENERGY = 6
const WIN_SCORE = 10

func _ready():
	start_player_turn()

func end_turn():
	resolve_combat()
	current_turn += 1
	start_player_turn()

func resolve_combat():
	# Reference your Board's lanes from the HBoxContainer 
	var lanes = $Board.get_children()
	
	for lane in lanes:
		if !lane.is_empty():
			var damage = lane.get_card_attack()
			# Inside the loop after add_score(damage)
			var vfx = lane.get_node("VFXSpawner")
			# Simple visual feedback: Shake the lane slightly
			var tween = create_tween()
			tween.tween_property(lane, "position:y", lane.position.y - 10, 0.1)
			tween.tween_property(lane, "position:y", lane.position.y, 0.1)
			# Check Opponent (For the prototype, we'll assume direct damage to score)
			# In a full game, you'd check the opponent's matching lane here
			print("Lane attacks for: ", damage)
			add_score(damage) # Directly adds to the 0-10 Score Meter
			

func add_score(amount: int):
	player_score += amount
	if player_score >= WIN_SCORE:
		print("Victory!") # Trigger "Flashy effects" here
	update_ui()

func update_ui():
	$UI/EnergyDisplay.text = "Energy: " + str(player_energy)
	$UI/ProgressBar.value = player_score # Tracks 0-10 win condition

func start_player_turn():
	player_energy = min(current_turn, MAX_ENERGY)
	# Loop to draw until the player has a full hand (e.g., 5 cards)
	while deck_manager.hand.size() < 5:
		deck_manager.draw_card($UI/PlayerHand)
	update_ui()
