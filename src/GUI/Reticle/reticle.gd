class_name Reticle
extends Node2D

var _accept_armed: bool = false

signal position_selected(grid_position)

const directions = {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
	"move_up_left": Vector2i.UP + Vector2i.LEFT,
	"move_up_right": Vector2i.UP + Vector2i.RIGHT,
	"move_down_left": Vector2i.DOWN + Vector2i.LEFT,
	"move_down_right": Vector2i.DOWN + Vector2i.RIGHT,
}

var grid_position: Vector2i:
	set(value):
		grid_position = value
		position = Grid.grid_to_world(grid_position)

var map_data: MapData

@onready var camera: Camera2D = $Camera2D
@onready var border: Line2D = $Line2D

var origin: Vector2i
var max_range: int = -1

var _held_dir: String = ""
var _next_repeat_ms: int = 0
var _repeat_started: bool = false

const HOLD_INITIAL_DELAY_MS: int = 180
const HOLD_REPEAT_DELAY_MS: int = 80

func _ready() -> void:
	hide()
	set_physics_process(false)

func select_position(player: Entity, radius: int, p_max_range: int = -1) -> Vector2i:
	map_data = player.map_data
	origin = player.grid_position
	max_range = p_max_range
	grid_position = player.grid_position

	var player_camera: Camera2D = get_viewport().get_camera_2d()
	camera.make_current()
	_setup_border(radius)
	show()

	_accept_armed = false
	Input.flush_buffered_events()
	set_physics_process(true)
	await get_tree().physics_frame
	_accept_armed = true
	set_physics_process(true)
	await get_tree().physics_frame

	var selected_position: Vector2i = await position_selected

	set_physics_process(false)
	player_camera.make_current()
	hide()

	return selected_position

func _physics_process(delta: float) -> void:
	var offset: Vector2i = Vector2i.ZERO


	for direction: String in directions.keys():
		if Input.is_action_just_pressed(direction):
			_held_dir = direction
			_repeat_started = false
			var now: int = Time.get_ticks_msec()
			_next_repeat_ms = now + HOLD_INITIAL_DELAY_MS
			offset = directions[direction]
			break


	if offset == Vector2i.ZERO and _held_dir != "" and Input.is_action_pressed(_held_dir):
		var now2: int = Time.get_ticks_msec()
		if now2 >= _next_repeat_ms:
			_repeat_started = true
			_next_repeat_ms = now2 + HOLD_REPEAT_DELAY_MS
			offset = directions[_held_dir]
	else:
		_held_dir = ""
		_repeat_started = false
		_next_repeat_ms = 0

	if offset != Vector2i.ZERO:
		grid_position += offset

		if max_range >= 0:
			var dx: int = abs(grid_position.x - origin.x)
			var dy: int = abs(grid_position.y - origin.y)
			var dist: int = max(dx, dy)
			if dist > max_range:
				grid_position -= offset

	if _accept_armed and Input.is_action_just_pressed("ui_accept"):
		position_selected.emit(grid_position)
	if _accept_armed and Input.is_action_just_pressed("ui_back"):
		position_selected.emit(Vector2i(-1, -1))

func _setup_border(radius: int) -> void:
	if radius <= 0:
		border.hide()
	else:
		border.points = [
			Vector2i(-radius, -radius) * Grid.tile_size,
			Vector2i(-radius, radius + 1) * Grid.tile_size,
			Vector2i(radius + 1, radius +1) * Grid.tile_size,
			Vector2i(radius + 1, -radius) * Grid.tile_size,
			Vector2i(-radius, -radius) * Grid.tile_size
		]
		border.show()
		
