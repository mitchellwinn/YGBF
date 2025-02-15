extends Stats

class_name Emilio

func initialize_stats():
	character_name = "Emilio"
	sprite = ImageTexture.new().create_from_image(Image.new().load_from_file("res://images/portraits/emilio.png"))
	talents.append(Diva.new())
	for talent in talents:
		add_child(talent)
	active_talent = talents[0]
	
	base_agility = 35
	base_strength = 9
	base_charisma = 15
	base_constitution = 30
	base_perspective = 50
	base_resilience = 35
	base_sturdiness = 20

	growth_agility = 0.55
	growth_strength = 0.7
	growth_charisma = 0.7
	growth_constitution = 0.4
	growth_perspective = 0.55
	growth_resilience = 0.7
	growth_sturdiness = 0.45