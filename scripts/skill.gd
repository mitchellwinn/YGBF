extends Node

class_name  Skill

var skill_name: String
var owner_name: String
var target_name: String
var accuracy: int #out of 100
var crit_chance: int #out of 100

var current_user: Stats
var current_target: Stats

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _ready():
	print("not a unique skill")

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
			await DialogueManager.print_dialogue(hit_text(),BattleManager.dialogue_label)
		await target.take_damage(ego_damage(),hp_damage(),crit_multiplier,hp_temp_armor(),ego_temp_armor())
	else:
		await DialogueManager.print_dialogue(miss_text(),BattleManager.dialogue_label)

func use_text() -> String:
	return "Use Attack"

func  hit_text() -> String:
	return "Attack Hit"

func  crit_text() -> String:
	return "Attack Crit"

func  miss_text() -> String:
	return "Attack Miss"

func hp_cost() -> int:
	return 0

func ego_cost() -> int:
	return 0

func hp_damage() -> int:
	return 0

func ego_damage() -> int:
	return 0

func hp_temp_armor() -> int:
	return 0

func ego_temp_armor() -> int:
	return 0
