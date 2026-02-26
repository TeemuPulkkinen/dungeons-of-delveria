class_name ShootAction
extends Action

var target_position: Vector2i

func _init(entity: Entity, target_position: Vector2i) -> void:
	super._init(entity)
	self.target_position = target_position
	
func perform() -> bool:
	var map_data: MapData = get_map_data()
	if map_data == null:
		return false

	# Is there an equipped bow or other ranged weapon?
	var weapon: Entity = entity.equipment_component.get_equipped_weapon() if entity.equipment_component else null
	if weapon == null or weapon.equippable_component == null or not weapon.equippable_component.is_ranged:
		if entity == map_data.player:
			MessageLog.send_message("You have no ranged weapon equipped.", GameColors.IMPOSSIBLE)
		return false
	
	var range: int = weapon.equippable_component.range
	if entity.grid_position.distance_to(target_position) > range:
		if entity == map_data.player:
			MessageLog.send_message("Out of range.", GameColors.IMPOSSIBLE)
		return false

	if target_position == entity.grid_position:
		if entity == map_data.player:
			MessageLog.send_message("You can't shoot yourself.", GameColors.IMPOSSIBLE)
		return false

	var target_tile: Tile = map_data.get_tile(target_position)
	if target_tile == null or not target_tile.is_in_view:
		if entity == map_data.player:
			MessageLog.send_message("You can't see that.", GameColors.IMPOSSIBLE)
		return false

	# Line of sight: first blocking wall stops the shot, first actor hit takes damage
	var hit_actor: Entity = null
	var blocked: bool = false

	for p: Vector2i in _bresenham_line(entity.grid_position, target_position):
		if p == entity.grid_position:
			continue

		var tile: Tile = map_data.get_tile(p)
		if tile == null:
			blocked = true
			break

		# If the tile is not transparent, the projectile won't pass
		if not tile.is_transparent():
			blocked = true
			break

		var actor: Entity = map_data.get_actor_at_location(p)
		if actor != null and actor.is_alive():
			hit_actor = actor
			break

	if blocked:
		if entity == map_data.player:
			MessageLog.send_message("Your shot is blocked.", GameColors.IMPOSSIBLE)
		return false

	# Fallback: if you targeted an actor tile directly, ensure we can hit it
	if hit_actor == null:
		hit_actor = map_data.get_actor_at_location(target_position)

	if hit_actor == null:
		if entity == map_data.player:
			MessageLog.send_message("Nothing to shoot.", GameColors.IMPOSSIBLE)
		return false

	if hit_actor.fighter_component == null:
		return false

	# Damage calculation
	var damage: int = entity.fighter_component.power - hit_actor.fighter_component.defense

	var attack_color: Color = GameColors.PLAYER_ATTACK if entity == map_data.player else GameColors.ENEMY_ATTACK
	var desc: String = "%s shoots %s" % [entity.get_entity_name(), hit_actor.get_entity_name()]

	if damage > 0:
		desc += " for %d hit points." % damage
		MessageLog.send_message(desc, attack_color)
		hit_actor.fighter_component.hp -= damage
	else:
		desc += " but does no damage."
		MessageLog.send_message(desc, attack_color)

	return true


func _bresenham_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0: int = a.x
	var y0: int = a.y
	var x1: int = b.x
	var y1: int = b.y

	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return points
