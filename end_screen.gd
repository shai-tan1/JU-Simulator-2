# end_screen.gd — Godot 4.x
# Attach to the CanvasLayer root of end_screen.tscn. Hidden until
# GameState.game_over fires (semester's 20 slots are up), then shows a
# verdict computed from final stats. "Play Again" resets GameState and
# reloads the scene.

extends CanvasLayer

@onready var title_label: Label = $Backdrop/Center/VBox/TitleLabel
@onready var body_label: Label = $Backdrop/Center/VBox/BodyLabel
@onready var play_again_button: Button = $Backdrop/Center/VBox/PlayAgainButton

func _ready() -> void:
	visible = false
	GameState.game_over.connect(_show_verdict)
	play_again_button.pressed.connect(_on_play_again)

func _show_verdict() -> void:
	var att: float = GameState.attendance
	var cgpa: float = GameState.cgpa
	var mood: float = GameState.mood

	var verdict: String
	if att < 75.0:
		verdict = "Debarred!"
	elif cgpa >= 8.2 and mood >= 55.0:
		verdict = "Dean's List Semester"
	elif cgpa >= 8.2:
		verdict = "Topper, but Burnt Out"
	elif mood >= 70.0:
		verdict = "Vibes Department Topper"
	else:
		verdict = "Survived the Semester"

	title_label.text = verdict
	body_label.text = "Attendance %.0f%%\nCGPA %.2f\nMood %.0f%%\n₹%d" % [
		att, cgpa, mood, int(GameState.money)
	]
	visible = true

func _on_play_again() -> void:
	visible = false
	GameState.reset()
	get_tree().reload_current_scene()
