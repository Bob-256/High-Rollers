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
		
		card_node.get_parent().remove_child(card_node)
		$VBox/PlayerSlot.add_child(card_node)
		card_node.position = Vector2.ZERO 
		return true
	return false

func receive_opponent_card(card_node) -> bool:
	if opponent_card == null:
		opponent_card = card_node
		
		card_node.in_hand = false
		card_node.rotation = 0.0
		card_node.scale = Vector2.ONE
		
		if card_node.get_parent():
			card_node.get_parent().remove_child(card_node)
		$VBox/OpponentSlot.add_child(card_node)
		card_node.position = Vector2.ZERO 
		return true
	return false

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
		
		# Apply damage
		player_card.data.health -= o_atk
		player_card.setup_card(player_card.data)
		
		opponent_card.data.health -= p_atk
		opponent_card.setup_card(opponent_card.data)
		
		# Check defeats
		if player_card.data.health <= 0:
			player_card.queue_free()
			player_card = null
		if opponent_card.data.health <= 0:
			opponent_card.queue_free()
			opponent_card = null
			
	elif player_card != null and opponent_card == null:
		# Direct attack to opponent
		result["opponent_direct"] = player_card.data.attack
		
		var tween = create_tween()
		tween.tween_property(player_card, "position:y", -25.0, 0.1)
		tween.tween_property(player_card, "position:y", 0.0, 0.1)
		
	elif opponent_card != null and player_card == null:
		# Direct attack to player
		result["player_direct"] = opponent_card.data.attack
		
		var tween = create_tween()
		tween.tween_property(opponent_card, "position:y", 25.0, 0.1)
		tween.tween_property(opponent_card, "position:y", 0.0, 0.1)
		
	return result
