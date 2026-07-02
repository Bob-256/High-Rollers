extends Control

@export var card_spacing: float = 80.0
@export var max_arc_height: float = 35.0
@export var max_rotation_degrees: float = 12.0
@export var base_y: float = 55.0

func _ready():
	child_order_changed.connect(_on_child_order_changed)
	# Also trigger arrangement when container size changes to keep it centered
	resized.connect(_on_child_order_changed)

func _on_child_order_changed():
	# Defer to next frame to allow node structures to settle
	arrange_cards.call_deferred()

func arrange_cards():
	var cards = get_children()
	var n = cards.size()
	if n == 0:
		return
		
	var center_x = size.x / 2.0
	
	for i in range(n):
		var card = cards[i]
		# Ensure the card's pivot is at its center (140x190 cards) for correct rotation
		card.pivot_offset = Vector2(70, 95)
		
		var t = 0.0
		if n > 1:
			t = -1.0 + (2.0 * i) / (n - 1)
			
		var target_x = center_x + t * ((n - 1) * card_spacing) / 2.0 - 70.0
		var target_y = base_y - (1.0 - t * t) * max_arc_height
		var target_rot = deg_to_rad(t * max_rotation_degrees)
		
		if card.has_method("set_hand_targets"):
			card.set_hand_targets(Vector2(target_x, target_y), target_rot)
		else:
			card.position = Vector2(target_x, target_y)
			card.rotation = target_rot
