extends Minigame

var points: int
var key_presses: Array

var key_press_prefab = preload("res://prefabs/minigames/key_press.tscn")

# Called when the node enters the scene tree for the first time.
func initialize():
	countdown = 5.5
	$AnimationPlayer.play("initialize")

func _process(_delta):
	for key_press in key_presses:
		if key_press.pressed:
			key_press.active = false
			continue
		key_press.active = true
		break
	super._process(_delta)

func minigame_countdown():
	var random_floats: Array
	for i in range(5):
		random_floats.append(random_approximate_float(0,2))
	while countdown>0:
		await get_tree().create_timer(0.1).timeout
		countdown -= 0.1 #subtract 0.1 from timer every 0.1 seconds, this way you can check to see if the timer is equal to a value only on 1 specific frame and call different functions
		if is_equal_approx(countdown,5.5-random_floats[0]):
			spawn_key()
			print(str(countdown))
			continue
		if is_equal_approx(countdown,5.0-random_floats[1]):
			spawn_key()
			print(countdown)
			continue
		if is_equal_approx(countdown,4.5-random_floats[2]):
			spawn_key()
			print(countdown)
			continue
		if is_equal_approx(countdown,4.0-random_floats[3]):
			spawn_key()
			print(countdown)
			continue
		if is_equal_approx(countdown,3.5-random_floats[4]):
			spawn_key()
			print(countdown)
			continue
		if is_equal_approx(countdown,1.5):
			$AnimationPlayer.play("finish")
			print(countdown)
			continue
		if is_equal_approx(countdown,1):
			$AnimationPlayer.play("finish")
			print(countdown)
			print("Minigame over, out of time")
			BattleManager.minigame_status = 0 #failed the minigame

func random_approximate_float(from: int, to: int) -> float:
	var value: float = float(BattleManager.rng.randi_range(from,to))/10.0
	print("value: "+str(value))
	return value

func spawn_key():
	var key_press = key_press_prefab.instantiate()
	key_press.randomize()
	key_press.speed = 400
	key_press.minigame = self
	key_presses.append(key_press)
	$KeyPressSpawner.add_child(key_press)
	print(key_press.position)


func minigame_process():
	return
