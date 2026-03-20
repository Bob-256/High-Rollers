extends Node

# Reference to the Card scene to instantiate visuals
@export var card_scene: PackedScene
# List of CardData resources (Dealer, Slot Guard, etc.)
@export var starter_deck: Array[CardData] 

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []

func _ready():
	# Initialize the game with the 10-card starter deck
	prepare_deck()

func prepare_deck():
	draw_pile = starter_deck.duplicate()
	draw_pile.shuffle() # Shuffling ensures low-randomness strategy starts fresh

func draw_card(hand_container: Control):
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			print("No cards left to draw!")
			return
		reshuffle_discard_into_draw()

	var card_data = draw_pile.pop_front()
	hand.append(card_data)
	
	# Instantiate the visual card in the PlayerHand UI
	var new_card = card_scene.instantiate()
	hand_container.add_child(new_card)
	new_card.setup_card(card_data) # Pass the Energy, Atk, and HP stats
	
	print("Drew: ", card_data.card_name)

func reshuffle_discard_into_draw():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()

func discard_card(card_data: CardData):
	hand.erase(card_data)
	discard_pile.append(card_data)
