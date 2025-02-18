extends Talent

class_name Model

# Called when the node enters the scene tree for the first time.
func _ready():
	talent = "model"

	main_attack_resource_limit_cap = 4+(get_level()/10)
	main_attack_resource_limit = main_attack_resource_limit_cap

	main_attack = MainAttackModel.new()
	add_child(main_attack)
	skills.append(FashionInsult.new())
	for skill in skills:
		add_child(skill)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
