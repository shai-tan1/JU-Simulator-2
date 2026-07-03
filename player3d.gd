# player3d.gd — Godowwwwwwwwwwwwwwwwwwwwt 4.x
# Attach to a CharacterBody3D with children:
#   - CollisionShape3D (CapsuleShape3D, radius 0.5, height 1.8)
#   - MeshInstance3D  (CapsuleMesh, same size — the placeholder body) -> HIDE THIS
#   - Node3D named "CamPivot" containing a Camera3D
#   - Node3D named "student" (The FBX imported model)

extends CharacterBody3D

const SPEED := 8.0          # m/s — campus-stroll x2
const TILT_DEG := -20.0     # camera tilt: -90 = straight down, -45 = shallow
const CAM_DIST := 18.0      # meters from player

@onready var pivot: Node3D = $CamPivot
@onready var cam: Camera3D = $CamPivot/Camera3D
@onready var character_mesh: Node3D = $student
@onready var anim_player: AnimationPlayer = $student/AnimationPlayer

var current_building: String = ""

func _ready() -> void:
	pivot.rotation_degrees.x = TILT_DEG
	cam.position = Vector3(0, 0, CAM_DIST)
	cam.current = true
	
	# Force the size and ground position on load
	character_mesh.scale = Vector3(2.2, 2.2, 2.2) # Increases size by 2.2x
	character_mesh.position.y = -0.9 # Pushes the mesh down to the bottom of your capsule

func _physics_process(_delta: float) -> void:
	if not GameState.game_active:
		velocity = Vector3.ZERO
		anim_player.stop()
		move_and_slide()
		return
		
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = input.x * SPEED
	velocity.z = input.y * SPEED
	velocity.y = -9.8  # keep grounded
	
	if input.length() > 0:
		# Standard orientation math for Mixamo FBX imports in Godot.
		# If the character walks exactly backwards, change it to: atan2(velocity.x, velocity.z) + PI
		var target_angle = atan2(velocity.x, velocity.z)
		
		# Smoothly rotate the character to face the target angle
		character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, target_angle, 15.0 * _delta)
		
		anim_player.play("mixamo_com")
	else:
		anim_player.stop()
		
	move_and_slide()
func _unhandled_input(event: InputEvent) -> void:
	if not GameState.game_active:
		return
	if event.is_action_pressed("interact"):
		_interact()

# called by the building Area3D (see world3d.gd) when the player enters/exits its trigger
func set_current_building(building_name: String) -> void:
	print("Entered zone: %s" % building_name)
	current_building = building_name

func clear_current_building(building_name: String) -> void:
	if current_building == building_name:
		print("Left zone: %s" % building_name)
		current_building = ""

func _interact() -> void:
	if current_building == "":
		return
	if Actions.TABLE.has(current_building):
		var action: Dictionary = Actions.TABLE[current_building]
		GameState.apply(action["fx"])
		GameState.message.emit(action["msg"])
		print("%s → att=%.1f energy=%.1f mood=%.1f cgpa=%.2f money=₹%.0f" % [
			action["msg"], GameState.attendance, GameState.energy,
			GameState.mood, GameState.cgpa, GameState.money,
		])
	else:
		var msg: String = "Nothing to do at %s yet." % current_building
		GameState.message.emit(msg)
		print(msg)
