extends PanelContainer

var occupied_card = null

# Ensure this function is exactly as written here
func is_empty() -> bool:
	return occupied_card == null

func receive_card(card_node):
	if is_empty():
		occupied_card = card_node
		# Use the Marker2D you created in Lane.tscn 
		card_node.global_position = $DropZone/CardPos.global_position
		return true
	return false
# Add this to Lane.gd
func get_card_attack() -> int:
	if occupied_card and occupied_card.data:
		return occupied_card.data.attack
	return 0

func take_damage(amount: int):
	if occupied_card:
		occupied_card.data.health -= amount
		# Update the visual label on the card [cite: 5]
		occupied_card.setup_card(occupied_card.data) 
		
		if occupied_card.data.health <= 0:
			print("Card defeated!")
			occupied_card.queue_free() # Remove from screen
			occupied_card = null
