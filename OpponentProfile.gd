extends Resource
class_name OpponentProfile

@export var opponent_name: String = "Dealer"
@export_enum("EASY", "MEDIUM", "HARD") var difficulty: String = "MEDIUM"
@export_enum("BALANCED", "AGGRESSIVE", "DEFENSIVE", "RANDOM") var play_style: String = "BALANCED"

# Decision weights for scoring (Medium and Hard AIs)
@export var weight_damage: float = 1.0       # Weight for dealing direct damage to player
@export var weight_block: float = 1.0        # Weight for blocking player attacks
@export var weight_kill_ally: float = 0.5    # Penalty/loss for losing own card in combat (positive value represents cost subtracted)
@export var weight_kill_enemy: float = 1.0   # Reward for defeating a player card
@export var weight_buff_allies: float = 0.5  # Synergy weight for buffing existing allies (e.g. Pit Boss)
@export var weight_hand_size: float = 0.3    # Value of drawing cards (e.g. Dealer)

# Randomness weight (higher makes more mistakes)
@export var valuation_noise: float = 0.0     # Maximum random score added/subtracted
