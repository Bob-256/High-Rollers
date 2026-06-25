extends PanelContainer

var occupied_card = null

func _ready():
	_apply_styling()

func _apply_styling():
	var col_panel_bg     := Color(0.051, 0.122, 0.071, 0.5)   # felt green, semi-transparent
	var col_panel_border := Color(0.722, 0.569, 0.165)         # casino gold
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = col_panel_bg
	style_box.border_color = col_panel_border
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(6)
	
	add_theme_stylebox_override("panel", style_box)
	
	if has_node("Highlight"):
		get_node("Highlight").visible = false

# Ensure this function is exactly as written here
func is_empty() -> bool:
	return occupied_card == null

func receive_card(card_node):
	if is_empty():
		occupied_card = card_node
		
		card_node.in_hand = false
		card_node.rotation = 0.0
		card_node.scale = Vector2.ONE
		
		# FIX: Move the card from the Hand to the Lane in the node tree
		card_node.get_parent().remove_child(card_node)
		add_child(card_node)
		
		# Now that it's a child of the Lane (a PanelContainer), 
		# it will automatically center itself!
		card_node.position = Vector2.ZERO 
		return true
	return false

func take_damage(amount: int):
	if occupied_card:
		occupied_card.data.health -= amount
		# Update the visual label on the card [cite: 5]
		occupied_card.setup_card(occupied_card.data) 
		
		if occupied_card.data.health <= 0:
			print("Card defeated!")
			occupied_card.queue_free() # Remove from screen
			occupied_card = null
