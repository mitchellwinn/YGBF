extends Node

class_name Stats

var sprite

var enemy: bool

var hp_armor: int #holds data for current hp_armor
var temporary_hp_armor: int
var inner_hp: int #holds data for current inner_hp
var ego_armor: int #holds data for current ego_armor/id shield
var temporary_ego_armor: int
var pacified: bool #holds data for whether entity has been pacified
var active_talent: Talent
var talents: Array[Talent]
var inner_ego: int #holds data for current inner ego_armor
var ego_subdue_threshold: float #[0.0-1.0] represents percentage of max ego_armor that ego_armor needs to decrease beyond to subdue
var hp_subdue_threshold: float #[0.0-1.0] represents percentage of max inner_hp that inner_hp needs to decrease beyond to subdue
var attacks: Array[int] = [] #holds data for each attack that can be performed per turn and its corresponding speed (thats what the int is for)
#var skills: Array[Skill] = [] #holds data for each skill known
var main_attack: Skill #the skill that represents the main attack
var attack_index: int = 0 #holds data for which index of move the player is on, most of the time this is 0 if they haven't attacked this turn, 1 if they have
var character_name: String
var loaded_from_save: bool
var animator: AnimationPlayer

var exp: int
var level_cap: int

var base_strength: int #determines damage dealt by physical attacks
var base_charisma: int #determines damage dealt by EGO attacks
var base_agility: int #determines speed when deciding who should attack
var base_constitution: int #determines max HP
var base_sturdiness: int #determines defense against physical attacks
var base_perspective: int #determines max EGO
var base_resilience: int #determines defense against EGO attacks

var growth_strength: float #determines damage dealt by physical attacks
var growth_charisma: float #determines damage dealt by EGO attacks
var growth_agility: float #determines speed when deciding who should attack
var growth_constitution: float #determines max HP
var growth_sturdiness: float #determines defense against physical attacks
var growth_perspective: float #determines max EGO
var growth_resilience: float #determines defense against EGO attacks

func _ready():
	print("New entity added to scene tree "+character_name)
	if(!loaded_from_save):
		initialize_new_party_member()

func initialize_new_party_member():
	initialize_stats()
	define_attacks()
	hp_armor = get_max_hp_armor()
	inner_hp = get_max_hp() 
	ego_armor = get_max_ego_armor()
	inner_ego = get_max_ego()
	print("hp for "+character_name+" is "+str(inner_hp))
	return

func restore_resources_full():
	active_talent.main_attack_resource_limit = active_talent.main_attack_resource_limit_cap

func restore_resources_iterate():
	active_talent.main_attack_resource_limit += 1  
	active_talent.main_attack_resource_limit = clamp(active_talent.main_attack_resource_limit, 0, active_talent.main_attack_resource_limit_cap)

func initialize_stats():
	pass

func gain_exp(value: int):
	exp += value
	if exp > level_cap*10:
		exp = level_cap*10

func get_level() -> int:
	return (exp/10)+1

func get_rank() -> String:
	match (exp/100):
		0:
			return "F"
		1:
			return "E"
		2,3:
			return "D"
		4,5:
			return "C"
		6,7:
			return "B"
		8,9:
			return "A"
		_:
			return "S"

func get_max_ego_armor() -> int:
	return get_perspective()/(2-float(float(get_level()/100.0)))

func get_max_hp_armor() -> int:
	return get_constitution()/(2-float(float(get_level()/100.0)))

func get_max_ego() -> int:
	return get_perspective()

func get_max_hp() -> int:
	return get_constitution()

func get_constitution() -> int:
	return base_constitution+growth_constitution*(float(get_level())/5.0)*base_constitution

func get_perspective() -> int:
	return base_perspective+growth_perspective*(float(get_level())/5.0)*base_perspective

func get_strength() -> int:
	return base_strength+growth_strength*(float(get_level())/5.0)*base_strength

func get_charisma() -> int:
	return base_charisma+growth_charisma*(float(get_level())/5.0)*base_charisma

func get_agility() -> int:
	return base_agility+growth_agility*(float(get_level())/5.0)*base_agility

func get_sturdiness() -> int:
	return base_sturdiness+growth_sturdiness*(float(get_level())/5.0)*base_sturdiness

func get_resilience()-> int:
	return base_resilience+growth_resilience*(float(get_level())/5.0)*base_resilience

func define_attacks():
	attacks.clear() #wipe array to a clean slate before any recalculations
	attacks.append(get_agility())
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

func take_damage(ego_dmg: int, hp_dmg: int, crit: float, hp_temp_armor, ego_temp_armor, skill_name: String):
	#hp dmg
	var hp_armor_gain = hp_temp_armor*crit
	var ego_armor_gain = ego_temp_armor*crit
	var hp_armor_meaningful_gain = false
	var ego_armor_meaningful_gain = false

	hp_dmg = int(hp_dmg*crit)
	ego_dmg = int(ego_dmg*crit)

	var temp_overflow = 0
	if hp_temp_armor>0:
		if hp_temp_armor*crit+hp_armor<=get_max_hp_armor():
			hp_armor += hp_temp_armor*crit
			hp_armor_meaningful_gain = true
			print("missing hp totally")
		elif hp_armor != get_max_hp_armor():
			print("missing some hp")
			temp_overflow = (hp_armor+hp_temp_armor*crit)-get_max_hp_armor()
			hp_armor = get_max_hp_armor()
		elif hp_armor == get_max_hp_armor():
			print("missing no hp")
			temp_overflow = hp_temp_armor * crit
		if temporary_hp_armor<temp_overflow:
			temporary_hp_armor = temp_overflow
			hp_armor_meaningful_gain = true
		print("hp armor: "+str(temporary_hp_armor))
		print("temp hp armor: "+str(temporary_hp_armor))
	temp_overflow = 0
	if ego_temp_armor>0:
		if ego_temp_armor*crit+ego_armor<=get_max_ego_armor():
			ego_armor += ego_temp_armor*crit
			ego_armor_meaningful_gain = true
			print("missing ego totally")
		elif ego_armor != get_max_ego_armor():
			print("missing some ego")
			temp_overflow = (ego_armor+ego_temp_armor*crit)-get_max_ego_armor()
			ego_armor = get_max_ego_armor()
		elif ego_armor == get_max_ego_armor():
			print("missing no ego")
			temp_overflow = ego_temp_armor * crit
		if temporary_ego_armor<temp_overflow:
			temporary_ego_armor = temp_overflow
			ego_armor_meaningful_gain = true
		print("ego armor: "+str(ego_armor))
		print("temp ego armor: "+str(temporary_ego_armor))

	var remainder: int = 0
	var not_yet_subdued: bool = !is_subdued()
	var ego_not_yet_broken: bool
	var hp_not_yet_broken: bool
	if hp_armor_meaningful_gain:
		await DialogueManager.print_dialogue(character_name+" gained "+str(hp_armor_gain)+" points of HP armor!",BattleManager.dialogue_label)
	if ego_armor_meaningful_gain:
		await DialogueManager.print_dialogue(character_name+" gained "+str(ego_armor_gain)+" points of EGO armor!",BattleManager.dialogue_label)

	if temporary_hp_armor>0:
		if hp_dmg>temporary_hp_armor:
			hp_dmg = hp_dmg-temporary_hp_armor
			temporary_hp_armor = 0
			await DialogueManager.print_dialogue(character_name+"'s extra HP shield has been broken!",BattleManager.dialogue_label)
		elif hp_dmg>0:
			temporary_hp_armor-=hp_dmg
			hp_dmg = 0
			await DialogueManager.print_dialogue(character_name+" had their HP completely protected by the shield!",BattleManager.dialogue_label)

	if temporary_ego_armor>0:
		if ego_dmg>temporary_ego_armor:
			ego_dmg = ego_dmg-temporary_ego_armor
			temporary_ego_armor = 0
			await DialogueManager.print_dialogue(character_name+"'s extra EGO shield has been broken!",BattleManager.dialogue_label)
		elif ego_dmg>0:
			temporary_ego_armor-=ego_dmg
			ego_dmg = 0
			await DialogueManager.print_dialogue(character_name+" had their EGO completely protected by the shield!",BattleManager.dialogue_label)

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
	if animator and (ego_dmg>0 or hp_dmg>0):
		if animator.has_animation(skill_name):
			animator.play(skill_name)
			await animator.animation_finished
		GameManager.play_sound(BattleManager.sfx_player,"res://sounds/ego_dmg.wav")
		animator.play("damage")
		await animator.animation_finished
		animator.play("RESET")
		await animator.animation_finished
	#BattleManager.animate_bars()
	if hp_dmg>0:
		await DialogueManager.print_dialogue(character_name+" took "+str(hp_dmg)+" damage to their HP!",BattleManager.dialogue_label)
	elif hp_dmg<0:
		await DialogueManager.print_dialogue(character_name+" recovered "+str(hp_dmg)+" points of damage from their HP!",BattleManager.dialogue_label)
	if ego_dmg>0:
		await DialogueManager.print_dialogue(character_name+" took "+str(ego_dmg)+" damage to their EGO!",BattleManager.dialogue_label)
	elif ego_dmg<0:
		await DialogueManager.print_dialogue(character_name+" recovered "+str(ego_dmg)+" points of damage from their EGO!",BattleManager.dialogue_label)
	if hp_armor<=0 and hp_not_yet_broken:
		await DialogueManager.print_dialogue(character_name+"'s HP armor has been broken!",BattleManager.dialogue_label)
	if ego_armor<=0 and ego_not_yet_broken:
		await DialogueManager.print_dialogue(character_name+"'s EGO armor has been broken!",BattleManager.dialogue_label)
	if animator and (is_defeated()):
		GameManager.play_sound(BattleManager.sfx_player,"res://sounds/ego_dmg.wav")
		animator.play("defeated")
	if inner_hp<=0:
		await DialogueManager.print_dialogue(character_name+" passed out!",BattleManager.dialogue_label)
		return
	if inner_ego<=0:
		await DialogueManager.print_dialogue(character_name+" has become emotionally destroyed!",BattleManager.dialogue_label)
		return
	if not_yet_subdued and is_subdued():
		await DialogueManager.print_dialogue(character_name+" seems to be tired of fighting!",BattleManager.dialogue_label)
