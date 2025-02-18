extends Talent

class_name Action

# Called when the node enters the scene tree for the first time.
func _ready():

	while !BattleManager.in_battle:
		await get_tree().process_frame
	update()

	talent = "action"
	main_attack = MainAttackAction.new()
	add_child(main_attack)
	skills.append(DynamoSuplex.new())
	for skill in skills:
		add_child(skill)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update():
	main_attack_resource_limit_cap = 4+(get_level()/10)
	main_attack_resource_limit = main_attack_resource_limit_cap
	BattleManager.main_attack_action.get_node("ActionBar/GridContainer").columns = main_attack_resource_limit
	for i in range(10):
		BattleManager.main_attack_action.get_node("ActionBar/GridContainer").get_children()[i].visible = false
		if i<main_attack_resource_limit:
			BattleManager.main_attack_action.get_node("ActionBar/GridContainer").get_children()[i].visible = true
