# game_state.gd — Godot 4.x
# Autoload singleton "GameState". Tracks player stats across the campus sim.
# Call GameState.apply({"energy": -10, ...}) after any action; it clamps
# stats to their valid ranges, advances the time slot, and emits `changed`.

extends Node

signal changed

var attendance: float = 70.0
var energy: float = 80.0
var mood: float = 60.0
var cgpa: float = 7.5
var money: float = 300.0
var slot: int = 0

func apply(fx: Dictionary) -> void:
	for key in fx.keys():
		match key:
			"attendance":
				attendance += fx[key]
			"energy":
				energy += fx[key]
			"mood":
				mood += fx[key]
			"cgpa":
				cgpa += fx[key]
			"money":
				money += fx[key]
	attendance = clamp(attendance, 0.0, 100.0)
	energy = clamp(energy, 0.0, 100.0)
	mood = clamp(mood, 0.0, 100.0)
	cgpa = clamp(cgpa, 0.0, 10.0)
	money = max(money, 0.0)
	slot += 1
	changed.emit()
