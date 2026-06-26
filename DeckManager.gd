extends Node

@export var card_scene: PackedScene
@export var starter_deck: Array[CardData] 

var communal_deck: Array[CardData] = []
var hand: Array[CardData] = [] # Player hand

func _ready():
	prepare_communal_deck()

func prepare_communal_deck():
	communal_deck.clear()
	
	var archetypes = [
		{"name": "Slot Guard", "cost": 2, "attack": 1, "health": 5, "ability": "Defender (Armor 1)", "template_idx": 0},
		{"name": "Card Shark", "cost": 3, "attack": 4, "health": 2, "ability": "Glass Cannon", "template_idx": 1},
		{"name": "Dealer", "cost": 1, "attack": 1, "health": 3, "ability": "On Play: Draw 1 card", "template_idx": 2},
		{"name": "Bouncer", "cost": 3, "attack": 2, "health": 5, "ability": "On Play: Deal 2 damage to blocker", "template_idx": 0},
		{"name": "High Roller", "cost": 4, "attack": 2, "health": 6, "ability": "Gains +1 Atk at end of turn", "template_idx": 2},
		{"name": "Pit Boss", "cost": 5, "attack": 3, "health": 7, "ability": "On Play: Friendly cards +1/+1", "template_idx": 0},
		{"name": "Jackpot King", "cost": 6, "attack": 7, "health": 7, "ability": "Jackpot (+2 direct damage)", "template_idx": 1}
	]
	
	var distribution = [10, 10, 10, 8, 6, 4, 2]
	
	for arch_idx in range(archetypes.size()):
		var arch = archetypes[arch_idx]
		var count = distribution[arch_idx]
		var template = starter_deck[min(arch.template_idx, starter_deck.size() - 1)]
		
		for c in range(count):
			var new_card = template.duplicate()
			new_card.card_name = arch.name
			new_card.energy_cost = arch.cost
			new_card.attack = arch.attack
			new_card.health = arch.health
			new_card.ability_text = arch.ability
			communal_deck.append(new_card)
			
	communal_deck.shuffle()
	print("Prepared communal deck of ", communal_deck.size(), " cards!")

func draw_card(hand_container: Control) -> CardData:
	if communal_deck.is_empty():
		prepare_communal_deck()
		
	var card_data = communal_deck.pop_front()
	hand.append(card_data)
	
	var new_card = card_scene.instantiate()
	hand_container.add_child(new_card)
	new_card.setup_card(card_data)
	
	print("Player Drew: ", card_data.card_name)
	return card_data

func draw_card_for_opponent() -> CardData:
	if communal_deck.is_empty():
		prepare_communal_deck()
		
	var card_data = communal_deck.pop_front()
	print("Opponent Drew: ", card_data.card_name)
	return card_data
