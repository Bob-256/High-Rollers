extends Node2D

@onready var deck_manager = $DeckManager
@onready var opponent_manager = $OpponentManager

var current_turn: int = 1
var player_energy: int = 1

var player_hp: int = 20
var opponent_hp: int = 20

const MAX_ENERGY = 6

var cards_played_this_turn: int = 0

func _ready():
	opponent_manager.prepare_deck()
	start_player_turn()

func end_turn():
	# Block turn end if no cards played AND player has valid moves they could make
	if cards_played_this_turn == 0 and has_valid_plays():
		show_warning_message("Must play at least one card!")
		return
		
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

func has_valid_plays() -> bool:
	for card_data in deck_manager.hand:
		if card_data.energy_cost <= player_energy:
			for lane in $Board.get_children():
				if lane.is_empty():
					return true
	return false

func show_warning_message(text: String):
	if $UI.has_node("WarningLabel"):
		$UI/WarningLabel.queue_free()
		
	var lbl = Label.new()
	lbl.name = "WarningLabel"
	lbl.text = text
	# Position in the center of the screen
	lbl.offset_left = 376.0
	lbl.offset_top = 10.0
	lbl.offset_right = 776.0
	lbl.offset_bottom = 50.0
	
	# Style it matching casino noir colors (gold border warning)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia"])
	serif.font_weight = 700
	lbl.add_theme_font_override("font", serif)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.753, 0.224, 0.169)) # dealer red
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	$UI.add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.2).set_delay(0.8)
	tween.tween_callback(lbl.queue_free)

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

func animate_energy_change():
	var energy_lbl = $UI/EnergyDisplay
	energy_lbl.pivot_offset = energy_lbl.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(energy_lbl, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(energy_lbl, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func start_player_turn():
	cards_played_this_turn = 0
	player_energy = min(current_turn + 2, MAX_ENERGY)
	while deck_manager.hand.size() < 5:
		deck_manager.draw_card($UI/PlayerHand)
	update_ui()
