extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var party: Array[Stats] = [] #holds data for all party members who will appear in battle
var enemies: Array[Stats] = [] #holds data for all enemies who will appear in battle
var participants: Array[Stats] = [] #holds data for all participants including both party and enemies
var categorical_menu_buttons: Array[CustomButton] = [] #holds data for the hoverable menu buttons like Talent, Items, etc...

var party_sprites: Array[TextureButton] = []
var enemy_sprites: Array[TextureRect] = []
var main_menu_sprite: NinePatchRect

var troop: int #holds data for which troop of enemies will be encountered when a battle starts
var bg: int #holds data for which background effect will be loaded when battle starts

var in_battle: bool #referenced by other scripts that may halt functions during a battle
var attacker_index: int = 0 #holds data for which party member is / was last selected to use an attack
var categorical_button_index: int = 0 #holds data for which catergorical button  is / was last selected to access
var menu_index: int = 0
var target_index: int = 0 #holds data for which enemy is / was last targeted for attack
var attacker: Stats = null
var hovered_selection: CustomButton = null
var target: Stats = null

var phase: String = ""
var last_delta: float

############## BUILT IN FUNCTIONS ######################

func _ready():
	pass

func _physics_process(delta):
	last_delta = delta
	return

############### INITIALIZATION FUNCTIONS ###############

func start_battle():
	#remember character's position on the overworld
	#switch to battle scene
	party = GameManager.party
	await EnemyTroops.load(troop)
	participants = party + enemies
	get_scene_references()
	stop_all_flashes()
	in_battle = true
	battle_process()#starts the battle process loop
	return
	
func end_battle():
	in_battle = false
	#switch to overworld scene
	#spawn player at remembered position
	return

func get_scene_references():
	party_sprites.clear()
	enemy_sprites.clear()
	categorical_menu_buttons.clear()
	main_menu_sprite = get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerMenu/Menu")
	for button in main_menu_sprite.get_child(0).get_children():
		categorical_menu_buttons.append(button)
	main_menu_sprite.visible = false
	for i in range (4):
		party_sprites.append(get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerParty"+str(i+1)+"/PartyMember"))
		party_sprites[i].visible = false
	party_sprites[0].grab_focus()
	for i in range (party.size()):
		party_sprites[i].visible = true
		party_sprites[i].material = party_sprites[i].material.duplicate() #give it unique copy of material so it can flash independently of other sprites
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
	for i in range (enemies.size()):
		enemy_sprites.append(get_tree().root.get_node("Battle/CanvasLayer/HBoxContainerEnemy"+str(i+1)+"/Enemy"))
		print(enemy_sprites.size())
		enemy_sprites[i].material = enemy_sprites[i].material.duplicate()
	return
	

############### BATTLE physics FUNCTIONS #####################

func battle_process():
	print("Started battle_process")
	while true:
		print("New lap of battle_process")
		if !all_party_members_exhausted(): #still have a party member we can pick to attack
			await decide_attacker()
			await decide_menu_category()
			await decide_target()
			await determine_enemy_attack()
			await we_attack_enemy()
		else:
			await remaining_enemies_attack()
		reset_exhaustion()
		await get_tree().physics_frame
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
		if Input.is_action_just_pressed("confirm"):
			#play some sound effect
			attacker = party[attacker_index] #sets the attacker equal to the instance of that party member
			break #break out of the loop, return to the battle_physics function, keep on going, yadayadayada
		await get_tree().physics_frame
	phase = ""
	return

func decide_attacker_button(): #same idea as decide_attacker, but by taking advantage of button class
	phase = "decide_attacker"
	stop_all_flashes()
	while(true):
		pass
		await get_tree().physics_frame
	phase = ""
	return

	
func decide_menu_category():
	phase = "decide_menu_category"
	stop_all_flashes()
	open_menu()
	await iterate_categorical_menu_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("move_right"):
			#play some sound effect
			await iterate_categorical_menu_index(1)
		if Input.is_action_just_pressed("move_left"):
			#play some sound effect
			await iterate_categorical_menu_index(-1)
		if Input.is_action_just_pressed("move_down"):
			#play some sound effect
			await iterate_categorical_menu_index(2)
		if Input.is_action_just_pressed("move_up"):
			#play some sound effect
			await iterate_categorical_menu_index(-2)
		if Input.is_action_just_pressed("confirm"):
			#play some sound effect
			hovered_selection = categorical_menu_buttons[categorical_button_index] #sets the hovered button based on categorical_button_index
			await execute_on_hovered_selection()
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		phase = ""
		await get_tree().physics_frame
	return
	
func decide_target():
	await iterate_target_index(0) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("move_right"):
			#play some sound effect
			await iterate_target_index(1)
		if Input.is_action_just_pressed("move_left"):
			#play some sound effect
			await iterate_target_index(-1)
		if Input.is_action_just_pressed("confirm"):
			#play some sound effect
			target = enemies[target_index] #sets the attacker equal to the instance of that troop member
			break #break out of the loop, return to the battle_physics function, keep on going, yadayadayada
		await get_tree().physics_frame
	return
	
func determine_enemy_attack():
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
	while party[attacker_index].is_exhausted():
		attacker_index = keep_iterating(attacker_index, value) #target the next party member over
		attacker_index = posmod(attacker_index,party.size()) #makes sure the attacker_index stays within the size of the party
		await get_tree().physics_frame
	select_flash_attacker()
	return

func iterate_categorical_menu_index(value: int):
	categorical_button_index += value #pick the member to the left of currently hovered party member
	categorical_button_index = posmod(categorical_button_index,4) #makes sure the categorical_button_index stays within the amount of options
	while !categorical_menu_buttons[categorical_button_index].can_hover:
		categorical_button_index = keep_iterating(categorical_button_index, value) #target the next button over
		categorical_button_index = posmod(categorical_button_index,4) #makes sure the categorical_button_index stays within the amount of options
		await get_tree().physics_frame
	return
	
func iterate_target_index(value: int):
	target_index += value #pick the member to the left of currently hovered party member
	target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
	while enemies[target_index].is_subdued(): #can't tareget an enemy that has already been defeated
		target_index = keep_iterating(target_index, value) #target the next enemy over
		target_index = posmod(target_index,enemies.size()) #makes sure the attacker_index stays within the size of the enemy troop
		await get_tree().physics_frame
	return

func keep_iterating(index: int, value: int):
	if value == 0:
		index += 1
	else:
		index += value/abs(value) #iterate by 1 in the original direction we were iterating in
	return index;

func execute_on_hovered_selection():
	await get_tree().physics_frame
	return

func compare_speed(enemy: Stats) -> int:
	var value: int = enemy.attacks[enemy.attack_index]-attacker.attacks[attacker.attack_index]
	if value > 10:
		return -1 #enemy faster
	elif value >= -10 and value <= 10:
		return 0 #tie and mus coinflip beacuase our speed is within 10 points of the enemy
	else:
		return 1 #enemy slower

	
func all_party_members_exhausted() -> bool:
	for member in party:
		if !member.is_exhausted():
			print(member.character_name+" still has it in them!")
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
	#write code to deal damage to enemy and do effects and stuff
	attacker.attack_index += 1 #we now have one less attack this turn
	return

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
	party_sprites[attacker_index].material.set_shader_parameter("flash_enabled", true)
	party_sprites[attacker_index].material.set_shader_parameter("oscillation_speed", 7)
	return

func select_flash_enemy():
	enemy_sprites[target_index].material.set_shader_parameter("flash_enabled", true)
	enemy_sprites[target_index].material.set_shader_parameter("oscillation_speed", 7)
	return

func stop_all_flashes():
	for sprite in party_sprites:
		sprite.material.set_shader_parameter("flash_enabled", false)
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
	main_menu_sprite.visible = true
	while phase == "decide_menu_category":
		party_sprites[attacker_index].get_parent().anchor_left = lerp(party_sprites[attacker_index].get_parent().anchor_left,0.125,last_delta*10.0)
		party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
		await get_tree().physics_frame
	party_sprites[attacker_index].get_parent().anchor_left = attacker_original_anchor
	party_sprites[attacker_index].get_parent().anchor_right = party_sprites[attacker_index].get_parent().anchor_left
	main_menu_sprite.visible = false
	for i in range(party.size()):
		party_sprites[i].visible = true
	return
