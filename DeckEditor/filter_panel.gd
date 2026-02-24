extends Panel

class_name FilterPanel

signal filters_changed
@onready var attribute_grid_container: GridContainer = $ScrollContainer/VBoxContainer/AttributeGridContainer
@onready var card_type_grid_container: GridContainer = $ScrollContainer/VBoxContainer/CardTypeGridContainer
@onready var monster_type_grid_container: GridContainer = $ScrollContainer/VBoxContainer/MonsterTypeGridContainer
@onready var monster_ability_grid_container: GridContainer = $ScrollContainer/VBoxContainer/MonsterAbilityGridContainer

@onready var level_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/LevelSpinBox
@onready var atk_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/AtkSpinBox
@onready var def_spin_box: SpinBox = $ScrollContainer/VBoxContainer/SpinBoxGridContainer/DefSpinBox

@onready var clear_filters_button: Button = $ClearFiltersButton
@onready var set_filters_button: Button = $SetFiltersButton

var current_filters := {
	"attribute": [CardHelper.Attribute,[]],
	"card_type": [CardHelper.CardType,[]],
	"monster_type": [CardHelper.MonsterType,[]],
	"monster_ability": [CardHelper.MonsterAbility,[]]
}

var current_numerical_filters := {
	"level": -1,
	"atk": -1,
	"def": -1
}
func _ready() -> void:
	fill_filter_panel()
	# Connect SpinBoxes
	level_spin_box.value_changed.connect(set_numerical_filter.bind("level"))
	atk_spin_box.value_changed.connect(set_numerical_filter.bind("atk"))
	def_spin_box.value_changed.connect(set_numerical_filter.bind("def"))
	set_filters_button.pressed.connect(func(): filters_changed.emit())
	clear_filters_button.pressed.connect(clear_filters)
	
func set_filter(is_pressed:bool, filter_name : String, value:int) -> void:
	if is_pressed:
		current_filters[filter_name][1].append(value)
	else:
		if current_filters[filter_name][1].has(value):
			current_filters[filter_name][1].erase(value)

func set_numerical_filter(value:int, filter_name:String) -> void:
	current_numerical_filters[filter_name] = value

func clear_filters() -> void:
	for checkbox : CheckBox in attribute_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in card_type_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in monster_type_grid_container.get_children():
		checkbox.button_pressed = false
	for checkbox : CheckBox in monster_ability_grid_container.get_children():
		checkbox.button_pressed = false
	level_spin_box.value = -1
	atk_spin_box.value = -1
	def_spin_box.value = -1
	filters_changed.emit()

func fill_filter_panel() -> void:
	# Add options for Attribute (DARK, LIGHT, etc.) - exclude SPELL, TRAP, NONE
	for a in CardHelper.Attribute.values():
		if a == CardHelper.Attribute.SPELL or a == CardHelper.Attribute.TRAP or a == CardHelper.Attribute.NONE:
			continue
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.Attribute.keys()[a]
		checkbox.toggled.connect(set_filter.bind("attribute", CardHelper.Attribute.get(checkbox.text)))
		attribute_grid_container.add_child(checkbox)
	# Add options for Card Type (Monster, Spell, Trap)
	for t in CardHelper.CardType.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.CardType.keys()[t]
		checkbox.toggled.connect(set_filter.bind("card_type", CardHelper.CardType.get(checkbox.text)))
		card_type_grid_container.add_child(checkbox)
	# Add options for Monster Type (Warrior, Dragon, etc.)
	for mt in CardHelper.MonsterType.values():
		if mt == CardHelper.MonsterType.NONE:
			continue
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.MonsterType.keys()[mt]
		checkbox.toggled.connect(set_filter.bind("monster_type", CardHelper.MonsterType.get(checkbox.text)))
		monster_type_grid_container.add_child(checkbox)
	# Add options for Monster Ability (Normal, Effect, Fusion, Maximum)
	for ma in CardHelper.MonsterAbility.values():
		var checkbox : CheckBox = CheckBox.new()
		checkbox.text = CardHelper.MonsterAbility.keys()[ma]
		checkbox.toggled.connect(set_filter.bind("monster_ability", CardHelper.MonsterAbility.get(checkbox.text)))
		monster_ability_grid_container.add_child(checkbox)

func get_spinbox_filter_map() -> Dictionary:
	var numerical_filter_map = {
		"level": [level_spin_box, "level"],
		"atk": [atk_spin_box, "atk"],
		"def": [def_spin_box, "def"]
	}
	return numerical_filter_map
