extends Node2D

@onready var deck_manager = $DeckManager
@onready var opponent_manager = $OpponentManager

var current_turn: int = 1
var player_energy: int = 1

var player_hp: int = 20
var opponent_hp: int = 20

const MAX_ENERGY = 6

func _ready():
	opponent_manager.prepare_deck()
	start_player_turn()

func end_turn():
	$UI/EndTurnButton.disabled = true
	
	# 1. Opponent Turn (AI plays cards)
	var lanes = $Board.get_children()
	opponent_manager.execute_ai_turn(lanes, min(current_turn, MAX_ENERGY))
	
	# Wait for card placements to settle
	await get_tree().create_timer(0.6).timeout
	
	# 2. Combat Resolution Phase
	for lane in lanes:
		# Visual cue: Shake the lane
		var tween = create_tween()
		tween.tween_property(lane, "position:x", -5.0, 0.05)
		tween.tween_property(lane, "position:x", 5.0, 0.05)
		tween.tween_property(lane, "position:x", 0.0, 0.05)
		
		# Resolve combat math and card damage
		var results = lane.resolve_lane_combat()
		
		if results["player_direct"] > 0:
			player_hp -= results["player_direct"]
			print("Player takes direct damage: ", results["player_direct"])
			
		if results["opponent_direct"] > 0:
			opponent_hp -= results["opponent_direct"]
			print("Opponent takes direct damage: ", results["opponent_direct"])
			
		update_ui()
		
		if player_hp <= 0 or opponent_hp <= 0:
			break
			
		# Visual pause between lanes
		await get_tree().create_timer(0.6).timeout
		
	# 3. Check for Game End
	if player_hp <= 0 or opponent_hp <= 0:
		declare_game_over()
		return
		
	# 4. Next Round Setup
	current_turn += 1
	start_player_turn()
	$UI/EndTurnButton.disabled = false

func declare_game_over():
	if player_hp <= 0 and opponent_hp <= 0:
		print("It's a draw!")
	elif player_hp <= 0:
		print("Opponent wins!")
	else:
		print("Player wins!")
		
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func update_ui():
	$UI/EnergyDisplay.text = "Energy: " + str(player_energy)
	if $UI.has_method("update_hp_display"):
		$UI.update_hp_display(player_hp, opponent_hp)

func start_player_turn():
	player_energy = min(current_turn, MAX_ENERGY)
	while deck_manager.hand.size() < 5:
		deck_manager.draw_card($UI/PlayerHand)
	update_ui()
