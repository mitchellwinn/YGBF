extends Stats

class_name BigMenace

func initialize_other_stats():
	character_name = "New Kleo Hustler"
	ego_subdue_threshold = .9
	skills.append(BasicAttack.new())
	for skill in skills:
			add_child(skill)

func get_max_hp_armor() -> int:
	var value: int = 10 #write code later to calculate this based on level or other factors
	return value

func get_max_ego() -> int:
	var value: int = 60 #write code later to calculate this based on level or other factors
	return value

func get_max_hp() -> int:
	var value: int = 30 #write code later to calculate this based on level or other factors
	return value

func get_max_ego_armor() -> int:
	var value: int = 10 #write code later to calculate this based on level or other factors
	return value