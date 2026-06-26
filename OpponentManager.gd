extends Node

@export var card_scene: PackedScene
@export var starter_deck: Array[CardData]

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var energy: int = 1

func prepare_deck():
	draw_pile = starter_deck.duplicate()
	# Duplicate resources to avoid modifying shared references
	for i in range(draw_pile.size()):
		draw_pile[i] = draw_pile[i].duplicate()
		draw_pile[i].init_stats()
	draw_pile.shuffle()

func draw_card():
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return
		reshuffle_discard_into_draw()
		
	var card_data = draw_pile.pop_front()
	hand.append(card_data)

func reshuffle_discard_into_draw():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()

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
		# Sort descending by cost to play high-value cards first
		hand.sort_custom(func(a, b): return a.energy_cost > b.energy_cost)
		
		for card_data in hand:
			if card_data.energy_cost <= energy:
				var target_lane = _choose_best_lane(lanes)
				if target_lane:
					energy -= card_data.energy_cost
					hand.erase(card_data)
					
					# Visual card creation
					var new_card = card_scene.instantiate()
					# Opponent cards cannot be dragged or hovered by the player
					new_card.in_hand = false
					new_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
					
					target_lane.receive_opponent_card(new_card)
					new_card.setup_card(card_data)
					
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
