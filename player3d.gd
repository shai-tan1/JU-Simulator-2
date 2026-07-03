# player3d.gd — Godot 4.x
# Attach to a CharacterBody3D with children:
#   - CollisionShape3D (CapsuleShape3D, radius 0.5, height 1.8)
#   - MeshInstance3D  (CapsuleMesh, same size — the placeholder body)
#   - Node3D named "CamPivot" containing a Camera3D
# The camera pivot gives the tilted three-quarter view; adjust TILT_DEG
# and CAM_DIST live in the editor to taste.

extends CharacterBody3D

const SPEED := 8.0          # m/s — campus-stroll x2
const TILT_DEG := -55.0     # camera tilt: -90 = straight down, -45 = shallow
const CAM_DIST := 60.0      # meters from player

@onready var pivot: Node3D = $CamPivot
@onready var cam: Camera3D = $CamPivot/Camera3D

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
