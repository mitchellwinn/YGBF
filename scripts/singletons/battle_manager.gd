extends Node

const Stats = preload("res://scripts/stats.gd")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var party: Array[Stats] = [] #holds data for all party members who will appear in battle
var enemies: Array[Stats] = [] #holds data for all enemies who will appear in battle
var participants: Array[Stats] = [] #holds data for all participants including both party and enemies

var troop: int #holds data for which troop of enemies will be encountered when a battle starts
var bg: int #holds data for which background effect will be loaded when battle starts

var in_battle: bool #referenced by other scripts that may halt functions during a battle
var attacker_index: int = 0 #holds data for which party member is / was last selected to use an attack
var attacker: Stats = null

############### INITIALIZATION FUNCTIONS ###############

func start_battle():
	#remember character's position on the overworld
	#switch to battle scene
	initialize_data()
	load_troop()
	in_battle = true
	battle_process()#starts the battle process loop
	return
	
func end_battle():
	initialize_data()
	in_battle = false
	#switch to overworld scene
	#spawn player at remembered position
	return

func initialize_data():
	return
	
func load_troop():
	#load the enemies into the battle
	return

############### BATTLE PROCESS FUNCTIONS #####################

func battle_process():
	while true:
		if !all_party_members_exhausted(): #still have a party member we can pick to attack
			await decide_attacker()
			await determine_enemy_attack()
			await we_attack_enemy(attacker)
		else:
			await remaining_enemies_attack()
		await get_tree().fixed_frame()
		reset_exhaustion()
	return

func decide_attacker():
	await iterate_attacker_index(1) #incase we start the turn hovering someone who is grayed out for some reason; eg. enemy attack exhausts them before they can go
	while(true):
		if Input.is_action_just_pressed("move_right"):
			#play some sound effect
			await iterate_attacker_index(1)
		if Input.is_action_just_pressed("move_left"):
			#play some sound effect
			await iterate_attacker_index(-1)
		attacker_index = attacker_index%party.size() #makes sure the attacker_index stays within the size of the party
		attacker = party[attacker_index] #sets the attacker equal to the instance of that party member
		if Input.is_action_just_pressed("confirm"):
			#play some sound effect
			break #break out of the loop, return to the battle_process function, keep on going, yadayadayada
		await get_tree().fixed_frame()
	return
	
func determine_enemy_attack():
	for enemy in enemies:
		if enemy.is_exhausted(): #if the enemy we would compare speed to has already used all their moves, skip them
			continue
		match compare_speed(enemy, attacker): #
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
	attacker_index += value #pick the member to the left of currently hovered party member
	while(party[attacker_index].isExhausted()):
		attacker_index += value
		await get_tree().fixed_frame()
	return
	
func compare_speed(enemy: Stats, attacker: Stats) -> int:
	var value: int = enemy.attacks[enemy.attack_index]-attacker.attacks[attacker.attack_index]
	if value > 10:
		return -1 #enemy faster
	elif value >= -10 and value <= 10:
		return 0 #tie
	else:
		return 1 #enemy slower
	return value
	
func all_party_members_exhausted() -> bool:
	for member in party:
		if !member.is_exhausted():
			return false #at least one member can still attack, so return false
	return true

func enemy_attacks_us(enemy: Stats):
	#enemy might be another unique class that extends from Stats; haven't decided yet, 
	#but they will have parameters for what skills they know, and maybe a basic
	#algorithm to decide which one they will use
	enemy.attack_index += 1
	return

func we_attack_enemy(attacker: Stats):
	#write code to open menu and pick skill
	#write code to pick which enemy is gonna be attacked
	#write code to deal damage to enemy and do effects and stuff
	attacker.attack_index += 1
	return

func remaining_enemies_attack():
	for enemy in enemies:
		while !enemy.is_exhausted(): #if the enemy we would compare speed to has already used all their moves, skip them
			await enemy_attacks_us(enemy)
			
func reset_exhaustion():
	for participant in participants:
		participant.attack_index = 0
