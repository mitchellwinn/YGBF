extends Node

class_name Stats

var hp: int #holds data for current hp
var ego: int #holds data for current ego
var ego_subdue_threshold: float #[0.0-1.0] represents percentage of max ego that ego needs to decrease beyond to subdue
var attacks: Array[int] = [] #holds data for each attack that can be performed per turn and its corresponding speed (thats what the int is for)
var attack_index: int = 0 #holds data for which index of move the player is on, most of the time this is 0 if they haven't attacked this turn, 1 if they have
var character_name: String

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
	if is_subdued(): #if entity is subdued they also cannot attack lol
		return true
	if attack_index>=attacks.size():
		return true #we have used more attacks than we have available this turn, we are exhausted
	return false 

func is_subdued() -> bool:
	if hp <= 0:
		return true
	if float(ego)/float(get_max_ego()) <= ego_subdue_threshold:
		return true
	return false
