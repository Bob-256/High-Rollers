extends Node

@export var card_scene: PackedScene

var hand: Array[CardData] = []
var energy: int = 1

@onready var deck_manager = $"../DeckManager"

func prepare_deck():
	# Stub for GameManager compatibility
	pass

func draw_card():
	var card_data = deck_manager.draw_card_for_opponent()
	if card_data:
		hand.append(card_data)

# AI Turn Execution
func execute_ai_turn(lanes: Array, max_energy: int):
	energy = max_energy
	
	# Draw up to 5 cards
	while hand.size() < 5:
		draw_card()
		
	# Play cards heuristic
	var played_any = true
	while played_any:
		played_any = false
		hand.sort_custom(func(a, b): return a.energy_cost > b.energy_cost)
		
		for card_data in hand:
			if card_data.energy_cost <= energy:
				var target_lane = _choose_best_lane(lanes)
				if target_lane:
					energy -= card_data.energy_cost
					hand.erase(card_data)
					
					# Visual card creation
					var new_card = card_scene.instantiate()
					new_card.in_hand = false
					new_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
					
					new_card.setup_card(card_data)
					target_lane.receive_opponent_card(new_card)
					
					played_any = true
					break

func _choose_best_lane(lanes: Array) -> Node:
	# Priority 1: Lanes where player has a card, but opponent does not (block player attack)
	for lane in lanes:
		if lane.opponent_card == null and lane.player_card != null:
			return lane
			
	# Priority 2: Completely empty lanes
	for lane in lanes:
		if lane.opponent_card == null and lane.player_card == null:
			return lane
			
	return null
