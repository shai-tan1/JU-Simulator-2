# actions.gd — Godot 4.x
# Autoload singleton "Actions". Maps a building name (as it appears in
# data/buildings.json / data/campus3d.json) to the interaction available there.

extends Node

const TABLE := {
	"Aurobindo Bhavan": {
		"label": "Collect Scholarship",
		"fx": {"money": 150, "mood": -8, "energy": -6},
		"msg": "Two hours in the Aurobindo Bhavan queue, a dozen signatures, and finally the scholarship cashier counts out your notes.",
	},
	"Jadavpur University Central Library": {
		"label": "Study",
		"fx": {"cgpa": 0.2, "energy": -14, "mood": -4},
		"msg": "You disappear into the CL stacks and grind through backlog notes until the peon starts switching off the lights.",
	},
	"Aahar Canteen": {
		"label": "Eat",
		"fx": {"energy": 16, "mood": 8, "money": -30},
		"msg": "Egg roll, extra chili, and cutting chai at Aahar — the world feels survivable again.",
	},
	"Mechanical Engineering Building": {
		"label": "Workshop",
		"fx": {"cgpa": 0.1, "energy": -12},
		"msg": "You lose an afternoon to the lathe and a stubborn workshop drawing, but the submission goes in on time.",
	},
	"Chemical Engineering Department": {
		"label": "Lab",
		"fx": {"cgpa": 0.12, "energy": -12, "mood": -3},
		"msg": "The titration takes three tries and the TA sighs audibly, but the readings finally check out.",
	},
}
