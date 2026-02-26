class_name EquippableComponentDefinition
extends ItemComponentDefinition

@export var equipment_type: EquippableComponent.EquipmentType
#Melee weapons and armor
@export var power_bonus: int = 0
@export var defense_bonus: int = 0

#Ranged weapons
@export var is_ranged: bool = false
@export var range: int = 6
