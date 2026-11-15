extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var monster_spawn: Marker3D = $MonsterSpawn
@onready var monster: Area3D = $Monster
@onready var door_a: CSGBox3D = $DoorA
@onready var door_b: CSGBox3D = $DoorB
@onready var exit_door: CSGBox3D = $ExitDoor
@onready var key_item: Area3D = $Key
@onready var key_item2: Area3D = $Key2
@onready var key_item3: Area3D = $Key3
@onready var chase_trigger: Area3D = $ChaseTrigger
@onready var exit_zone: Area3D = $ExitZone
@onready var sting: AudioStreamPlayer = $Sting
@onready var flash_rect: ColorRect = $UI/FlashRect
@onready var loop_label: Label = $UI/LoopLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var fake_wall: CSGBox3D = $FakeWall
@onready var start_label: Label = $UI/StartLabel
@onready var start_label2: Label = $UI/StartLabel2

var has_key: bool = false
var has_key2: bool = false
var has_key3: bool = false
var chase_started: bool = false
var bouncing: bool = false
var escaped: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.bounce_count = 0
	GameState.bounced.connect(_on_bounced)
	monster.caught_player.connect(_on_monster_caught_player)
	chase_trigger.body_entered.connect(_on_chase_trigger_entered)
	key_item.body_entered.connect(_on_key_picked_up)
	key_item2.body_entered.connect(_on_key2_picked_up)
	key_item3.body_entered.connect(_on_key3_picked_up)
	exit_zone.body_entered.connect(_on_exit_reached)
	message_label.visible = false
	start_label.visible = true
	start_label2.visible = false
	_apply_loop_state()


func _apply_loop_state() -> void:
	var n: int = GameState.bounce_count
	loop_label.text = 'Bounded: %d' % n

	if n==1:
		start_label.visible = false
		start_label2.visible = true
		
	
	if n==2:
		start_label2.visible = false
		chase_trigger.position = Vector3(0, 1.5, -11)
		_open(door_b)
	
	if n >= 2:
		_open(door_a)
		_open(fake_wall)
		

	var show_key: bool = has_key2 and not has_key
	key_item.visible = show_key
	key_item.set_deferred('monitoring', show_key)
	
	var show_key2: bool = has_key3 and not has_key2
	key_item2.visible = show_key2
	key_item2.set_deferred('monitoring', show_key2)
	
	var show_key3: bool = n >= 2 and not has_key3
	key_item3.visible = show_key3
	key_item3.set_deferred('monitoring', true)


func _open(door) -> void:
	if is_instance_valid(door):
		door.queue_free()


func _on_bounced(_new_count: int) -> void:
	_apply_loop_state()


func _on_chase_trigger_entered(body: Node3D) -> void:
	if body.is_in_group('player') and not chase_started and not escaped:
		chase_started = true
		monster.activate(monster_spawn.global_position)


func _on_monster_caught_player() -> void:
	if bouncing or escaped:
		return
	bouncing = true
	chase_started = false
	monster.deactivate()
	player.teleport_to(spawn_point)
	GameState.register_bounce()
	_screen_flash()
	if sting.stream:
		sting.play()
	await get_tree().create_timer(0.5).timeout
	bouncing = false


func _screen_flash() -> void:
	flash_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(flash_rect, 'modulate:a', 0.0, 0.7)


func _on_key_picked_up(body: Node3D) -> void:
	if not body.is_in_group('player'):
		return
	has_key = true
	key_item.visible = false
	key_item.set_deferred('monitoring', false)
	_open(exit_door)
	_show_message('The way out is open... RUN', 3.0)
	
func _on_key2_picked_up(body: Node3D) -> void:
	if not body.is_in_group('player'):
		return
	has_key2 = true
	key_item2.visible = false
	key_item2.set_deferred('monitoring', false)
	_show_message('2nd key acquired', 3.0)
	
func _on_key3_picked_up(body: Node3D) -> void:
	if not body.is_in_group('player'):
		return
	has_key3 = true
	key_item3.visible = false
	key_item3.set_deferred('monitoring', false)
	_show_message('1st key acquired', 3.0)


func _on_exit_reached(body: Node3D) -> void:
	if not body.is_in_group('player') or escaped:
		return
	escaped = true
	monster.deactivate()
	message_label.text = 'YOU ESCAPED BOUNDS\nBounds: %d' % GameState.bounce_count
	message_label.visible = true
	player.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _show_message(text: String, seconds: float) -> void:
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(seconds).timeout
	if not escaped:
		message_label.visible = false

func _process(_delta: float) -> void:
	var light: SpotLight3D = player.get_node('Head/Camera3D/Flashlight')
	if chase_started and not escaped:
		light.light_energy = randf_range(2.0, 6.0)
	else:
		light.light_energy = 6.0
