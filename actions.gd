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
	"AC Canteen (Amenity Centre Canteen)": {
		"label": "Snack",
		"fx": {"energy": 10, "mood": 4, "money": -15},
		"msg": "Muri-makha and a five-rupee cutting chai at the AC Canteen — not fancy, but it does the job between classes.",
	},
	"Computer Science": {
		"label": "Debug",
		"fx": {"cgpa": 0.15, "energy": -10, "mood": -2},
		"msg": "You corner a segfault in the CS department lab at 2am — turns out it was a missing semicolon all along.",
	},
	"Civil Engineering": {
		"label": "Site Model",
		"fx": {"cgpa": 0.1, "energy": -10},
		"msg": "You spend the afternoon hunched over a surveying model in the Civil Engineering drafting hall, T-square in hand.",
	},
	"Department of English": {
		"label": "Attend Lecture",
		"fx": {"attendance": 6, "mood": 3, "energy": -5},
		"msg": "A spirited seminar on postcolonial literature in the Department of English leaves you oddly recharged.",
	},
	"Dr. Triguna Sen Auditorium": {
		"label": "Catch the Fest",
		"fx": {"mood": 12, "energy": -8, "money": -20},
		"msg": "You squeeze into the Triguna Sen Auditorium for the annual fest headliner — worth every rupee of the ticket and every hour of lost sleep.",
	},
	"Worldview Book Shop": {
		"label": "Browse Books",
		"fx": {"cgpa": 0.05, "money": -40, "mood": 5},
		"msg": "You pick up a dog-eared secondhand reference text from Worldview, JU's favourite pavement-adjacent bookshop.",
	},
}
