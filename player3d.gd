# player3d.gd — Godowwwwwwwwwwwwwwwwwwwwt 4.x
# Attach to a CharacterBody3D with children:
#   - CollisionShape3D (CapsuleShape3D, radius 0.5, height 1.8)
#   - MeshInstance3D  (CapsuleMesh, same size — the placeholder body)
#   - Node3D named "CamPivot" containing a Camera3D
# The camera pivot gives the tilted three-quarter view; adjust TILT_DEG
# and CAM_DIST live in the editor to taste.

extends CharacterBody3D

const SPEED := 8.0          # m/s — campus-stroll x2
const TILT_DEG := -20.0     # camera tilt: -90 = straight down, -45 = shallow
const CAM_DIST := 18.0      # meters from player

@onready var pivot: Node3D = $CamPivot
@onready var cam: Camera3D = $CamPivot/Camera3D

var current_building: String = ""

func _ready() -> void:
	pivot.rotation_degrees.x = TILT_DEG
	cam.position = Vector3(0, 0, CAM_DIST)
	cam.current = true

func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = input.x * SPEED
	velocity.z = input.y * SPEED
	velocity.y = -9.8  # keep grounded
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_interact()

# called by the building Area3D (see world3d.gd) when the player enters/exits its trigger
func set_current_building(building_name: String) -> void:
	current_building = building_name

func clear_current_building(building_name: String) -> void:
	if current_building == building_name:
		current_building = ""

func _interact() -> void:
	if current_building == "":
		return
	if Actions.TABLE.has(current_building):
		var action: Dictionary = Actions.TABLE[current_building]
		GameState.apply(action["fx"])
		print("%s → att=%.1f energy=%.1f mood=%.1f cgpa=%.2f money=₹%.0f" % [
			action["msg"], GameState.attendance, GameState.energy,
			GameState.mood, GameState.cgpa, GameState.money,
		])
	else:
		print("Nothing to do at %s yet." % current_building)
