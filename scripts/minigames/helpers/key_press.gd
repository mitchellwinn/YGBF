extends Sprite2D

var minigame: Minigame
var speed: int
var direction: String
var active: bool
var pressed: bool
var in_zone: bool
var speed_mult = 5;

# Called when the node enters the scene tree for the first time.
func _ready():
	material = material.duplicate()
	material.set_shader_parameter("use_blend", false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= delta*speed*speed_mult
	speed_mult-=delta*6
	if speed_mult<1:
		speed_mult = 1
	if !active:
		return
	if test_key_press():
		material.set_shader_parameter("use_blend", true)
		material.set_shader_parameter("color", Color.RED)
		if in_zone:
			print("Good!")
			minigame.points += 1
			$Good.visible = true
			material.set_shader_parameter("color", Color.GREEN)
		else:
			$Miss.visible = true
		pressed = true

func test_key_press() -> bool:
	if Input.is_action_just_pressed("move_"+direction):
		minigame.get_node("AnimationPlayer").stop()
		minigame.get_node("AnimationPlayer").play("snap")
		minigame.get_node("Model_Small").texture = load("res://images/minigames/model_"+direction+".png")
		minigame.get_node("Model").texture = load("res://images/minigames/model_"+direction+".png")
		$AnimationPlayer.play("press")
		return true
	return false

func randomize():
	match BattleManager.rng.randi()%4:
		0:
			direction = "up"
		1:
			direction = "right"
		2:
			direction = "down"
		3:
			direction = "left"
	texture = load("res://images/minigames/"+direction+"_key.png")
	

func _on_area_2d_area_entered(area:Area2D):
	in_zone = true

func _on_area_2d_area_exited(area:Area2D):
	in_zone = false
	if !pressed:
		print ("not pressed")
		$Miss.visible = true
		$AnimationPlayer.play("miss")
		material.set_shader_parameter("use_blend", true)
		material.set_shader_parameter("color", Color.RED)
	pressed = true
