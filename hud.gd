# hud.gd — Godot 4.x
# Attach to the CanvasLayer root of hud.tscn. Mirrors GameState's stats
# on screen; refreshes whenever GameState emits `changed`, plus once at start.

extends CanvasLayer

@onready var attendance_bar: ProgressBar = $Panel/VBox/AttendanceRow/AttendanceBar
@onready var energy_bar: ProgressBar = $Panel/VBox/EnergyRow/EnergyBar
@onready var mood_bar: ProgressBar = $Panel/VBox/MoodRow/MoodBar
@onready var cgpa_label: Label = $Panel/VBox/CGPALabel
@onready var money_label: Label = $Panel/VBox/MoneyLabel
@onready var slot_label: Label = $Panel/VBox/SlotLabel
@onready var toast: PanelContainer = $Toast
@onready var toast_label: Label = $Toast/ToastLabel

var _fill_normal: StyleBoxFlat
var _fill_low: StyleBoxFlat
var _toast_token: int = 0

func _ready() -> void:
	# duplicate the shared fill stylebox so recoloring attendance never
	# bleeds into the energy/mood bars, which reuse the same sub_resource
	_fill_normal = attendance_bar.get_theme_stylebox("fill").duplicate()
	_fill_low = _fill_normal.duplicate()
	_fill_low.bg_color = Color(0.82, 0.22, 0.22, 1.0)
	GameState.changed.connect(_refresh)
	GameState.message.connect(show_toast)
	_refresh()

func show_toast(text: String) -> void:
	toast_label.text = text
	toast.visible = true
	_toast_token += 1
	var token: int = _toast_token
	await get_tree().create_timer(3.0).timeout
	# a newer toast may have already replaced this one — only the latest timer hides it
	if token == _toast_token:
		toast.visible = false

func _refresh() -> void:
	attendance_bar.value = GameState.attendance
	energy_bar.value = GameState.energy
	mood_bar.value = GameState.mood
	attendance_bar.add_theme_stylebox_override(
		"fill", _fill_low if GameState.attendance < 75.0 else _fill_normal
	)
	cgpa_label.text = "CGPA %.2f" % GameState.cgpa
	money_label.text = "₹%d" % int(GameState.money)
	var day: int = GameState.slot / 4 + 1
	slot_label.text = "Day %d / 5" % day
