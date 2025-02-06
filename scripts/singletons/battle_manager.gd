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
var categorical_menu: GridContainer
var act_menu: GridContainer
var dialogue_label: Label

var came_from_overworld: bool
var overworld_position: Vector3

var troop: int #holds data for which troop of enemies will be encountered when a battle starts
var bg: int #holds data for which background effect will be loaded when battle starts

var in_battle: bool #referenced by other scripts that may halt functions during a battle
var attacker_index: int = 0 #holds data for which party member is / was last selected to use an attack
var categorical_button_index: int = 0 #holds data for which catergorical button  is / was last selected to access
var act_button_index: int = 0
var menu_index: int = 0
var current_move_functionality: String
var target_index: int = 0 #holds data for which enemy is / was last targeted for attack
var attacker: Stats = null
var target: Stats = null

var battle_option: String
var phase: String = ""
var minigame_status: int

var model_minigame = preload("res://scenes/minigames/model.tscn")

############## BUILT IN FUNCTIONS ######################

func _ready():
	pass

func _physics_process(_delta):
	pass


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
	menu = get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerMenu")
	categorical_menu = menu.get_node("GridContainerCategorical")
	minigame = get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerMinigame/Minigame")
	minigame_viewport = get_tree().root.get_node("Battle/MinigameViewport")
	minigame_size_guide = get_tree().root.get_node("Battle/CanvasLayer/MinigameSizeGuide")
	act_menu = menu.get_node("GridContainerAct")
	menu.visible = false
	for i in range (4):
		party_sprites.append(get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerParty"+str(i+1)+"/PartyMember"))
		party_sprites[i].visible = false
	for i in range (party.size()):
		party_sprites[i].visible = true
		party_sprites[i].get_node("Character").material = party_sprites[i].get_node("Character").material.duplicate() #give it unique copy of material so it can flash independently of other sprites
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
		enemy_sprites[i].material = enemy_sprites[i].material.duplicate()
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
	while true:
		print("New lap of battle_process")
		await DialogueManager.print_dialogue("A new turn of the battle system.",dialogue_label)
		battle_option = ""
		phase = ""
		current_move_functionality = ""
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
				1: #Skills
					continue
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
			await decide_target()
			await determine_enemy_attack()
			await we_attack_enemy()
		else:
			await remaining_enemies_attack()
			await DialogueManager.print_dialogue("Everyone is exhausted.",dialogue_label)
			reset_exhaustion()
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
			#play some sound effect
			await iterate_attacker_index(1)
		if Input.is_action_just_pressed("move_left"):
			#play some sound effect
			await iterate_attacker_index(-1)
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			GameManager.click_button = ""
			#play some sound effect
			attacker = party[attacker_index] #sets the attacker equal to the instance of that party member
			print(attacker.character_name)
			break #break out of the loop, return to the battle_physics function, keep on going, yadayadayada
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
		categorical_button_index = get_tree().root.get_viewport().gui_get_focus_owner().index
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			#play some sound effect
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
					if enemy.is_subdued():
						button.make_selectable()
	get_tree().get_nodes_in_group("menu_act_buttons")[act_button_index].grab_focus()
	print("grabbed focus")
	#await iterate_categorical_button_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("back"):
			return -1
		act_button_index = get_tree().root.get_viewport().gui_get_focus_owner().index
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			current_move_functionality = get_tree().get_nodes_in_group("menu_act_buttons")[act_button_index].functionality
			#play some sound effect
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().process_frame
	await get_tree().process_frame
	return
	
func decide_target():
	phase = "decide_target"
	stop_all_flashes()
	await iterate_target_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("move_right"):
			#play some sound effect
			await iterate_target_index(1)
		if Input.is_action_just_pressed("move_left"):
			#play some sound effect
			await iterate_target_index(-1)
		if Input.is_action_just_pressed("confirm") || GameManager.click_button == phase:
			#play some sound effect
			target = enemies[target_index] #sets the attacker equal to the instance of that troop member
			break #break out of the loop, return to the battle_physics function, keep on going, yadayadayada
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
# 		await get_tree().physics_frame
# 	categorical_menu_buttons[categorical_button_index].grab_focus()
# 	return
	
func iterate_target_index(value: int):
	stop_all_flashes()
	target_index += value #pick the member to the left of currently hovered party member
	target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
	while current_move_functionality == "pacify" and !enemies[target_index].is_subdued(): #can't target an enemy for pacification that has not been subdued
		target_index = keep_iterating(target_index, value) #target the next enemy over
		target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
		await get_tree().process_frame
	while enemies[target_index].is_defeated(): #can't target an enemy that has already been defeated
		target_index = keep_iterating(target_index, value) #target the next enemy over
		target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
		await get_tree().process_frame
	select_flash_enemy()
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
	#enemy might be another unique class that extends from Stats; haven't decided yet, 
	#but they will have parameters for what skills they know, and maybe a basic
	#algorithm to decide which one they will use
	enemy.attack_index += 1 #enemy now has one less attack this turn
	return

func we_attack_enemy():
	match battle_option:
		"attack":
			pass
		"pacify":
			await play_minigame()
			pass
		_:
			pass
	attacker.attack_index += 1 #we now have one less attack this turn
	return

func play_minigame():
	minigame_status = -1 #this is redundant as minigames will set this as well for testing in an isolated space
	var minigame_instance
	stop_all_flashes()
	match attacker.talent.to_lower():
		"model":
			minigame_instance = model_minigame.instantiate()
	minigame_viewport.add_child(minigame_instance)
	minigame.visible = true
	while(minigame_status == -1):
		minigame_viewport.size = minigame_size_guide.size
		await get_tree().process_frame
	minigame.visible = false
	minigame_instance.queue_free()
	match minigame_status:
		0: #minigame fail
			pass
		1: #minigame success
			target.pacified = true

func remaining_enemies_attack():
	for enemy in enemies:
		while !enemy.is_exhausted(): #if the enemy we would compare speed to has already used all their moves, skip them
			await enemy_attacks_us(enemy)
			
func reset_exhaustion():
	for participant in participants:
		participant.attack_index = 0

################### VISUAL HELPER FUNCTIONS #####################

func select_flash_attacker():
	print ("Flash select attacker_index"+str(attacker_index))
	party_sprites[attacker_index].get_node("Character").material.set_shader_parameter("flash_enabled", true)
	party_sprites[attacker_index].get_node("Character").material.set_shader_parameter("oscillation_speed", 7)
	return

func select_flash_enemy():
	enemy_sprites[target_index].material.set_shader_parameter("flash_enabled", true)
	enemy_sprites[target_index].material.set_shader_parameter("oscillation_speed", 7)
	return

func stop_all_flashes():
	for sprite in party_sprites:
		sprite.get_node("Character").material.set_shader_parameter("flash_enabled", false)
	for sprite in enemy_sprites:
		sprite.material.set_shader_parameter("flash_enabled", false)
	return

func open_menu():
	for sprite in party_sprites:
		if sprite != party_sprites[attacker_index]:
			sprite.visible = false;
		else:
			sprite.visible = true
	var attacker_original_anchor = party_sprites[attacker_index].get_parent().anchor_left
	menu.visible = true
	while true:
		match phase:
			"decide_menu_category":
				categorical_menu.visible = true
				act_menu.visible = false
				party_sprites[attacker_index].get_parent().anchor_left = lerp(party_sprites[attacker_index].get_parent().anchor_left,0.125,GameManager.last_delta*20.0)
				party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
			"decide_menu_act":
				act_menu.visible = true
				categorical_menu.visible = false
				party_sprites[attacker_index].get_parent().anchor_left = lerp(party_sprites[attacker_index].get_parent().anchor_left,0.125,GameManager.last_delta*20.0)
				party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
			_:
				break
		await get_tree().physics_frame
	party_sprites[attacker_index].get_parent().anchor_left = attacker_original_anchor
	party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
	menu.visible = false
	for i in range(party.size()):
		party_sprites[i].visible = true
	return
