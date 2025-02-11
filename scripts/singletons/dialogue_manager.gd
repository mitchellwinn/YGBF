extends Node

var dialogue_open: bool
var waiting_for_confirmation: bool
var printed_dialogue: String = ""
var dialogue_printed: int = 0
var target_dialogue: String
var target_region: Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("confirm") and !waiting_for_confirmation:
			printed_dialogue = target_dialogue
			target_region.text = printed_dialogue

func print_dialogue(dialogue: String, region: Label):
	dialogue_open = true
	dialogue_printed = 0
	target_dialogue = dialogue
	target_region = region
	region.text = printed_dialogue
	region.get_parent().visible = true
	while printed_dialogue!=dialogue:
		dialogue_printed+=1
		printed_dialogue = dialogue.substr(0,dialogue_printed)
		region.text = printed_dialogue
		if get_tree().current_scene.name.to_lower() == "battle":
			GameManager.play_sound(BattleManager.dialogue_sfx_player,"res://sounds/text1.wav")
		await get_tree().create_timer(0.01).timeout
	await get_tree().create_timer(0.1).timeout
	waiting_for_confirmation = true
	while waiting_for_confirmation:
		if Input.is_action_just_pressed("confirm"):
			waiting_for_confirmation = false
			await get_tree().process_frame
			break
		await get_tree().process_frame
	dialogue_open = false
	wait_to_close(region)

func wait_to_close(region: Label):
	await get_tree().create_timer(0.1).timeout
	if !dialogue_open: #another dialogue might immediately come up
		region.get_parent().visible = false
