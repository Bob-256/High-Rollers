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
	# Logic for units to attack forward would go here
	current_turn += 1
	start_player_turn()

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
	# Draw until hand is full or deck empty [cite: 5]
	deck_manager.draw_card($UI/PlayerHand)
	update_ui()
