extends Node

class_name Talent

var talent: String
var skills: Array[Skill]
var main_attack: Skill

var main_attack_resource_count: int
var main_attack_resource_limit: int
var main_attack_resource_limit_cap: int
var main_attack_hp: int
var main_attack_ego: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass