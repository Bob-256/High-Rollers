extends PanelContainer

var occupied_card = null

# Ensure this function is exactly as written here
func is_empty() -> bool:
	return occupied_card == null

func receive_card(card_node):
	if is_empty():
		occupied_card = card_node
		
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
