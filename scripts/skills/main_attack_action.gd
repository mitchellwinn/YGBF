extends Skill

class_name MainAttackAction

# Called when the node enters the scene tree for the first time.
func _ready():
	skill_name = "ActionMain"
	crit_chance = 10
	accuracy = 100

func use_text() -> String:
	return owner_name+" performed a flurry of attacks!"

func  hit_text() -> String:
	return ""

func  crit_text() -> String:
	return ""

func  miss_text() -> String:
	return ""

func use(user: Stats, target: Stats):
	var crit_multiplier = 1.0
	current_target = target
	current_user = user
	target_name = target.character_name
	owner_name = user.character_name
	var combo_count: int = 0
	#await get_tree().create_timer(0.5).timeout #skill effect would go here
	#await button press
	if BattleManager.rng.randi()%100<=accuracy:
		if BattleManager.rng.randi()%100<=crit_chance:
			await DialogueManager.print_dialogue(crit_text(),BattleManager.dialogue_label)
			crit_multiplier = 2.0
		else:
			await DialogueManager.print_dialogue(hit_text(),BattleManager.dialogue_label)
		await target.take_damage(ego_damage(),hp_damage(),crit_multiplier,hp_temp_armor(),ego_temp_armor(),skill_name)
	else:
		await DialogueManager.print_dialogue(miss_text(),BattleManager.dialogue_label)
	await DialogueManager.print_dialogue(use_text(),BattleManager.dialogue_label)
