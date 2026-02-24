extends TextureButton

class_name SetPanel

var pack_resource : PackResource

@onready var pack_size_label: Label = $PackSizeLabel
@onready var pack_amount_label: Label = $PackAmountLabel
@onready var pack_name_label: Label = $PackNameLabel

func _ready() -> void:
	pack_size_label.text = str(pack_resource.pack_size) + " Cards/Pack"
	pack_amount_label.text = str(pack_resource.get_number_of_cards()) + " Total Cards"
	button_group.pressed.connect(set_texture_modulate)

func set_checkbox_name(box_name : String):
	pack_name_label.text = box_name

func set_texture_modulate(button : TextureButton) -> void:
	if self == button:
		self_modulate = Color(0.3, 0.3,0.3)
	else:
		self_modulate = Color(1, 1, 1)
