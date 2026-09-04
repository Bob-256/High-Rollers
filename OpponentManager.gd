extends Node

@export var card_scene: PackedScene
@export var profile: Resource

var hand: Array[CardData] = []
var energy: int = 1

@onready var deck_manager = $"../DeckManager"

func _ready():
	# Create visual hand container dynamically
	var opp_hand = Control.new()
	opp_hand.name = "OpponentHand"
	opp_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opp_hand.layout_mode = 3
	opp_hand.anchors_preset = 5 # Top Center
	opp_hand.anchor_left = 0.5
	opp_hand.anchor_right = 0.5
	opp_hand.anchor_top = 0.0
	opp_hand.anchor_bottom = 0.0
	opp_hand.offset_left = -400.0
	opp_hand.offset_top = -90.0
	opp_hand.offset_right = 400.0
	opp_hand.offset_bottom = 110.0
	opp_hand.grow_horizontal = 2
	opp_hand.grow_vertical = 1
	
	opp_hand.set_script(preload("res://OpponentHand.gd"))
	
	var ui = get_node("../UI")
	if ui:
		ui.add_child(opp_hand)

func prepare_deck():
	# Stub for GameManager compatibility
	pass

func draw_card():
	var card_data = deck_manager.draw_card_for_opponent()
	if card_data:
		hand.append(card_data)
		
		var opp_hand_node = get_node("../UI/OpponentHand")
		if opp_hand_node:
			var new_card = card_scene.instantiate()
			new_card.face_down = true
			opp_hand_node.add_child(new_card)
			new_card.setup_card(card_data)

# AI Turn Execution (yields between actions for premium visual pacing)
func execute_ai_turn(lanes: Array, max_energy: int):
	energy = max_energy
	
	# Draw up to 5 cards
	while hand.size() < 5:
		draw_card()
		await get_tree().create_timer(0.15).timeout
		
	# Fallback default profile if not set
	var active_profile = profile
	if active_profile == null:
		active_profile = preload("res://OpponentProfile.gd").new() # Default Balanced Medium AI
		
	var difficulty = active_profile.difficulty
	print("Opponent AI starting turn using profile: ", active_profile.opponent_name, " (", difficulty, " / ", active_profile.play_style, ")")
	
	var played_any = true
	while played_any:
		played_any = false
		
		# 1. Filter hand for affordable cards
		var affordable_cards: Array[CardData] = []
		for card in hand:
			if card.energy_cost <= energy:
				affordable_cards.append(card)
				
		if affordable_cards.is_empty():
			break
			
		# 2. Filter lanes for empty opponent slots
		var empty_lanes = []
		for lane in lanes:
			if lane.opponent_card == null:
				empty_lanes.append(lane)
				
		if empty_lanes.is_empty():
			break
			
		# 3. Choose the best move based on difficulty
		var selected_card: CardData = null
		var selected_lane: Node = null
		
		if difficulty == "EASY":
			# Pick random affordable card and random empty lane
			selected_card = affordable_cards.pick_random()
			selected_lane = empty_lanes.pick_random()
			
			# Easy bot has 25% chance to end turn early
			if randf() < 0.25:
				print("Easy bot decides to pass turn early!")
				break
				
		elif difficulty == "MEDIUM":
			# Heuristic rule-based strategy
			var play_style = active_profile.play_style
			
			# Sort affordable cards by energy cost descending to play big cards first
			affordable_cards.sort_custom(func(a, b): return a.energy_cost > b.energy_cost)
			selected_card = affordable_cards[0]
			
			# Choose lane based on style
			if play_style == "DEFENSIVE":
				# Try to block the player's card with the highest attack
				var highest_threat_lane: Node = null
				var max_threat = -1
				for lane in empty_lanes:
					if lane.player_card != null and lane.player_card.data.attack > max_threat:
						max_threat = lane.player_card.data.attack
						highest_threat_lane = lane
				
				if highest_threat_lane:
					selected_lane = highest_threat_lane
				else:
					selected_lane = empty_lanes.pick_random()
					
			elif play_style == "AGGRESSIVE":
				# Try to find a lane where player has NO card (so we can deal direct damage)
				var open_lanes = []
				for lane in empty_lanes:
					if lane.player_card == null:
						open_lanes.append(lane)
						
				if not open_lanes.is_empty():
					selected_lane = open_lanes.pick_random()
				else:
					selected_lane = empty_lanes.pick_random()
					
			else: # BALANCED / default
				# Try to block first; if no player threats, attack empty lanes
				var threat_lanes = []
				var open_lanes = []
				for lane in empty_lanes:
					if lane.player_card != null:
						threat_lanes.append(lane)
					else:
						open_lanes.append(lane)
						
				if not threat_lanes.is_empty():
					selected_lane = threat_lanes.pick_random()
				elif not open_lanes.is_empty():
					selected_lane = open_lanes.pick_random()
				else:
					selected_lane = empty_lanes.pick_random()
					
		else: # HARD (Simulation / Utility scoring)
			var best_score = -9999.0
			
			for card in affordable_cards:
				for lane in empty_lanes:
					var score = _evaluate_move(card, lane, active_profile)
					if score > best_score:
						best_score = score
						selected_card = card
						selected_lane = lane
						
		# 4. Play the chosen card
		if selected_card != null and selected_lane != null:
			energy -= selected_card.energy_cost
			hand.erase(selected_card)
			
			var visual_card = null
			var opp_hand_node = get_node("../UI/OpponentHand")
			if opp_hand_node:
				for child in opp_hand_node.get_children():
					if child.data == selected_card:
						visual_card = child
						break
						
			if visual_card:
				# Flip card face-up with animation
				visual_card.set_face_down(false, true)
				# Wait 0.15s to switch parent and slide during the flip
				await get_tree().create_timer(0.15).timeout
				selected_lane.receive_opponent_card(visual_card)
			else:
				# Fallback
				var new_card = card_scene.instantiate()
				new_card.in_hand = false
				new_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
				new_card.setup_card(selected_card)
				selected_lane.receive_opponent_card(new_card)
			
			played_any = true
			
			# Visual pause between card plays (0.5s)
			await get_tree().create_timer(0.5).timeout

# Scoring function simulating combat resolution outcomes
func _evaluate_move(card_data: CardData, lane: Node, active_profile: Resource) -> float:
	var score = 0.0
	
	# Determine names/abilities
	var name_lower = card_data.card_name.to_lower()
	
	# ─── 1. Evaluate "On Play" effects ───
	if "dealer" in name_lower: # On Play: Draw 1 card
		# If hand is not full, drawing is useful
		if hand.size() < 5:
			score += active_profile.weight_hand_size * 2.0
			
	elif "bouncer" in name_lower: # On Play: Deal 2 damage to blocker
		if lane.player_card != null:
			var blocker = lane.player_card
			var blocker_hp = blocker.data.health
			
			# If 2 damage kills the player's card, huge reward
			if blocker_hp <= 2:
				score += active_profile.weight_kill_enemy * 2.0
			else:
				# Otherwise reward for softening it up
				score += 2.0 * active_profile.weight_damage * 0.5
				
	elif "pit boss" in name_lower: # On Play: Friendly cards +1/+1
		# Count other friendly cards on board
		var allies_count = 0
		var board = lane.get_parent()
		if board:
			for other_lane in board.get_children():
				if other_lane != lane and other_lane.opponent_card != null:
					allies_count += 1
		score += allies_count * active_profile.weight_buff_allies * 1.5
		
	# ─── 2. Evaluate Combat Resolution Simulation ───
	if lane.player_card != null:
		# Blocked combat
		var player_card = lane.player_card
		var p_atk = player_card.data.attack
		var p_hp = player_card.data.health
		var o_atk = card_data.attack
		var o_hp = card_data.health
		
		# Resolve armor modifications (Slot Guard)
		var p_damage = o_atk
		var o_damage = p_atk
		if "slot guard" in player_card.data.card_name.to_lower():
			p_damage = max(0, o_atk - 1)
		if "slot guard" in name_lower:
			o_damage = max(0, p_atk - 1)
			
		var p_remaining_hp = p_hp - p_damage
		var o_remaining_hp = o_hp - o_damage
		
		# Did we defeat the player card?
		if p_remaining_hp <= 0:
			score += active_profile.weight_kill_enemy
			
		# Did our card die?
		if o_remaining_hp <= 0:
			score -= active_profile.weight_kill_ally
		else:
			# Our card survives!
			score += 0.2 # small baseline reward for keeping presence
			
			# If it is a High Roller, it gains attack
			if "high roller" in name_lower:
				score += 0.3 * active_profile.weight_buff_allies
				
			# Health percentage preservation
			score += (float(o_remaining_hp) / float(o_hp)) * 0.2
			
		# Evaluate Jackpot King bonus direct damage during combat
		if "jackpot king" in name_lower:
			score += 2.0 * active_profile.weight_damage
		if "jackpot king" in player_card.data.card_name.to_lower():
			score -= 2.0 * active_profile.weight_damage * 0.5 # Penalty for receiving jackpot damage
			
		# General block scoring (relieving player pressure in this lane)
		score += p_atk * active_profile.weight_block * 0.8
		
	else:
		# Unblocked combat (attacking player directly!)
		var o_atk = card_data.attack
		score += o_atk * active_profile.weight_damage
		
		# Jackpot King bonus
		if "jackpot king" in name_lower:
			score += 2.0 * active_profile.weight_damage
			
		# High Roller survives and grows
		if "high roller" in name_lower:
			score += 0.3 * active_profile.weight_buff_allies
			
		# Card survives unblocked
		score += 0.3
		
	# ─── 3. Inject Valuation Noise ───
	if active_profile.valuation_noise > 0.0:
		score += randf_range(-active_profile.valuation_noise, active_profile.valuation_noise)
		
	return score
