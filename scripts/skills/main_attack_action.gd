extends Skill

class_name MainAttackAction

var combo_dmg = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	skill_name = "ActionMain"
	crit_chance = 10
	accuracy = 100

func use_text() -> String:
	return owner_name+" begins their combo!"

func  hit_text() -> String:
	return "A clean hit for "+str(combo_dmg)+"!"

func  crit_text() -> String:
	return "A brilliant strike for "+str(combo_dmg)+"!"

func  miss_text() -> String:
	return "Huh?"

func use(user: Stats, target: Stats):
	dmg_calcs(user,target)
		
	DialogueManager.print_dialogue(use_text(),BattleManager.dialogue_label)
	#await get_tree().create_timer(0.5).timeout #skill effect would go here

	if !user.enemy:
		if user.inner_hp>hp_cost():
			user.inner_hp -= hp_cost()
		if user.inner_ego>ego_cost():
			user.inner_ego -= ego_cost()
	#BattleManager.animate_bars()
	for i in range(10):
		BattleManager.main_attack_action.get_node("ActionBar/GridContainer").get_children()[i].texture = load("res://images/battles_system/combo_marker_blank.png")
	BattleManager.phase = "main_attack_action"
	user.active_talent.update()
	BattleManager.open_menu()
	DialogueManager.wait_time = 1
	var combo_count = 0
	var dir: String
	var total_dmg = 0
	while combo_count<user.active_talent.main_attack_resource_limit:
		while true:
			if Input.is_action_just_pressed("move_right"):
				dir = "right"
				break
			if Input.is_action_just_pressed("move_left"):
				dir = "left"
				break
			if Input.is_action_just_pressed("move_up"):
				dir = "up"
				break
			if Input.is_action_just_pressed("move_down"):
				dir = "down"
				break
			await get_tree().process_frame
		BattleManager.main_attack_action.get_node("ActionBar/GridContainer").get_children()[combo_count].texture = load("res://images/battles_system/combo_marker_"+dir+".png")
		combo_count+=1
		if BattleManager.rng.randi()%100<=accuracy:
			if BattleManager.rng.randi()%100<=crit_chance:
				combo_dmg = int(randi_range(3,8)*user.active_talent.get_level()/15+hp_dmg_mod)
				if combo_dmg<1:
					combo_dmg = 1
				DialogueManager.print_dialogue("",BattleManager.dialogue_label)
				DialogueManager.print_dialogue(crit_text(),BattleManager.dialogue_label)
			else:
				combo_dmg = int(randi_range(3,8)*user.active_talent.get_level()/15+hp_dmg_mod)/2
				if combo_dmg<1:
					combo_dmg = 1
				DialogueManager.print_dialogue("",BattleManager.dialogue_label)
				DialogueManager.print_dialogue(hit_text(),BattleManager.dialogue_label)
			total_dmg += combo_dmg
			
		else:
			DialogueManager.print_dialogue(miss_text(),BattleManager.dialogue_label)
		if combo_count == user.active_talent.main_attack_resource_limit:
			break
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	await target.take_damage(ego_dmg,total_dmg,1,hp_temp_armor(),ego_temp_armor(),skill_name)
	DialogueManager.wait_time = 0.1
	BattleManager.phase = ""