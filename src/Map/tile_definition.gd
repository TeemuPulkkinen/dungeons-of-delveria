class_name TileDefinition
extends Resource

@export_category("Visuals")
@export var texture: AtlasTexture

# Own color of the tile material
@export_color_no_alpha var base_color: Color = Color.WHITE

# FOV lighting, not a material color
@export_color_no_alpha var lit_multiplier: Color = Color(1, 1, 1) #visible
@export_color_no_alpha var explored_multiplier: Color = Color(0.35, 0.35, 0.35) #was explored

# Backward compatible exports
@export var use_legacy_lit_dark_colors: bool = true
@export_color_no_alpha var color_lit: Color = Color.WHITE
@export_color_no_alpha var color_dark: Color = Color.WHITE

@export_category("Mechanics")
@export var is_walkable: bool = true
@export var is_transparent: bool = true
