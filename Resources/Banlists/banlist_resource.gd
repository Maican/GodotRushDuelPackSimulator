extends Resource

class_name BanlistResource

@export var name : String = ""
@export var cards : Dictionary[String, CardResource] = {}

func clear_banlist() -> void:
	name = ""
	cards = {}
