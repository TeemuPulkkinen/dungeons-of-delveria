extends BaseInputHandler

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

var _held_dir: String = ""
var _next_repeat_ms: int = 0
var _repeat_started: bool = false

const HOLD_INITIAL_DELAY_MS := 180
const HOLD_REPEAT_DELAY_MS := 80

const inventory_menu_scene = preload("res://src/GUI/InventoryMenu/inventory_menu.tscn")

@export var reticle: Reticle

func get_action(player: Entity) -> Action:
	
	for direction in directions:
		if Input.is_action_just_pressed(direction):
			_held_dir = direction
			_repeat_started = false
			var now := Time.get_ticks_msec()
			_next_repeat_ms = now + HOLD_INITIAL_DELAY_MS
			
			var offset: Vector2i = directions[direction]
			return BumpAction.new(player, offset.x, offset.y)
			
		if _held_dir != "" and Input.is_action_pressed(_held_dir):
			var now := Time.get_ticks_msec()
			
			if now >= _next_repeat_ms:
				_repeat_started = true
				_next_repeat_ms = now + HOLD_REPEAT_DELAY_MS
				var offset: Vector2i = directions[_held_dir]
				return BumpAction.new(player, offset.x, offset.y)
		else:
			_clear_hold()
	
	var action: Action = null
	
	if Input.is_action_just_pressed("wait"):
		action = WaitAction.new(player)
	
	if Input.is_action_just_pressed("view_history"):
		get_parent().transition_to(InputHandler.InputHandlers.HISTORY_VIEWER)
	
	if Input.is_action_just_pressed("pickup"):
		action = PickupAction.new(player)
	
	if Input.is_action_just_pressed("drop"):
		_clear_hold()
		var selected_item: Entity = await get_item("Select an item to drop", player.inventory_component)
		action = DropItemAction.new(player, selected_item)
	
	if Input.is_action_just_pressed("activate"):
		_clear_hold()
		action = await activate_item(player)
	
	if Input.is_action_just_pressed("quit") or Input.is_action_just_pressed("ui_back"):
		action = EscapeAction.new(player)
	
	if Input.is_action_just_pressed("look"):
		_clear_hold()
		await get_grid_position(player, 0)
	
	if Input.is_action_just_pressed("descend"):
		action = TakeStairsAction.new(player)
	
	if Input.is_action_just_pressed("shoot"):
		_clear_hold()

		var weapon: Entity = player.equipment_component.get_equipped_weapon() if player.equipment_component else null
		var is_ranged: bool = (
			weapon != null
			and weapon.equippable_component != null
			and weapon.equippable_component.is_ranged
		)

		if not is_ranged:
			MessageLog.send_message("You have no ranged weapon equipped.", GameColors.IMPOSSIBLE)
		else:
			var weapon_range: int = weapon.equippable_component.range
			var target_pos: Vector2i = await get_grid_position(player, 0, weapon_range)
			
			if target_pos == Vector2i(-1, -1):
				pass #canceled
			elif target_pos == player.grid_position:
				MessageLog.send_message("You can't shoot yourself.", GameColors.IMPOSSIBLE)
			else:
				action = ShootAction.new(player, target_pos)
				
	return action

func get_item(window_title: String, inventory: InventoryComponent, evaluate_for_next_step: bool = false) -> Entity:
	if inventory.items.is_empty():
		await get_tree().physics_frame
		MessageLog.send_message("No items in inventory.", GameColors.IMPOSSIBLE)
		return null

	var inventory_menu: InventoryMenu = inventory_menu_scene.instantiate()
	add_child(inventory_menu)
	inventory_menu.build(window_title, inventory)

	get_parent().transition_to(InputHandler.InputHandlers.DUMMY)

	var selected_item: Entity = await inventory_menu.item_selected

	var has_item: bool = selected_item != null
	var needs_targeting: bool = (
		has_item
		and selected_item.consumable_component != null
		and selected_item.consumable_component.get_targeting_radius() != -1
	)


	if not (evaluate_for_next_step and needs_targeting):
		await get_tree().physics_frame
		get_parent().call_deferred("transition_to", InputHandler.InputHandlers.MAIN_GAME)

	return selected_item

func get_grid_position(player: Entity, radius: int, max_range : int = -1) -> Vector2i:
	get_parent().transition_to(InputHandler.InputHandlers.DUMMY)
	var selected_position: Vector2i = await reticle.select_position(player, radius, max_range)
	await get_tree().physics_frame
	get_parent().call_deferred("transition_to", InputHandler.InputHandlers.MAIN_GAME)
	return selected_position

func activate_item(player: Entity) -> Action:
	var selected_item: Entity = await get_item("Select an item to use", player.inventory_component, true)
	if selected_item == null:
		get_parent().call_deferred("transition_to", InputHandler.InputHandlers.MAIN_GAME)
		return null

	var target_radius: int = -1
	if selected_item.consumable_component != null:
		target_radius = selected_item.consumable_component.get_targeting_radius()

	if target_radius == -1:
		return ItemAction.new(player, selected_item)

	var target_position: Vector2i = await reticle.select_position(player, target_radius)
	await get_tree().physics_frame
	get_parent().call_deferred("transition_to", InputHandler.InputHandlers.MAIN_GAME)

	if target_position == Vector2i(-1, -1):
		return null

	return ItemAction.new(player, selected_item, target_position)
func enter() -> void:
	_held_dir = ""
	_repeat_started = false
	_next_repeat_ms = 0

func exit() -> void:
	_held_dir = ""
	_repeat_started = false
	_next_repeat_ms = 0

# Clears the key being held where needed
func _clear_hold() -> void:
	_held_dir = ""
	_repeat_started = false
	_next_repeat_ms = 0
