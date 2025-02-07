extends Skill

class_name BasicAttack

# Called when the node enters the scene tree for the first time.
func _ready():
    ego_cost = 10
    hp_damage = 20
    skill_name = "Cowardly Smack"
    crit_chance = 10
    accuracy = 80

func use_text() -> String:
    return owner_name+" reels back their arm for a smack!"

func  hit_text() -> String:
    return "That's gotta hurt!"

func  crit_text() -> String:
    return "The smack made direct contact with "+target_name+"'s face!"

func  miss_text() -> String:
    return "But "+target_name+" simply stepped out of the way!"