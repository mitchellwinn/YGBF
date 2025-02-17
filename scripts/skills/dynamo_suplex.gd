extends Skill

class_name DynamoSuplex

# Called when the node enters the scene tree for the first time.
func _ready():
    skill_name = "Dynamo Suplex"
    crit_chance = 30
    accuracy = 70

func use_text() -> String:
    return owner_name+" prepares for sheer embrace!"

func  hit_text() -> String:
    return owner_name+" flips "+target_name+" into the ground!"

func  crit_text() -> String:
    return owner_name+" grips "+target_name+" with immense power and drives them straight through the floor!"

func  miss_text() -> String:
    return "But "+target_name+" simply stepped out of the way!"

func ego_cost() -> int:
    return 10

func hp_damage() -> int:
    return 20