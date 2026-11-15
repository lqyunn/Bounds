extends CharacterBody3D

@export var speed: float = 4.5
@export var mouse_sensitivity: float = 0.003

@onready var head: Node3D = $Head
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

var gravity: float = ProjectSettings.get_setting('physics/3d/default_gravity')


func _ready() -> void:
	print('Player script is running')
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed('toggle_flashlight'):
		flashlight.visible = not flashlight.visible

	if event.is_action_pressed('ui_cancel'):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()


func teleport_to(marker: Node3D) -> void:
	global_position = marker.global_position
	rotation = Vector3(0, marker.global_rotation.y, 0)
	head.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
