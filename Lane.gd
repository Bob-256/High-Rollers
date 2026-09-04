extends PanelContainer

var player_card = null
var opponent_card = null

func _ready():
	_apply_styling()
	
	var num = name.replace("Lane", "")
	$VBox/LaneLabel.text = "LANE " + num

func _apply_styling():
	var col_player_bg     := Color(0.051, 0.122, 0.071, 0.4)
	var col_player_border := Color(0.722, 0.569, 0.165, 0.8)
	
	var col_opp_bg         := Color(0.051, 0.122, 0.071, 0.4)
	var col_opp_border     := Color(0.420, 0.067, 0.067, 0.8)
	
	var player_box = StyleBoxFlat.new()
	player_box.bg_color = col_player_bg
	player_box.border_color = col_player_border
	player_box.set_border_width_all(2)
	player_box.set_corner_radius_all(6)
	
	var opp_box = StyleBoxFlat.new()
	opp_box.bg_color = col_opp_bg
	opp_box.border_color = col_opp_border
	opp_box.set_border_width_all(2)
	opp_box.set_corner_radius_all(6)
	
	$VBox/PlayerSlot.add_theme_stylebox_override("panel", player_box)
	$VBox/OpponentSlot.add_theme_stylebox_override("panel", opp_box)
	
	var main_box = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", main_box)
	
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray([
		"Georgia", "Palatino Linotype", "Palatino",
		"Book Antiqua", "Times New Roman"
	])
	serif.font_weight = 700
	
	$VBox/LaneLabel.add_theme_font_override("font", serif)
	$VBox/LaneLabel.add_theme_color_override("font_color", Color(0.722, 0.569, 0.165))
	$VBox/LaneLabel.add_theme_font_size_override("font_size", 14)

func is_empty() -> bool:
	return player_card == null

func receive_card(card_node) -> bool:
	if player_card == null:
		player_card = card_node
		
		card_node.in_hand = false
		card_node.rotation = 0.0
		card_node.scale = Vector2.ONE
		
		var global_start_pos = card_node.global_position
		card_node.get_parent().remove_child(card_node)
		$VBox/PlayerSlot.add_child(card_node)
		
		# Set to previous global pos so tween can slide it back to (0,0)
		card_node.global_position = global_start_pos
		
		var tween = create_tween()
		tween.tween_property(card_node, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		trigger_on_play_ability(card_node, true)
		return true
	return false

func receive_opponent_card(card_node) -> bool:
	if opponent_card == null:
		opponent_card = card_node
		
		card_node.in_hand = false
		card_node.rotation = 0.0
		card_node.scale = Vector2.ONE
		
		var global_start_pos = card_node.global_position
		if card_node.get_parent():
			card_node.get_parent().remove_child(card_node)
		$VBox/OpponentSlot.add_child(card_node)
		
		card_node.global_position = global_start_pos
		
		var tween = create_tween()
		tween.tween_property(card_node, "position", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		trigger_on_play_ability(card_node, false)
		return true
	return false

func trigger_on_play_ability(card_node, is_player: bool):
	if card_node == null or card_node.data == null:
		return
	var gm = get_tree().root.get_node("Main")
	var ability = card_node.data.card_name.to_lower()
	
	if "dealer" in ability:
		# Draw an extra card instantly
		if is_player:
			gm.deck_manager.draw_card(gm.get_node("UI/PlayerHand"))
		else:
			gm.opponent_manager.draw_card()
			
	elif "bouncer" in ability:
		# Deal 2 damage directly to the opponent's card in this lane
		var blocker = opponent_card if is_player else player_card
		if blocker:
			blocker.data.health -= 2
			blocker.setup_card(blocker.data)
			if blocker.data.health <= 0:
				blocker.queue_free()
				if is_player:
					opponent_card = null
				else:
					player_card = null
					
	elif "pit boss" in ability:
		# Give all other friendly fielded cards +1 Atk and +1 HP
		var board = get_parent()
		for lane in board.get_children():
			var ally = lane.player_card if is_player else lane.opponent_card
			if ally and ally != card_node:
				ally.data.attack += 1
				ally.data.health += 1
				ally.setup_card(ally.data)

# Resolves combat in this lane.
# Returns a Dictionary: {"player_direct": int, "opponent_direct": int}
func resolve_lane_combat() -> Dictionary:
	var result = {"player_direct": 0, "opponent_direct": 0}
	
	if player_card != null and opponent_card != null:
		var p_atk = player_card.data.attack
		var o_atk = opponent_card.data.attack
		
		# Visual strike tween
		var tween = create_tween().set_parallel(true)
		tween.tween_property(player_card, "position:y", -15.0, 0.1)
		tween.tween_property(opponent_card, "position:y", 15.0, 0.1)
		
		tween.chain().set_parallel(true)
		tween.tween_property(player_card, "position:y", 0.0, 0.1)
		tween.tween_property(opponent_card, "position:y", 0.0, 0.1)
		
		# Resolve Armor for Slot Guard (Common Tank)
		var p_damage = o_atk
		var o_damage = p_atk
		if "slot guard" in player_card.data.card_name.to_lower():
			p_damage = max(0, o_atk - 1)
		if "slot guard" in opponent_card.data.card_name.to_lower():
			o_damage = max(0, p_atk - 1)
			
		# Apply damage
		player_card.data.health -= p_damage
		player_card.setup_card(player_card.data)
		
		opponent_card.data.health -= o_damage
		opponent_card.setup_card(opponent_card.data)
		
		# Resolve Jackpot King bonus direct damage
		if "jackpot king" in player_card.data.card_name.to_lower():
			result["opponent_direct"] += 2
		if "jackpot king" in opponent_card.data.card_name.to_lower():
			result["player_direct"] += 2
			
		# Check defeats
		if player_card.data.health <= 0:
			player_card.queue_free()
			player_card = null
		else:
			# High Roller gains +1 Atk if it survives combat
			if "high roller" in player_card.data.card_name.to_lower():
				player_card.data.attack += 1
				player_card.setup_card(player_card.data)
				
		if opponent_card.data.health <= 0:
			opponent_card.queue_free()
			opponent_card = null
		else:
			# High Roller gains +1 Atk if it survives combat
			if "high roller" in opponent_card.data.card_name.to_lower():
				opponent_card.data.attack += 1
				opponent_card.setup_card(opponent_card.data)
			
	elif player_card != null and opponent_card == null:
		# Direct attack to opponent
		var damage = player_card.data.attack
		if "jackpot king" in player_card.data.card_name.to_lower():
			damage += 2 # Extra direct damage for Jackpot King
		result["opponent_direct"] = damage
		
		var tween = create_tween()
		tween.tween_property(player_card, "position:y", -25.0, 0.1)
		tween.tween_property(player_card, "position:y", 0.0, 0.1)
		
		# High Roller gains +1 Atk on survival (always gains when attacking directly)
		if "high roller" in player_card.data.card_name.to_lower():
			player_card.data.attack += 1
			player_card.setup_card(player_card.data)
		
	elif opponent_card != null and player_card == null:
		# Direct attack to player
		var damage = opponent_card.data.attack
		if "jackpot king" in opponent_card.data.card_name.to_lower():
			damage += 2 # Extra direct damage for Jackpot King
		result["player_direct"] = damage
		
		var tween = create_tween()
		tween.tween_property(opponent_card, "position:y", 25.0, 0.1)
		tween.tween_property(opponent_card, "position:y", 0.0, 0.1)
		
		# High Roller gains +1 Atk on survival (always gains when attacking directly)
		if "high roller" in opponent_card.data.card_name.to_lower():
			opponent_card.data.attack += 1
			opponent_card.setup_card(opponent_card.data)
		
	return result
