extends Node

class_name Minigame

var countdown: float

# Called when the node enters the scene tree for the first time.
func _ready():
	BattleManager.minigame_status = -1
	initialize()
	minigame_countdown()
	minigame_process()

func _process(_delta):
	if get_tree().current_scene.name.to_lower() != "battle":
		if BattleManager.minigame_status!=-1:
			get_tree().quit()

func initialize():
	#This function is defined in classes that inherit from Minigame, but a barebones example could look like this:
	countdown = 5.0

func minigame_countdown():
	#This function is defined in classes that inherit from Minigame, but a barebones example could look like this:
	while countdown>0:
		await get_tree().create_timer(0.1).timeout
		countdown -= 0.1 #subtract 0.1 from timer every 0.1 seconds, this way you can check to see if the timer is equal to a value only on 1 specific frame and call different functions
		if is_equal_approx(countdown,4.5):
			print(countdown)
			continue
		if is_equal_approx(countdown,3.5):
			print(countdown)
			continue
		if is_equal_approx(countdown,2.5):
			print(countdown)
			continue
		if is_equal_approx(countdown,1.5):
			print(countdown)
			continue
		if is_equal_approx(countdown,0.5):
			print(countdown)
			continue
	print("Minigame over, out of time")
	BattleManager.minigame_status = 0 #failed the minigame

func minigame_process():
	#This function is defined in classes that inherit from Minigame, but a barebones example could look like this:
	while true:
		if Input.is_action_just_pressed("confirm"): #Z or Enter key
			print("Minigame over, player pressed win button")
			BattleManager.minigame_status = 1 #succeeded at the minigame
		await get_tree().process_frame