extends Control
@onready var grid_container: GridContainer = $Panel/ScrollContainer/GridContainer
@onready var open_pack_button: Button = $Panel/OpenPackButton
const SET_RADIO_BUTTON_GROUP = preload("res://Resources/SetRadioButtonGroup.tres")
const SET_PANEL = preload("res://Sets/set_panel.tscn")
@onready var spin_box: SpinBox = $Panel/SpinBox
const PACK_OPEN_SCREEN = preload("res://PackOpening/pack_open_screen.tscn")

func _ready() -> void:
	open_pack_button.disabled = true
	open_pack_button.pressed.connect(open_packs)
	load_available_packs()

func load_available_packs() -> void:
	# Iterate through pre-loaded packs from PackOpenHelper
	for pack_name in PackOpenHelper.packs:
		var pack_resource : PackResource = PackOpenHelper.packs[pack_name]
		
		var new_set_panel : SetPanel = SET_PANEL.instantiate()
		new_set_panel.pack_resource = pack_resource
		new_set_panel.button_group = SET_RADIO_BUTTON_GROUP
		grid_container.add_child(new_set_panel)
		new_set_panel.pressed.connect(checkbox_pressed)
		new_set_panel.set_checkbox_name(pack_name)
		
		# Set texture if available
		if pack_resource.pack_texture != null:
			new_set_panel.texture_normal = pack_resource.pack_texture
	print(SET_RADIO_BUTTON_GROUP.get_buttons())

func open_packs() -> void:
	PackOpenHelper.opening_pack_resource = SET_RADIO_BUTTON_GROUP.get_pressed_button().pack_resource
	PackOpenHelper.packs_to_open = int(spin_box.value)
	PackOpenHelper.opened_cards.clear()
	get_tree().change_scene_to_packed(PACK_OPEN_SCREEN)

func checkbox_pressed() -> void:
	if SET_RADIO_BUTTON_GROUP.get_pressed_button():
		open_pack_button.disabled = false

func _on_main_menu_button_pressed() -> void:
	SceneChanger.switch_to_main_menu_scene()
