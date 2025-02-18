extends Node

class_name Talent

var talent_owner: Stats

var talent: String
var skills: Array[Skill]
var main_attack: Skill

var main_attack_resource_count: int
var main_attack_resource_limit: int
var main_attack_resource_limit_cap: int
var main_attack_hp: int
var main_attack_ego: int

var exp: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func gain_exp(value: int):
	exp += value
	if exp > talent_owner.level_cap*10:
		exp = talent_owner.level_cap*10

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