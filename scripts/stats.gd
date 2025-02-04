extends Node

class_name Stats

var armor: int #holds data for current armor
var hp: int #holds data for current hp
var ego: int #holds data for current ego/id shield
var pacified: bool #holds data for whether entity has been pacified
var talent: String
var inner_ego: int #holds data for current inner ego
var ego_subdue_threshold: float #[0.0-1.0] represents percentage of max ego that ego needs to decrease beyond to subdue
var hp_subdue_threshold: float #[0.0-1.0] represents percentage of max hp that hp needs to decrease beyond to subdue
var attacks: Array[int] = [] #holds data for each attack that can be performed per turn and its corresponding speed (thats what the int is for)
var attack_index: int = 0 #holds data for which index of move the player is on, most of the time this is 0 if they haven't attacked this turn, 1 if they have
var character_name: String
var loaded_from_save: bool

func _ready():
	print("New entity added to scene tree "+character_name)
	if(!loaded_from_save):
		initialize_new_party_member()

func initialize_new_party_member():
	define_attacks()
	armor = get_max_armor()
	hp = get_max_hp() 
	ego = get_max_ego()
	inner_ego = get_max_id()
	return

func get_max_armor() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func get_max_id() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func get_max_hp() -> int:
	var value: int = 100 #write code later to calculate this based on level or other factors
	return value

func get_max_ego() -> int:
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
	if hp <= 0:
		return true
	if ego <= 0:
		return true
	if pacified:
		return true
	return false

func is_subdued() -> bool:
	if float(hp)/float(get_max_hp()) <= hp_subdue_threshold:
		return true
	if float(ego)/float(get_max_ego()) <= ego_subdue_threshold:
		return true
	return false
