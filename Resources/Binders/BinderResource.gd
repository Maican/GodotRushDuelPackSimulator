extends Resource

class_name BinderResource

## card_id → quantity (CardResource looked up via CardDatabase at runtime)
@export var cards : Dictionary[String, int] = {}
@export var name : String = ""

func clear_binder() -> void:
	cards = {}
