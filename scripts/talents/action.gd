extends Talent

class_name Action

# Called when the node enters the scene tree for the first time.
func _ready():
	talent = "action"
	main_attack = MainAttackAction.new()
	add_child(main_attack)
	skills.append(DynamoSuplex.new())
	for skill in skills:
		add_child(skill)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
