extends Button

class_name CustomButton

@export var index: int
var can_hover: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _pressed() -> void:
	print("click")
	GameManager.click_button = BattleManager.phase

func _on_mouse_entered():
	grab_focus()
    # Add your custom hover logic here
