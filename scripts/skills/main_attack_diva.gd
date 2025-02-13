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

func use(user: Stats, target: Stats):
	var crit_multiplier = 1.0
	current_target = target
	current_user = user
	target_name = target.character_name
	owner_name = user.character_name
	await DialogueManager.print_dialogue(use_text(),BattleManager.dialogue_label)
	#await get_tree().create_timer(0.5).timeout #skill effect would go here
	if BattleManager.rng.randi()%100<=accuracy:
		if BattleManager.rng.randi()%100<=crit_chance:
			await DialogueManager.print_dialogue(crit_text(),BattleManager.dialogue_label)
			crit_multiplier = 2.0
		else:
			user.main_attack_diva_resource_limit -= user.main_attack_diva_resource_count
			await DialogueManager.print_dialogue(hit_text(),BattleManager.dialogue_label)
		await target.take_damage(ego_damage(),hp_damage(),crit_multiplier,hp_temp_armor(),ego_temp_armor())
	else:
		await DialogueManager.print_dialogue(miss_text(),BattleManager.dialogue_label)
		user.main_attack_diva_resource_limit -= 1