extends Node

########## MAIN FUNCTIONS ##############

func load(troop: int):
	match troop:
		0:
			print("Loading troop "+str(troop))
			await load_test_troop()
	return

func entry_message(troop: int) -> String:
	match troop:
		0:
			return "A trio of Big Menaces have made an entrance!"
	return "Suddenly we find ourselves contested!"

######### LOADABLE TROOPS ##############

func load_test_troop():
	for i in range(3): #make a dummy troop with 3 enemies
		var enemy: Stats = Stats.new()
		enemy.character_name = "Big Menace "+str(i+1)
		enemy.skills.append(BasicAttack.new())
		enemy.ego_subdue_threshold = .9
		get_tree().root.add_child.call_deferred(enemy)
		for skill in enemy.skills:
			enemy.add_child(skill)
		BattleManager.enemies.append.call_deferred(enemy)
		await get_tree().process_frame
