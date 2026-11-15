extends Area3D

signal caught_player

@export var speed: float = 3.0

var chasing: bool = false
var player: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate()


func activate(at: Vector3) -> void:
	player = get_tree().get_first_node_in_group('player')
	global_position = at
	chasing = true
	visible = true
	set_deferred('monitoring', true)


func deactivate() -> void:
	chasing = false
	visible = false
	set_deferred('monitoring', false)


func _physics_process(delta: float) -> void:
	if not chasing or player == null:
		return
	var target := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if global_position.distance_to(target) > 0.1:
		look_at(target)
		global_position = global_position.move_toward(target, speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if chasing and body.is_in_group('player'):
		caught_player.emit()
