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
