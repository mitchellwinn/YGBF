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
	var ego_dmg_mod: float = user.get_charisma()-target.get_resilience()*.75
	var hp_dmg_mod: float = user.get_sturdiness()-target.get_sturdiness()*.75
	var ego_dmg: int
	var hp_dmg: int
	if ego_damage()>0:
		ego_dmg = ego_damage() + int(ego_dmg_mod)
	else:
		ego_dmg = ego_damage()
	if hp_damage()>0:
		hp_dmg = hp_damage() + int(hp_dmg_mod)
	else:
		hp_dmg = hp_damage()
		

	await DialogueManager.print_dialogue(use_text(),BattleManager.dialogue_label)
	#await get_tree().create_timer(0.5).timeout #skill effect would go here
	if BattleManager.rng.randi()%100<=accuracy:
		if BattleManager.rng.randi()%100<=crit_chance:
			await DialogueManager.print_dialogue(crit_text(),BattleManager.dialogue_label)
			crit_multiplier = 2.0
		else:
			await DialogueManager.print_dialogue(hit_text(),BattleManager.dialogue_label)
		await target.take_damage(ego_dmg,hp_dmg,crit_multiplier,hp_temp_armor(),ego_temp_armor())
		if user.enemy:
			return
		if user.inner_hp>hp_cost():
			user.inner_hp -= hp_cost()
		if user.inner_ego>ego_cost():
			user.inner_ego -= ego_cost()
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
