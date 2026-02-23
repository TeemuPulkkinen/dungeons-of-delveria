extends HBoxContainer

var _player: Entity
var _update_queued := false

@onready var level_label: Label = $LevelLabel
@onready var attack_label: Label = $AttackLabel
@onready var defense_label: Label = $DefenseLabel

func setup(player: Entity) -> void:
	_player = player
	if not _player.is_inside_tree():
		await _player.ready

	_player.level_component.leveled_up.connect(_request_update)
	if _player.equipment_component:
		_player.equipment_component.equipment_changed.connect(_request_update)

	update_labels()

func _request_update() -> void:
	if _update_queued:
		return
	_update_queued = true
	call_deferred("_do_update")

func _do_update() -> void:
	_update_queued = false
	update_labels()

func update_labels() -> void:
	level_label.text = "LVL: %d" % _player.level_component.current_level
	attack_label.text = "ATK: %d" % _player.fighter_component.power
	defense_label.text = "DEF: %d" % _player.fighter_component.defense
