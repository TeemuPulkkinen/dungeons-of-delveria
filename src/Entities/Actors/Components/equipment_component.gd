class_name EquipmentComponent
extends Component

signal equipment_changed

var slots := {}
var _is_changing := false

func get_defense_bonus() -> int:
	var bonus := 0
	for item in slots.values():
		if item != null and item.equippable_component:
			bonus += item.equippable_component.defense_bonus
	return bonus

func get_power_bonus() -> int:
	var bonus := 0
	for item in slots.values():
		if item != null and item.equippable_component:
			bonus += item.equippable_component.power_bonus
	return bonus

func get_equipped_weapon() -> Entity:
	return slots.get(EquippableComponent.EquipmentType.WEAPON)

func is_item_equipped(item: Entity) -> bool:
	return item in slots.values()

func _unequip_from_slot(slot: EquippableComponent.EquipmentType, add_message: bool) -> void:
	var current_item: Entity = slots.get(slot)
	if current_item == null:
		return

	# Päivitä tila ensin, sitten UI
	slots.erase(slot)

	if add_message:
		# Deferoi viesti, ettei UI/scene-tree muutu kesken input-eventin
		call_deferred("_send_remove_message", current_item)

	# Deferoi signaali samaan syyhyn
	call_deferred("emit_signal", "equipment_changed")

func _send_remove_message(item: Entity) -> void:
	if item == null or not is_instance_valid(item):
		return
	MessageLog.send_message("You remove the %s." % item.get_entity_name(), Color.WHITE)

func _equip_to_slot(slot: EquippableComponent.EquipmentType, item: Entity, add_message: bool) -> void:
	var current_item: Entity = slots.get(slot)
	if current_item != null:
		_unequip_from_slot(slot, add_message)

	slots[slot] = item

	if add_message:
		call_deferred("_send_equip_message", item)

	call_deferred("emit_signal", "equipment_changed")

func _send_equip_message(item: Entity) -> void:
	if item == null or not is_instance_valid(item):
		return
	MessageLog.send_message("You equip the %s." % item.get_entity_name(), Color.WHITE)

func toggle_equip(equippable_item: Entity, add_message: bool = true) -> void:
	if _is_changing:
		return
	_is_changing = true

	if equippable_item == null or not is_instance_valid(equippable_item):
		_is_changing = false
		return
	if equippable_item.equippable_component == null:
		_is_changing = false
		return

	var slot: EquippableComponent.EquipmentType = equippable_item.equippable_component.equipment_type

	if slots.get(slot) == equippable_item:
		_unequip_from_slot(slot, add_message)
	else:
		_equip_to_slot(slot, equippable_item, add_message)

	_is_changing = false


func get_save_data() -> Dictionary:
	var equipped_indices := []
	var inventory: InventoryComponent = entity.inventory_component
	for i in inventory.items.size():
		var item: Entity = inventory.items[i]
		if is_item_equipped(item):
			equipped_indices.append(i)
	return {"equipped_indices": equipped_indices}

func restore(save_data: Dictionary) -> void:
	var equipped_indices: Array = save_data.get("equipped_indices", [])
	var inventory: InventoryComponent = entity.inventory_component
	for i in inventory.items.size():
		if equipped_indices.any(func(index): return int(index) == i):
			var item: Entity = inventory.items[i]
			toggle_equip(item, false)
