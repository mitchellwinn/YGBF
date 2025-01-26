extends Node

const Stats = preload("res://scripts/stats.gd")

var party: Array[Stats] = [] #holds data for all party members who will appear in battle
var participants: Array[Stats] = [] #holds data for all participants including enemies; can be sorted for turn order
var troop: int #holds data for which troop of enemies will be encountered when a battle starts
var bg: int #holds data for which background effect will be loaded when battle starts

var in_battle: bool #determines whether the _process function should be trying to process the battle
var turn: int #holds data for which participant's turn is active
var phase: int #holds data for which part of the turn is happening; eg. menuing, selecting target, attack happening, damage being dealt, dialogue being printed, etc///

# Called when the node enters the scene tree for the first time.
func _ready():
	in_battle = false #not in a battle when the game loads
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_battle():
	#remember character's position on the overworld
	#switch to battle scene
	initialize_data()
	load_troop()
	in_battle = true
	return
	
func end_battle():
	initialize_data()
	in_battle = false
	#switch to overworld scene
	#spawn player at remembered position
	return

func initialize_data():
	turn = 0
	phase = 0
	return
	
func load_troop():
	#load the enemies into the battle
	return
