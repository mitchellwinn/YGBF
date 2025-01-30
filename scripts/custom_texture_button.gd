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
	print("press")
	match type:
		"party_member":
			BattleManager.attacker_index = index
			BattleManager.stop_all_flashes()
			BattleManager.select_flash_attacker()

func _on_mouse_entered():
	print("hover")
	match type:
		"party_member":
			BattleManager.attacker_index = index
			BattleManager.stop_all_flashes()
			BattleManager.select_flash_attacker()
    # Add your custom hover logic here
