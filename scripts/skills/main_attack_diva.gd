extends Skill

class_name MainAttackDiva

# Called when the node enters the scene tree for the first time.
func _ready():
	skill_name = "Diva"
	crit_chance = 10
	accuracy = 95

func use_text() -> String:
	return owner_name+" crafts some gear for "+target_name+" in a pinch!"

func  hit_text() -> String:
	return "Looks like a good fit!"

func  crit_text() -> String:
	return "Wow~! This is some functional clothing!"

func  miss_text() -> String:
	return "It doesn't quite fit "+target_name+"..."

func ego_temp_armor() -> int:
	return 5*current_user.main_attack_diva_ego

func hp_temp_armor() -> int:
	return 5*current_user.main_attack_diva_hp
