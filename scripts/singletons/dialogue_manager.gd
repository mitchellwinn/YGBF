extends Node

var dialogue_open: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func print_dialogue(dialogue: String, region: Label):
	dialogue_open = true
	var printed_dialogue: String = ""
	var dialogue_printed: int = 0
	region.text = printed_dialogue
	region.get_parent().visible = true
	while printed_dialogue!=dialogue:
		dialogue_printed+=1
		printed_dialogue = dialogue.substr(0,dialogue_printed)
		region.text = printed_dialogue
		await get_tree().process_frame
	while true:
		if Input.is_action_just_pressed("confirm"):
			break
		await get_tree().process_frame
	dialogue_open = false
	wait_to_close(region)

func wait_to_close(region: Label):
	await get_tree().create_timer(0.1).timeout
	if !dialogue_open: #another dialogue might immediately come up
		region.get_parent().visible = false
