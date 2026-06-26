extends Resource
class_name CardData

@export var card_name: String
@export var energy_cost: int
@export var attack: int
@export var health: int
@export var ability_text: String
@export var card_art: Texture2D

func init_stats():
	var path = resource_path.to_lower()
	if "slotgaurd" in path:
		card_name = "Slot Guard"
		energy_cost = 2
		attack = 1
		health = 5
		ability_text = "Defender (Taunt)"
	elif "cardshark" in path:
		card_name = "Card Shark"
		energy_cost = 3
		attack = 4
		health = 2
		ability_text = "Glass Cannon"
	elif "dealer" in path:
		card_name = "Dealer"
		energy_cost = 1
		attack = 1
		health = 3
		ability_text = "Support"
