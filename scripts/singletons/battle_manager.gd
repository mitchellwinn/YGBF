extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var party: Array[Stats] = [] #holds data for all party members who will appear in battle
var enemies: Array[Stats] = [] #holds data for all enemies who will appear in battle
var participants: Array[Stats] = [] #holds data for all participants including both party and enemies

var party_sprites: Array[TextureButton] = []
var enemy_sprites: Array[TextureButton] = []
var menu: HBoxContainer
var minigame: TextureRect
var minigame_size_guide: HBoxContainer
var minigame_viewport: SubViewport
var categorical_menu: Control
var act_menu: GridContainer
var skill_menu: GridContainer
var talent_menu: GridContainer
var main_attack_model #not sure on the type yet
var main_attack_action #not sure on the type yet
var dialogue_label: Label
var sfx_player: PackedScene = preload("res://prefabs/sfx_player.tscn")
var dialogue_sfx_player: AudioStreamPlayer2D

var came_from_overworld: bool
var overworld_position: Vector3

var troop: int #holds data for which troop of enemies will be encountered when a battle starts
var bg: int #holds data for which background effect will be loaded when battle starts

var in_battle: bool #referenced by other scripts that may halt functions during a battle
var attacker_index: int = 0 #holds data for which party member is / was last selected to use an attack
var categorical_button_index: int = 0 #holds data for which catergorical button  is / was last selected to access
var act_button_index: int = 0
var talent_button_index: int = 0
var skill_button_index: int = 0
var menu_index: int = 0
var current_move_functionality: String
var target_index: int = 0 #holds data for which enemy is / was last targeted for attack
var ally_index: int = 0
var attacker: Stats = null
var target: Stats = null
var ally: Stats = null
var prepared_skill: Skill = null
var prepared_talent: Talent = null
var target_ally: bool

var battle_option: String
var phase: String = ""
var minigame_status: int

var model_minigame = preload("res://scenes/minigames/model.tscn")
var punchout_minigame = preload("res://scenes/minigames/punchout.tscn")

############## BUILT IN FUNCTIONS ######################

func _ready():
	pass

func _process(delta):
	if !in_battle:
		return
	animate_bars(delta)


############### INITIALIZATION FUNCTIONS ###############

func start_battle():
	if get_tree().current_scene.name.to_lower() != "battle":
		overworld_position = get_node("/root/Player").position
		get_tree().change_scene_to_file("res://scenes/battle.tscn")
		came_from_overworld = true
	party = GameManager.party
	await EnemyTroops.load(troop)
	participants = party + enemies
	get_scene_references()
	stop_all_flashes()
	in_battle = true
	battle_process()#starts the battle process loop
	return
	
func end_battle(result: int):
	in_battle = false
	match result:
		0:
			GameManager.game_over()
		1:
			if came_from_overworld:
				reload_overworld()
				return
			get_tree().quit()

func reload_overworld():
	get_tree().change_scene_to_file.call_deferred("res://scenes/maps/"+GameManager.overworld_map+".tscn")
	get_node("/root/Player").position = overworld_position

func get_scene_references():
	party_sprites.clear()
	enemy_sprites.clear()
	dialogue_label = get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerDialogue/DialogueGuide/Label")
	dialogue_label.get_parent().visible = false
	dialogue_sfx_player = get_tree().root.get_node("Battle/DialogueSfxPlayer")
	menu = get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerMenu")
	main_attack_model = menu.get_node("MainAttackModel")
	main_attack_action = menu.get_node("MainAttackAction")
	categorical_menu = menu.get_node("Categories")
	minigame = get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerMinigame/Minigame")
	minigame_viewport = get_tree().root.get_node("Battle/MinigameViewport")
	minigame_size_guide = get_tree().root.get_node("Battle/CanvasLayer/MinigameSizeGuide")
	act_menu = menu.get_node("GridContainerAct")
	talent_menu = menu.get_node("GridContainerTalent")
	skill_menu = menu.get_node("GridContainerSkills")
	menu.visible = false
	for flashable in get_tree().get_nodes_in_group("flashable"):
		flashable.material = flashable.material.duplicate()
	for i in range (4):
		party_sprites.append(get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerParty"+str(i+1)+"/PartyMember"))
		party_sprites[i].visible = false
	for i in range (party.size()):
		party_sprites[i].visible = true
		party_sprites[i].get_node("Frame/Character").sprite.texture = party[i].sprite
		party[i].animator = party_sprites[i].get_node("Frame/Character").animator
		party_sprites[i].get_node("Frame/Character").material = party_sprites[i].get_node("Frame/Character").material.duplicate() #give it unique copy of material so it can flash independently of other sprites
		match party.size():
			1:
				party_sprites[0].get_parent().anchor_left = .5
			2:
				party_sprites[0].get_parent().anchor_left = .5-.125
				party_sprites[1].get_parent().anchor_left = .5+.125
			3:
				party_sprites[0].get_parent().anchor_left = .25
				party_sprites[1].get_parent().anchor_left = .5
				party_sprites[1].get_parent().anchor_left = .75
			4:
				pass #it's already the right anchor setup by default when we load the scene
		party_sprites[i].anchor_right = party_sprites[i].anchor_left
	for i in range (3):
		enemy_sprites.append(get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerEnemy"+str(i+1)+"/Enemy"))
		enemy_sprites[i].visible = false
	for i in range (enemies.size()):
		enemy_sprites[i].visible = true
		enemy_sprites[i].sprite.texture = enemies[i].sprite
		enemies[i].animator = enemy_sprites[i].animator
		enemy_sprites[i].get_node("Enemy").material = enemy_sprites[i].get_node("Enemy").material.duplicate()
		match enemies.size():
			1:
				enemy_sprites[0].get_parent().anchor_left = .5
			2:
				enemy_sprites[0].get_parent().anchor_left = .5-.125
				enemy_sprites[1].get_parent().anchor_left = .5+.125
			3:
				pass #it's already the right anchor setup by default when we load the scene
	return
	

############### BATTLE PROCESS FUNCTIONS #####################

func battle_process():
	print("Started battle_process")
	for participant in participants:
		participant.restore_resources_full()
	await DialogueManager.print_dialogue(EnemyTroops.entry_message(troop), dialogue_label)
	await DialogueManager.print_dialogue("How are we gonna deal with this?", dialogue_label)
	while true:
		print("New lap of battle_process")
		#await DialogueManager.print_dialogue("A new turn of the battle system.",dialogue_label)
		battle_option = ""
		phase = ""
		current_move_functionality = ""
		target_ally = false
		await get_tree().process_frame
		if all_party_members_defeated():
			end_battle(0) #we lost the battle
			return
		if all_enemies_defeated():
			end_battle(1) #we won the battle
			return
		if !all_party_members_exhausted(): #still have a party member we can pick to attack
			await decide_attacker()
			if await decide_menu_category() == -1:
				continue
			match categorical_button_index: #this determines what happens based on the menu we picked
				0: #Main Attack
					battle_option = "attack"
					prepared_skill = attacker.active_talent.main_attack
					if await decide_menu_main() == -1:
						continue
				1: #Skills
					if await decide_menu_skill() == -1:
						continue
					battle_option = "skill"
					prepared_skill = attacker.active_talent.skills[skill_button_index]
				2: #Act
					if await decide_menu_act() == -1:
						continue
					match act_button_index:
						0: #Run
							continue
						1: #Study
							continue
						2: #Pacify
							battle_option = "pacify"
						_:
							continue
				3: #Item
					continue
				4: #Change
					print("change")
					battle_option = "change"
					if await decide_menu_talent() == -1:
						continue
					prepared_talent = attacker.talents[talent_button_index]
			if battle_option != "change":
				if target_ally:
					if await decide_ally() == -1:
						continue
				else:
					if await decide_target() == -1:
						continue
			stop_all_flashes()
			await determine_enemy_attack()
			await we_attack_enemy()
		else:
			await remaining_enemies_attack()
			#await DialogueManager.print_dialogue("Everyone is exhausted.",dialogue_label)
			reset_exhaustion_and_recover()
		await get_tree().process_frame
	return

func decide_attacker():
	phase = "decide_attacker"
	stop_all_flashes()
	print("Initial attacker_index before iteration: "+str(attacker_index))
	await iterate_attacker_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	print("Initial attacker_index after iteration: "+str(attacker_index))
	while(true):
		if Input.is_action_just_pressed("move_right"):
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
			await iterate_attacker_index(1)
		if Input.is_action_just_pressed("move_left"):
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
			await iterate_attacker_index(-1)
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			GameManager.click_button = ""
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			attacker = party[attacker_index] #sets the attacker equal to the instance of that party member
			print(attacker.character_name)
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return

func decide_menu_main():
	phase = "decide_menu_"+attacker.active_talent.talent
	if phase == "decide_menu_action":
		return
	stop_all_flashes()
	await get_tree().process_frame
	var index: int = 0
	get_tree().get_nodes_in_group("menu_"+attacker.active_talent.talent+"_buttons")[0].grab_focus()
	get_tree().root.get_viewport().gui_get_focus_owner().material.set_shader_parameter("flash_enabled", true)
	match attacker.active_talent.talent:
			"model":
				target_ally = true
				check_model_resources()

	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		match attacker.active_talent.talent:
			"model":
				model_main_actions(index)
		if (index != get_tree().root.get_viewport().gui_get_focus_owner().index):
			index = get_tree().root.get_viewport().gui_get_focus_owner().index
			stop_all_flashes()
			if get_tree().root.get_viewport().gui_get_focus_owner().is_in_group("flashable"):
				get_tree().root.get_viewport().gui_get_focus_owner().material.set_shader_parameter("flash_enabled", true)
				GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		if (Input.is_action_just_pressed("confirm") || GameManager.click_button == phase) and get_tree().root.get_viewport().gui_get_focus_owner().functionality == "finish":
			match attacker.active_talent.talent:
				"model":
					if attacker.active_talent.main_attack_resource_count<=0:
						await get_tree().process_frame
						print("continue")
						continue
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return

func decide_menu_category():
	phase = "decide_menu_category"
	stop_all_flashes()
	open_menu()
	get_tree().get_nodes_in_group("menu_categorical_buttons")[categorical_button_index].grab_focus()
	#await iterate_categorical_button_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		if (categorical_button_index != get_tree().root.get_viewport().gui_get_focus_owner().index):
			categorical_button_index = get_tree().root.get_viewport().gui_get_focus_owner().index
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return

func decide_menu_act():
	phase = "decide_menu_act"
	print(phase)
	stop_all_flashes()
	for button in get_tree().get_nodes_in_group("menu_act_buttons"):
		match button.functionality:
			"pacify":
				button.make_unselectable()
				for enemy in enemies:
					if enemy.is_subdued() and !enemy.is_defeated():
						button.make_selectable()		
	get_tree().get_nodes_in_group("menu_act_buttons")[act_button_index].grab_focus()
	print("grabbed focus")
	#await iterate_categorical_button_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		
		print("the gui focus goes to: "+get_tree().root.get_viewport().gui_get_focus_owner().name)
		if (act_button_index != get_tree().root.get_viewport().gui_get_focus_owner().index):
			act_button_index = get_tree().root.get_viewport().gui_get_focus_owner().index
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			current_move_functionality = get_tree().get_nodes_in_group("menu_act_buttons")[act_button_index].functionality
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return

func decide_menu_skill():
	phase = "decide_menu_skill"
	print(phase)
	stop_all_flashes()
	await populate_skill_buttons()
	for button in get_tree().get_nodes_in_group("menu_skill_buttons"):
		if attacker.active_talent.skills[button.index].hp_cost()>=attacker.inner_hp or attacker.active_talent.skills[button.index].ego_cost()>=attacker.inner_ego:
			button.make_unselectable()
			print("unselectable")
		else:
			button.make_selectable()
			print("selectable")
	print("skill index: "+str(skill_button_index))
	if skill_button_index < get_tree().get_nodes_in_group("menu_skill_buttons").size():
		pass
	else:
		skill_button_index = 0
	get_tree().get_nodes_in_group("menu_skill_buttons")[skill_button_index].grab_focus()
	print("grabbed focus")
	#await iterate_categorical_button_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		if (get_tree().root.get_viewport().gui_get_focus_owner()):
			if (skill_button_index != get_tree().root.get_viewport().gui_get_focus_owner().index):
				skill_button_index = get_tree().root.get_viewport().gui_get_focus_owner().index
				GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		else:
			await get_tree().process_frame
			continue
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			current_move_functionality = "skill"
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return

func decide_menu_talent():
	phase = "decide_menu_talent"
	print(phase)
	stop_all_flashes()
	await populate_talent_buttons()
	get_tree().get_nodes_in_group("menu_talent_buttons")[skill_button_index].grab_focus()
	while !get_tree().root.get_viewport().gui_get_focus_owner():
		talent_button_index+=1
		talent_button_index = talent_button_index%get_tree().get_nodes_in_group("menu_talent_buttons").size()
		get_tree().get_nodes_in_group("menu_talent_buttons")[skill_button_index].grab_focus()
	print("grabbed focus")
	#await iterate_categorical_button_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		if (get_tree().root.get_viewport().gui_get_focus_owner()):
			if (talent_button_index != get_tree().root.get_viewport().gui_get_focus_owner().index):
				talent_button_index = get_tree().root.get_viewport().gui_get_focus_owner().index
				print(talent_button_index)
				GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		else:
			await get_tree().process_frame
			continue
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return
	
func decide_target():
	phase = "decide_target"
	stop_all_flashes()
	await iterate_target_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		if Input.is_action_just_pressed("move_right"):
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
			await iterate_target_index(1)
		if Input.is_action_just_pressed("move_left"):
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
			await iterate_target_index(-1)
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			target = enemies[target_index] #sets the attacker equal to the instance of that troop member
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return

func decide_ally():
	phase = "decide_ally"
	stop_all_flashes()
	await iterate_ally_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		if Input.is_action_just_pressed("move_right"):
			GameManager.play_sound(sfx_player,"res://sounds/digi select.wav")
			await iterate_ally_index(1)
		if Input.is_action_just_pressed("move_left"):
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
			await iterate_ally_index(-1)
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
			ally = party[ally_index] #sets the attacker equal to the instance of that troop member
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return
	
func determine_enemy_attack():
	phase = "determine_enemy_attack"
	for enemy in enemies:
		if enemy.is_exhausted(): #if the enemy we would compare speed to has already used all their moves, skip them
			continue
		match compare_speed(enemy): #
			-1:
				await enemy_attacks_us(enemy) #we are slower than the enemy, enemy attacks us
			0:
				var coinflip: int = rng.randi()%2 #we are within 10 speed of the enemy, coinflip
				match coinflip:
					0:
						pass #enemy flipped tails, they don't attack us
					1:
						await enemy_attacks_us(enemy) #enemy flipped heads, they get to attack us
			1:
				pass #we are faster than the enemy, enemy does not get to attack us
	return

############### TALENT SPECIFIC ACTIONS ###############

func check_model_resources():
	while attacker.active_talent.main_attack_resource_count > attacker.active_talent.main_attack_resource_limit:
		if attacker.active_talent.main_attack_ego > 0:
			attacker.active_talent.main_attack_ego -= 1
			attacker.active_talent.main_attack_resource_count -= 1
		elif attacker.active_talent.main_attack_hp > 0 and attacker.active_talent.main_attack_resource_count > attacker.active_talent.main_attack_resource_limit:
			attacker.active_talent.main_attack_hp -= 1
			attacker.active_talent.main_attack_resource_count -= 1
		
	for i in range(10):
		main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture = main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.duplicate()
		main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.gradient = main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.gradient.duplicate()
		main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture = main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.duplicate()
		main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.gradient = main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.gradient.duplicate()
		main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.WHITE)
		main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.WHITE)
	for i in range(attacker.active_talent.main_attack_ego):
		main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.BLUE)
	for i in range(attacker.active_talent.main_attack_hp):
		main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.GREEN)

func model_main_actions(index: int):
	var value = 0
	if Input.is_action_just_pressed("move_right"):
		GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		if attacker.active_talent.main_attack_resource_count>=attacker.active_talent.main_attack_resource_limit: #no more resources to allocate
			return
		value = 1
	if Input.is_action_just_pressed("move_left"):
		GameManager.play_sound(sfx_player,"res://sounds/digi move.wav")
		if attacker.active_talent.main_attack_resource_count<=0: #bar is already zero
			return
		value = -1
	match index:
		0: #we are hovering the HP bar
			if attacker.active_talent.main_attack_hp<=0 and value == -1:
				return
			attacker.active_talent.main_attack_hp += value
			attacker.active_talent.main_attack_resource_count += value
		1: #we are hovering the EGO bar
			if attacker.active_talent.main_attack_ego<=0 and value == -1:
				return
			attacker.active_talent.main_attack_ego += value
			attacker.active_talent.main_attack_resource_count += value
		_:
			pass
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_left"):
		for i in range(10):
			
			if i<= attacker.active_talent.main_attack_ego-1:
				main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.BLUE)
			else:
				main_attack_model.get_node("EgoBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.WHITE)
			if i<= attacker.active_talent.main_attack_hp-1:
				main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.GREEN)
			else:
				main_attack_model.get_node("HpBar").get_child(0).get_children()[i].texture.gradient.set_color(0,Color.WHITE)

############### BATTLE HELPER FUNCTIONS ###############

func iterate_attacker_index(value: int):
	stop_all_flashes()
	attacker_index += value #pick the member to the left of currently hovered party member
	attacker_index = posmod(attacker_index,party.size()) #makes sure the attacker_index stays within the size of the party
	while party[attacker_index].is_exhausted() || party[attacker_index].is_defeated():
		attacker_index = keep_iterating(attacker_index, value) #target the next party member over
		attacker_index = posmod(attacker_index,party.size()) #makes sure the attacker_index stays within the size of the party
		await get_tree().process_frame
	select_flash_attacker()
	return

# func iterate_categorical_button_index(value: int):
# 	categorical_button_index += value #pick the member to the left of currently hovered party member
# 	categorical_button_index = posmod(categorical_button_index,4) #makes sure the categorical_button_index stays within the amount of options
# 	while true:
# 		categorical_button_index = keep_iterating(categorical_button_index, value) #target the next button over
# 		categorical_button_index = posmod(categorical_button_index,4) #makes sure the categorical_button_index stays within the amount of options
# 		await get_tree().process_frame
# 	categorical_menu_buttons[categorical_button_index].grab_focus()
# 	return
	
func iterate_target_index(value: int):
	stop_all_flashes()
	target_index += value #pick the member to the seleceted side of currently hovered party member
	target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
	while current_move_functionality == "pacify" and (!enemies[target_index].is_subdued() or enemies[target_index].is_defeated()): #can't target an enemy for pacification that has not been subdued
		target_index = keep_iterating(target_index, value) #target the next enemy over
		target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
		await get_tree().process_frame
	while enemies[target_index].is_defeated(): #can't target an enemy that has already been defeated
		target_index = keep_iterating(target_index, value) #target the next enemy over
		target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
		await get_tree().process_frame
	select_flash_enemy()
	return

func iterate_ally_index(value: int):
	stop_all_flashes()
	ally_index += value #pick the member to the left of currently hovered party member
	ally_index = posmod(ally_index,party.size()) #makes sure the ally_index stays within the size of the party
	while party[ally_index].is_defeated(): #can't pick a defeated ally
		ally_index = keep_iterating(ally_index, value) #target next ally over
		ally_index = posmod(ally_index,party.size()) #makes sure the ally_index stays within the size of the party
		await get_tree().process_frame
	select_flash_ally()
	return

func keep_iterating(index: int, value: int):
	if value == 0:
		index += 1
	else:
		index += value/abs(value) #iterate by 1 in the original direction we were iterating in
	return index;

func compare_speed(enemy: Stats) -> int:
	var value: int = enemy.attacks[enemy.attack_index]-attacker.attacks[attacker.attack_index]
	if value > 10:
		return -1 #enemy faster
	elif value >= -10 and value <= 10:
		return 0 #tie and mus coinflip beacuase our speed is within 10 points of the enemy
	else:
		return 1 #enemy slower

func all_party_members_defeated() -> bool:
	print("Checking if all party members are defeated...")
	for member in party:
		print("checking if "+member.character_name+" is defeated")
		if !member.is_defeated():
			print(member.character_name+" is still alive! Keep battling")
			return false #at least one member is still alive, so return false
	print("All party members are defeated")
	return true

func all_enemies_defeated() -> bool:
	print("Checking if all enemies have been defeated...")
	for enemy in enemies:
		if !enemy.is_defeated():
			print(enemy.character_name+" is still alive! Keep battling")
			return false #at least one enemy is alive, so return false
	print("All enemies are defeated")
	return true

func all_party_members_exhausted() -> bool:
	print("Checking if all party members are exhausted...")
	for member in party:
		if !member.is_exhausted():
			print(member.character_name+" still has it in them! Keep selecting moves")
			return false #at least one member can still attack, so return false
	print("All party members are exhausted")
	return true

func enemy_attacks_us(enemy: Stats):
	if enemy.is_defeated():
		await DialogueManager.print_dialogue(enemy.character_name+" was defeated before it had a chance to use its next attack!",dialogue_label)
		return
	var viable_party_targets: Array[Stats]
	for member in party:
		if !member.is_defeated():
			viable_party_targets.append(member)
	await enemy.active_talent.skills[rng.randi()%enemy.active_talent.skills.size()].use(enemy,viable_party_targets[rng.randi()%viable_party_targets.size()])
	enemy.attack_index += 1 #enemy now has one less attack this turn
	return

func we_attack_enemy():
	if attacker.is_defeated():
		await DialogueManager.print_dialogue(attacker.character_name+" can no longer go through with the plan!",dialogue_label)
		return
	match battle_option:
		"attack","skill":
			if target_ally:
				await prepared_skill.use(attacker,ally)
			else:
				await prepared_skill.use(attacker,target)
		"pacify":
			await play_minigame()
			if target.animator and (target.is_defeated()):
				GameManager.play_sound(BattleManager.sfx_player,"res://sounds/ego_dmg.wav")
				target.animator.play("defeated")
			pass
		"change":
			#await change_talent_animation()
			print(talent_button_index)
			print(prepared_talent.talent)
			attacker.active_talent = prepared_talent
			await DialogueManager.print_dialogue(attacker.character_name+" has taken on the "+attacker.active_talent.talent.capitalize()+" persona!",dialogue_label)
			pass
		_:
			pass
	attacker.attack_index += 1 #we now have one less attack this turn
	return



func play_minigame():
	minigame_status = -1 #this is redundant as minigames will set this as well for testing in an isolated space
	var minigame_instance
	stop_all_flashes()
	match attacker.active_talent.talent.to_lower():
		"model":
			minigame_instance = model_minigame.instantiate()
		"action":
			minigame_instance = punchout_minigame.instantiate()
	minigame_viewport.add_child(minigame_instance)
	minigame.visible = true
	while(minigame_status == -1):
		minigame_viewport.size = minigame_size_guide.size
		await get_tree().process_frame
	minigame.visible = false
	minigame_instance.queue_free()
	match minigame_status:
		0: #minigame fail
			GameManager.play_sound(sfx_player,"res://sounds/oh great job dumbass.wav")
			await DialogueManager.print_dialogue(target.character_name+" was unimpressed with "+attacker.character_name+"'s performance!",dialogue_label)
		1: #minigame success
			target.pacified = true
			act_button_index = 0
			for enemy in enemies:
				if enemy.is_subdued() and !enemy.is_defeated():
					act_button_index = 2
			GameManager.play_sound(sfx_player,"res://sounds/you did it.wav")
			await DialogueManager.print_dialogue(target.character_name+" was pacified by "+attacker.character_name+"'s performance!",dialogue_label)

func remaining_enemies_attack():
	for enemy in enemies:
		while !enemy.is_exhausted(): #if the enemy we would compare speed to has already used all their moves, skip them
			await enemy_attacks_us(enemy)
			
func reset_exhaustion_and_recover():
	for participant in participants:
		participant.attack_index = 0
		participant.restore_resources_iterate()

func populate_skill_buttons():
	for button in skill_menu.get_children():
		button.queue_free()
	var i: int = 0
	for skill in attacker.active_talent.skills:
		print("make skill button")
		var new_button = await load("res://prefabs/battle_button.tscn").instantiate()
		skill_menu.add_child(new_button)
		new_button.text = attacker.active_talent.skills[i].skill_name
		new_button.index = i
		new_button.add_to_group("menu_skill_buttons")
		i+=1
	await get_tree().process_frame

func populate_talent_buttons():
	for button in talent_menu.get_children():
		button.queue_free()
	var i: int = 0
	for talent in attacker.talents:
		print("new talent button")
		var new_button = await load("res://prefabs/battle_button.tscn").instantiate()
		talent_menu.add_child(new_button)
		new_button.text = attacker.talents[i].talent.capitalize()
		new_button.index = i
		new_button.add_to_group("menu_talent_buttons")
		i+=1
	await get_tree().process_frame

################### VISUAL HELPER FUNCTIONS #####################

func select_flash_attacker():
	print ("Flash select attacker_index"+str(attacker_index))
	party_sprites[attacker_index].get_node("Frame/Character").material.set_shader_parameter("flash_enabled", true)
	party_sprites[attacker_index].get_node("Frame/Character").material.set_shader_parameter("oscillation_speed", 7)
	return

func select_flash_ally():
	print ("Flash select attacker_index"+str(ally_index))
	party_sprites[ally_index].get_node("Frame/Character").material.set_shader_parameter("flash_enabled", true)
	party_sprites[ally_index].get_node("Frame/Character").material.set_shader_parameter("oscillation_speed", 7)
	return

func select_flash_enemy():
	enemy_sprites[target_index].get_node("Enemy").material.set_shader_parameter("flash_enabled", true)
	enemy_sprites[target_index].get_node("Enemy").material.set_shader_parameter("oscillation_speed", 7)
	return

func stop_all_flashes():
	for sprite in party_sprites:
		sprite.get_node("Frame/Character").material.set_shader_parameter("flash_enabled", false)
	for sprite in enemy_sprites:
		sprite.get_node("Enemy").material.set_shader_parameter("flash_enabled", false)
	for flashable in get_tree().get_nodes_in_group("flashable"):
		flashable.material.set_shader_parameter("flash_enabled", false)
	return

func animate_bars(delta):
	for i in range(party.size()):
		party_sprites[i].get_node("Hp/Armor2").value = (move_toward(party_sprites[i].get_node("Hp/Armor2").value,float(party[i].temporary_hp_armor)/float(party[i].get_max_hp_armor())*100,delta*500))
		party_sprites[i].get_node("Ego/Armor2").value = (move_toward(party_sprites[i].get_node("Ego/Armor2").value,float(party[i].temporary_ego_armor)/float(party[i].get_max_ego_armor())*100,delta*500))
		party_sprites[i].get_node("Hp/Armor/Bar").value = (move_toward(party_sprites[i].get_node("Hp/Armor/Bar").value,float(party[i].inner_hp)/float(party[i].get_max_hp())*100,delta*500))
		party_sprites[i].get_node("Hp/Armor").value = (move_toward(party_sprites[i].get_node("Hp/Armor").value,float(party[i].hp_armor)/float(party[i].get_max_hp_armor())*100,delta*500))
		party_sprites[i].get_node("Ego/Armor/Bar").value = (move_toward(party_sprites[i].get_node("Ego/Armor/Bar").value,float(party[i].inner_ego)/float(party[i].get_max_ego())*100,delta*500))
		party_sprites[i].get_node("Ego/Armor").value = (move_toward(party_sprites[i].get_node("Ego/Armor").value,float( party[i].ego_armor)/float(party[i].get_max_ego_armor())*100,delta*500))

func open_menu():
	for sprite in party_sprites:
		if sprite != party_sprites[attacker_index]:
			sprite.visible = false;
		else:
			sprite.visible = true
	var attacker_original_anchor = party_sprites[attacker_index].get_parent().anchor_left
	menu.visible = true
	var phase_last_frame = ""
	while true:
		party_sprites[attacker_index].get_parent().anchor_left = lerp(party_sprites[attacker_index].get_parent().anchor_left,0.117,GameManager.last_delta*20.0)
		party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
		if phase!=phase_last_frame:
			categorical_menu.visible = false
			skill_menu.visible = false
			act_menu.visible = false
			talent_menu.visible = false
			main_attack_model.visible = false
			main_attack_action.visible = false
			match phase:
				"decide_menu_talent":
					talent_menu.visible = true
				"decide_menu_category":
					categorical_menu.visible = true
					categorical_menu.get_node("GridContainerCategorical").size.x = menu.size.x
				"decide_menu_act":
					act_menu.visible = true
				"decide_menu_skill":
					skill_menu.visible = true
				"decide_menu_model":
					main_attack_model.visible = true
					main_attack_model.get_node("HpBar").size.x = menu.size.x
					print(menu.size.x)
				"main_attack_action":
					main_attack_action.visible = true
					main_attack_action.get_node("ActionBar").size.x = menu.size.x
					print(menu.size.x)
				_:
					break
		match phase:
			"main_attack_action":
					main_attack_action.get_node("ActionBar").size.x = menu.size.x
			"decide_menu_category":
					categorical_menu.get_node("GridContainerCategorical").size.x = menu.size.x
			"decide_menu_model":
				main_attack_model.get_node("HpBar").size.x = menu.size.x
				main_attack_model.get_node("HpBar").get_child(0).size.x = menu.size.x-9
				main_attack_model.get_node("EgoBar").size.x = menu.size.x
				main_attack_model.get_node("EgoBar").get_child(0).size.x = menu.size.x-9
				main_attack_model.get_node("Count").text = str(attacker.active_talent.main_attack_resource_limit-attacker.active_talent.main_attack_resource_count)+"/"+str(attacker.active_talent.main_attack_resource_limit)+" Available"
			_:
				pass
		phase_last_frame = phase
		await get_tree().process_frame
	print("put stuff back to normal")
	party_sprites[attacker_index].get_parent().anchor_left = attacker_original_anchor
	party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
	menu.visible = false
	for i in range(party.size()):
		party_sprites[i].visible = true
	return
