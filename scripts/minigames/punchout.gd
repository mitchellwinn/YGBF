extends Minigame

class_name Punchout

const WAIT_TIME: float = 2.0
var timer: Timer
var thread: Thread
# Player
var player_heath: int
enum PLAYER_STATE {ATTACK, DODGE_LEFT, DODGE_RIGHT, NONE}

# Enemy
var enemy_health: int
enum ENEMY_STATE {IDLE, GUARD, ATTACK_LEFT, ATTACK_RIGHT}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BattleManager.minigame_status = -1
	initialize()
	minigame_process()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)

func initialize():
	timer = Timer.new()
	timer.wait_time = WAIT_TIME
	timer.autostart = false
	timer.one_shot = true
	timer.timeout.connect(func(): print("Next Action"))
	add_child(timer)

	thread = Thread.new()

	player_heath = 3
	enemy_health = 3

func minigame_process():
	var enemy_state: ENEMY_STATE
	var player_state: PLAYER_STATE
	while true:
		# Select a random state for enemy
		enemy_state = ENEMY_STATE.values().pick_random()
		print("Enemy State: " + ENEMY_STATE.find_key(enemy_state))

		thread.start(player_action.bind())
		timer.start()
		await timer.timeout
		player_state = thread.wait_to_finish()

		process_states(enemy_state, player_state)

		if enemy_health <= 0:
			print("Minigame Success")
			BattleManager.minigame_status = 1
		elif player_heath <= 0:
			print("Minigame Fail")
			BattleManager.minigame_status = 0

		await get_tree().process_frame

func player_action() -> PLAYER_STATE:
	while timer.time_left > 0:
		# Dodge left
		if Input.is_action_just_pressed("move_left"):
			print("Dodged Left")
			# Signals aren't thread safe, need to defer the call
			timer.emit_signal.call_deferred("timeout")
			return PLAYER_STATE.DODGE_LEFT
		# Dodge right
		if Input.is_action_just_pressed("move_right"):
			print("Dodged Right")
			timer.emit_signal.call_deferred("timeout")
			return PLAYER_STATE.DODGE_RIGHT
		# Punch
		if Input.is_action_just_pressed("move_up"):
			print("Punched")
			timer.emit_signal.call_deferred("timeout")
			return PLAYER_STATE.ATTACK

	return PLAYER_STATE.NONE

func process_states(enemy_state: ENEMY_STATE, player_state: PLAYER_STATE):
	if enemy_state == ENEMY_STATE.IDLE:
		if player_state == PLAYER_STATE.ATTACK:
			print("Enemy Health -1")
			enemy_health -= 1
	elif enemy_state == ENEMY_STATE.GUARD:
		pass
	elif enemy_state == ENEMY_STATE.ATTACK_LEFT:
		if player_state != PLAYER_STATE.DODGE_RIGHT:
			print("Player Health -1")
			player_heath -= 1
	elif  enemy_state == ENEMY_STATE.ATTACK_RIGHT:
		if player_state != PLAYER_STATE.DODGE_LEFT:
			print("Player Health -1")
			player_heath -= 1
