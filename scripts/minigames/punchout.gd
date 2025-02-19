extends Minigame

class_name Punchout

const WAIT_TIME: float = 2.0
const ANIM_SPEED: float = 1.25
var timer: Timer
var thread: Thread
var scene_animator: AnimationPlayer

# Player
var player_heath: int
var success_counter: int
var player_animator: AnimationPlayer
enum PLAYER_STATE {ATTACK, DODGE_LEFT, DODGE_RIGHT, IDLE, HURT}

# Enemy
var enemy_health: int
var counter_available: bool
var enemy_animator: AnimationPlayer
var enemy_action_queue: Array[ENEMY_STATE]
enum ENEMY_STATE {IDLE, GUARD, ATTACK_LEFT, 
				  ATTACK_RIGHT, WINDUP_LEFT, 
				  WINDUP_RIGHT, COUNTERED,
				  HURT, COUNTERED_HURT}
const possible_actions: Array[ENEMY_STATE] = [ENEMY_STATE.IDLE, 
											  #ENEMY_STATE.GUARD,
											  ENEMY_STATE.WINDUP_LEFT,
											  ENEMY_STATE.WINDUP_RIGHT] 

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
	# Intentionally empty
	timer.timeout.connect(func():)
	add_child(timer)

	thread = Thread.new()

	player_animator = $Player.get_node("AnimationPlayer")
	enemy_animator = $Enemy.get_node("AnimationPlayer")
	player_animator.speed_scale = ANIM_SPEED
	enemy_animator.speed_scale = ANIM_SPEED
	scene_animator = $AnimationPlayer

	enemy_action_queue = []

	player_heath = 3
	success_counter = 0
	enemy_health = 3
	counter_available = false

func minigame_process():
	var enemy_state: ENEMY_STATE
	var player_state: PLAYER_STATE = PLAYER_STATE.IDLE
	scene_animator.play("INTRO")

	# NOTE: Don't go below 2 minimum actions
	for i in range(2):
		enemy_action_queue.append(possible_actions.pick_random())

	await scene_animator.animation_finished

	play_player_animation(PLAYER_STATE.IDLE)
	while BattleManager.minigame_status == -1:
		# Select a random state for enemy
		enemy_state = enemy_action_queue.pop_front()
		print("Enemy State: " + ENEMY_STATE.find_key(enemy_state))
		play_enemy_animation(enemy_state)
		# Add next enemy state to queue
		enemy_action_queue.append(possible_actions.pick_random())

		# TODO fix idle animation overwriting previous animations
		# Play idle animation while waiting
		# Check for any player input within WAIT_TIME seconds
		thread.start(player_action.bind())
		timer.start()
		await timer.timeout
		player_state = thread.wait_to_finish()

		play_player_animation(player_state)
		await process_states(enemy_state, player_state)
		if enemy_health <= 0:
			print("Minigame Success")
			scene_animator.play("OUTRO")
			await scene_animator.animation_finished
			BattleManager.minigame_status = 1
		elif player_heath <= 0:
			print("Minigame Fail")
			scene_animator.play("OUTRO")
			await scene_animator.animation_finished
			BattleManager.minigame_status = 0

		await get_tree().process_frame

func play_enemy_animation(enemy_state: ENEMY_STATE):
	enemy_animator.play("RESET")
	match enemy_state:
		ENEMY_STATE.ATTACK_LEFT:
			enemy_animator.play("ATTACK_LEFT")
		ENEMY_STATE.ATTACK_RIGHT:
			enemy_animator.play("ATTACK_RIGHT")
		ENEMY_STATE.GUARD:
			enemy_animator.play("GUARD")
		ENEMY_STATE.IDLE:
			enemy_animator.play("IDLE")
		ENEMY_STATE.WINDUP_LEFT:
			enemy_animator.play("WINDUP_LEFT")
		ENEMY_STATE.WINDUP_RIGHT:
			enemy_animator.play("WINDUP_RIGHT")
		ENEMY_STATE.COUNTERED:
			enemy_animator.play("COUNTERED")	
		ENEMY_STATE.COUNTERED_HURT:
			enemy_animator.play("COUNTERED_HURT")	
		ENEMY_STATE.HURT:
			enemy_animator.play("HURT")

func play_player_animation(player_state: PLAYER_STATE):
	player_animator.play("RESET")
	match player_state:
		PLAYER_STATE.ATTACK:
			player_animator.play("ATTACK")
		PLAYER_STATE.DODGE_LEFT:
			player_animator.play("DODGE_LEFT")
		PLAYER_STATE.DODGE_RIGHT:
			player_animator.play("DODGE_RIGHT")
		PLAYER_STATE.IDLE:
			player_animator.play("IDLE")
		PLAYER_STATE.HURT:
			player_animator.play("HURT")

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

	return PLAYER_STATE.IDLE

func handle_success_counter(is_successful: bool):
	# TODO sfx for increasing counter and losing the streak
	if is_successful:
		success_counter += 1
		return
	success_counter = 0
	
func process_states(enemy_state: ENEMY_STATE, player_state: PLAYER_STATE) -> void:
	match enemy_state:
		ENEMY_STATE.IDLE, ENEMY_STATE.COUNTERED:
			if player_state != PLAYER_STATE.ATTACK:
				return
			handle_success_counter(true)
			print("Enemy Health -1")
			enemy_health -= 1
			if enemy_state == ENEMY_STATE.COUNTERED:
				play_enemy_animation(ENEMY_STATE.COUNTERED_HURT)
			else:
				play_enemy_animation(ENEMY_STATE.HURT)
			await enemy_animator.animation_finished
		ENEMY_STATE.GUARD:
			return
		ENEMY_STATE.WINDUP_LEFT, ENEMY_STATE.WINDUP_RIGHT:
			var mapping: Dictionary = {
				ENEMY_STATE.WINDUP_LEFT: [ENEMY_STATE.ATTACK_LEFT, PLAYER_STATE.DODGE_LEFT],
				ENEMY_STATE.WINDUP_RIGHT: [ENEMY_STATE.ATTACK_RIGHT, PLAYER_STATE.DODGE_RIGHT]
			}
			var direction = mapping.get(enemy_state)
			play_enemy_animation(direction[0])
			# Damage player and move to next round if they didn't dodge correctly
			if player_state != direction[1]:
				# Failed, reset counter availability
				counter_available = false
				play_player_animation(PLAYER_STATE.HURT)
				handle_success_counter(false)
				print("Player Health -1")
				player_heath -= 1
				await enemy_animator.animation_finished
				await player_animator.animation_finished
				return
			handle_success_counter(true)
			_determine_counter_status()
			await enemy_animator.animation_finished

func _determine_counter_status():
	# Counter is only available when player chain dodges
	if counter_available:
		enemy_action_queue.insert(0, ENEMY_STATE.COUNTERED)
		counter_available = false
		return

	# Check passes only when the windup chain will end at the next state
	const windups: Array[ENEMY_STATE] = [ENEMY_STATE.WINDUP_LEFT, ENEMY_STATE.WINDUP_RIGHT]
	if enemy_action_queue[0] in windups && enemy_action_queue[1] not in windups :
		counter_available = true
