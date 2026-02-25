class_name Tile
extends Sprite2D

const tile_types = {
	"floor": preload("res://assets/definitions/tiles/tile_definition_floor.tres"),
	"wall": preload("res://assets/definitions/tiles/tile_definition_wall.tres"),
	"down_stairs": preload("res://assets/definitions/tiles/tile_definition_down_stairs.tres")
}

var key: String
var _definition: TileDefinition

var is_explored: bool = false:
	set(value):
		is_explored = value
		if is_explored and not visible:
			visible = true
		_apply_fov_shading()

var is_in_view: bool = false:
	set(value):
		is_in_view = value
		modulate = _definition.color_lit if is_in_view else _definition.color_dark
		if is_in_view and not is_explored:
			is_explored = true
		_apply_fov_shading()

func _init(grid_position: Vector2i, key: String) -> void:
	visible = false
	centered = false
	position = Grid.grid_to_world(grid_position)
	set_tile_type(key)

func set_tile_type(key: String) -> void:
	self.key = key
	_definition = tile_types[key]
	texture = _definition.texture
	_apply_fov_shading()

func _apply_fov_shading() -> void:
	if not is_explored and not is_in_view:
		visible = false
		return
	
	visible = true
	
	#Legacy code backup
	if _definition.use_legacy_lit_dark_colors:
		modulate = _definition.color_lit if is_in_view else _definition.color_dark
		return
		
	# Code for new base color and shading multiplier
	var base := _definition.base_color
	if is_in_view:
		modulate = base * _definition.lit_multiplier
	else:
		modulate = base * _definition.explored_multiplier

func is_walkable() -> bool:
	return _definition.is_walkable

func is_transparent() -> bool:
	return _definition.is_transparent

func get_save_data() -> Dictionary:
	return {
		"key": key,
		"is_explored": is_explored
	}

func restore(save_data: Dictionary) -> void:
	set_tile_type(save_data["key"])
	is_explored = save_data["is_explored"]
	_apply_fov_shading()
