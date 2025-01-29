extends Node

var party: Array[Stats] = [] #holds data for all party members who will appear in battle

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(2): #make a dummy party with 4 characters
		var party_member: Stats = Stats.new()
		party_member.character_name = "Dummy "+str(i+1)
		get_tree().root.add_child.call_deferred(party_member)
		GameManager.party.append.call_deferred(party_member)
		await get_tree().process_frame
	BattleManager.start_battle()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)
			DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
