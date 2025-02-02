extends Minigame

class_name Punchout

# Player Stats
var player_heath: int
var player_dodge_state: int		# -1 -> not dodging, 0 -> dodge left, 1 -> dodge right
const PLAYER_ACTION_COOLDOWN: float = 0.5
const PLAYER_SUCCESSFUL_DODGE_TIMER: float = 0.5

# Enemy stats
var enemy_health: int
var is_enemy_guarding: bool
const ENEMY_GUARD_DURATION: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)

func initialize():
	countdown = 5.0

	player_heath = 3
	player_dodge_state = -1
	
	enemy_health = 3
	is_enemy_guarding = false

func minigame_countdown():
	while countdown > 0:
		await get_tree().create_timer(0.1).timeout
		countdown -= 0.1
	# Ran out of time for minigame
	# TODO maybe reconsider failure state for running out of time
	print("Minigame Fail: Ran out of time")
	BattleManager.minigame_status = 0

func minigame_process():
	enemy_action()
	while true:
		# Dodge left
		if Input.is_action_just_pressed("move_left"):
			await player_dodge(0)
		# Dodge right
		if Input.is_action_just_pressed("move_right"):
			await player_dodge(1)
		# Punch
		if Input.is_action_just_pressed("move_up"):
			await player_punch()
			
		if enemy_health <= 0:
			print("Minigame Success: Beat enemy")
			BattleManager.minigame_status = 1
		elif player_heath <= 0:
			print("Minigame Fail: Lost all heath")
			BattleManager.minigame_status = 0

		await get_tree().process_frame

func player_dodge(dodge_state: int):
	print("Player Dodge: " + str(dodge_state))
	player_dodge_state = dodge_state
	await get_tree().create_timer(PLAYER_ACTION_COOLDOWN).timeout
	player_dodge_state = -1

func player_punch():
	print("Player punches")
	if !is_enemy_guarding:
		enemy_health -= 1
	# TODO maybe some sort of player punishment for punching on enemy guard
	await get_tree().create_timer(PLAYER_ACTION_COOLDOWN).timeout

func enemy_action():
	var actions: Array[Callable] = [_enemy_guard, _enemy_punch]

	while true:
		await get_tree().create_timer(randf_range(0.7, 1.2)).timeout
		await actions.pick_random().call()

func _enemy_punch():
	# 0 -> punch left, 1 -> punch right
	var punch_direction: int = randi_range(0, 0)
	print("Enemy Punches " + str(punch_direction))

	# Only deal damage if player is not dodging, or dodges towards the punch
	if punch_direction != player_dodge_state:
		player_heath -= 1
	# If player successfully dodges, then stun the enemy
	else:
		await get_tree().create_timer(PLAYER_SUCCESSFUL_DODGE_TIMER).timeout

func _enemy_guard():
	print("Enemy Guards")
	is_enemy_guarding = true
	await get_tree().create_timer(ENEMY_GUARD_DURATION).timeout
	is_enemy_guarding = false