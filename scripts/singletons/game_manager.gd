extends Node

var party: Array[Stats] = [] #holds data for all party members who will appear in battle

var overworld_map: String

var click_button: String

var last_delta: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	BattleManager.troop = 1
	var party_member: Stats
	party_member = Robby.new()
	get_tree().root.add_child.call_deferred(party_member)
	party.append.call_deferred(party_member)
	await get_tree().process_frame
	party_member = Emilio.new()
	get_tree().root.add_child.call_deferred(party_member)
	party.append.call_deferred(party_member)
	await get_tree().process_frame

	if get_tree().current_scene.name.to_lower() == "battle":
		BattleManager.start_battle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	last_delta = delta
	if Input.is_action_just_pressed("fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)
			DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)

func play_sound(player: AudioStreamPlayer2D, stream: String):
	player.stream = load(stream)
	player.play()
