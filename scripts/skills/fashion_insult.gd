extends Skill

class_name FashionInsult

# Called when the node enters the scene tree for the first time.
func _ready():
    ego_cost = 10
    ego_damage = 30
    skill_name = "Fashion Insult"
    crit_chance = 10
    accuracy = 80

func use_text() -> String:
    return owner_name+" insults "+target_name+"'s fashion sense!"

func  hit_text() -> String:
    return target_name+" got their feelings hurt!"

func  crit_text() -> String:
    return "The insult cut down to the core of "+target_name+"'s identity!"

func  miss_text() -> String:
    return "But "+target_name+" was preoccupied with something else!"