extends Node

class_name Stats

var hp_armor: int #holds data for current hp_armor
var inner_hp: int #holds data for current inner_hp
var ego_armor: int #holds data for current ego_armor/id shield
var pacified: bool #holds data for whether entity has been pacified
var talent: String
var inner_ego: int #holds data for current inner ego_armor
var ego_subdue_threshold: float #[0.0-1.0] represents percentage of max ego_armor that ego_armor needs to decrease beyond to subdue
var hp_subdue_threshold: float #[0.0-1.0] represents percentage of max inner_hp that inner_hp needs to decrease beyond to subdue
var attacks: Array[int] = [] #holds data for each attack that can be performed per turn and its corresponding speed (thats what the int is for)
var skills: Array[Skill] = [] #holds data for each skill known
var attack_index: int = 0 #holds data for which index of move the player is on, most of the time this is 0 if they haven't attacked this turn, 1 if they have
var character_name: String
var loaded_from_save: bool
var animator: AnimationPlayer

func _ready():
	print("New entity added to scene tree "+character_name)
	if(!loaded_from_save):
		initialize_new_party_member()

func initialize_new_party_member():
	define_attacks()
	hp_armor = get_max_hp_armor()
	inner_hp = get_max_hp() 
	ego_armor = get_max_ego_armor()
	inner_ego = get_max_ego()
	initialize_other_stats()
	return

func initialize_other_stats():
	pass

func get_max_hp_armor() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func get_max_ego() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func get_max_hp() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func get_max_ego_armor() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func define_attacks():
	attacks.clear() #wipe array to a clean slate before any recalculations
	attacks.append(50) #placeholder character gets 1 attack per turn at speed of 50
	return

func is_exhausted() -> bool:
	if is_defeated(): #if entity is defeated they also cannot attack lol
		return true
	if attack_index>=attacks.size():
		return true #we have used more attacks than we have available this turn, we are exhausted
	return false 

func is_defeated() -> bool:
	if inner_hp <= 0:
		return true
	if inner_ego <= 0:
		return true
	if pacified:
		return true
	return false

func is_subdued() -> bool:
	var subdued: bool = false
	if float(inner_hp)/float(get_max_hp()) <= hp_subdue_threshold:
		subdued = true
	if float(inner_ego)/float(get_max_ego()) <= ego_subdue_threshold:
		subdued = true
	return subdued

func take_damage(ego_dmg: int, hp_dmg: int, crit: float):
	#hp dmg
	hp_dmg = int(hp_dmg*crit)
	ego_dmg = int(ego_dmg*crit)
	var remainder: int = 0
	var not_yet_subdued: bool = !is_subdued()
	var ego_not_yet_broken: bool
	var hp_not_yet_broken: bool
	if hp_armor>0:
		hp_not_yet_broken = true
		if hp_dmg>hp_armor:
			remainder = hp_dmg-hp_armor
			hp_armor = 0
			inner_hp -= remainder
		else:
			hp_armor-=hp_dmg
	else:
		inner_hp -= hp_dmg
	#ego dmg
	remainder = 0
	if ego_armor>0:
		ego_not_yet_broken = true
		if ego_dmg>ego_armor:
			remainder = ego_dmg-ego_armor
			ego_armor = 0
			inner_ego -= remainder
		else:
			ego_armor-=ego_dmg
	else:
		inner_ego -= ego_dmg
	if animator:
		animator.play("dmg")
	if hp_dmg>0:
		await DialogueManager.print_dialogue(character_name+" took "+str(hp_dmg)+" damage to their HP!",BattleManager.dialogue_label)
	if ego_dmg>0:
		await DialogueManager.print_dialogue(character_name+" took "+str(ego_dmg)+" damage to their EGO!",BattleManager.dialogue_label)
	if hp_armor<=0 and hp_not_yet_broken:
		await DialogueManager.print_dialogue(character_name+"'s HP armor has been broken!",BattleManager.dialogue_label)
	if ego_armor<=0 and ego_not_yet_broken:
		await DialogueManager.print_dialogue(character_name+"'s EGO armor has been broken!",BattleManager.dialogue_label)
	if inner_hp<=0:
		await DialogueManager.print_dialogue(character_name+" passed out!",BattleManager.dialogue_label)
		return
	if inner_ego<=0:
		await DialogueManager.print_dialogue(character_name+" has become emotionally destroyed!",BattleManager.dialogue_label)
		return
	if not_yet_subdued and is_subdued():
		await DialogueManager.print_dialogue(character_name+" seems to be tired of fighting!",BattleManager.dialogue_label)
