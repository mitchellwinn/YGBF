extends Stats

class_name TrecherousStrutter

func initialize_stats():

	exp = 200

	character_name = "Trecherous Strutter"
	enemy = true
	sprite = ImageTexture.new().create_from_image(Image.new().load_from_file("res://images/portraits/tt1.png"))
	ego_subdue_threshold = .5
	talents.append(Model.new())
	for talent in talents:
		add_child(talent)
	active_talent = talents[0]

	base_agility = 20
	base_strength = 5
	base_charisma = 15
	base_constitution = 25
	base_perspective = 35
	base_resilience = 5
	base_sturdiness = 0

	growth_agility = 0.5
	growth_strength = 0.5
	growth_charisma = 0.5
	growth_constitution = 0.5
	growth_perspective = 0.5
	growth_resilience = 0.5
	growth_sturdiness = 0.5