extends TextureButton

class_name CustomTextureButton

@export var type: String
@export var index: int

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _pressed() -> void:
	if type!=BattleManager.phase:
		return
	match BattleManager.phase:
		"decide_attacker":
			if BattleManager.party[index].is_exhausted():
				return
	print("click")
	GameManager.click_button = BattleManager.phase

func _on_mouse_entered():
	match BattleManager.phase:
		"decide_attacker":
			match type:
				"decide_attacker":
					print("hover_potential_attacker")
					if BattleManager.party[index].is_exhausted():
						return
					BattleManager.attacker_index = index
					BattleManager.stop_all_flashes()
					BattleManager.select_flash_attacker()
		"decide_target":
			match type:
				"decide_target":
					print("hover_potential_enemy")
					BattleManager.target_index = index
					BattleManager.stop_all_flashes()
					BattleManager.select_flash_enemy()
    # Add your custom hover logic here
