extends Stats

class_name Robby

func initialize_stats():
	character_name = "Robby"

	exp = 150
	level_cap = 20

	sprite = ImageTexture.new().create_from_image(Image.new().load_from_file("res://images/portraits/robby.png"))
	talents.append(Model.new())
	talents.append(Action.new())
	for talent in talents:
		talent.owner = self
		talent.exp = 150
		add_child(talent)
	active_talent = talents[0]

	base_agility = 25
	base_strength = 6
	base_charisma = 10
	base_constitution = 25
	base_perspective = 40
	base_resilience = 30
	base_sturdiness = 15

	growth_agility = 0.6
	growth_strength = 0.75
	growth_charisma = 0.75
	growth_constitution = 0.6
	growth_perspective = 0.65
	growth_resilience = 0.8
	growth_sturdiness = 0.5
