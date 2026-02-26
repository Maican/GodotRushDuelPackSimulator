extends Resource

class_name BanlistResource

@export var name : String = ""
## Array of banned card IDs (CardResource looked up via CardDatabase at runtime)
@export var cards : Array[String] = []

func clear_banlist() -> void:
	name = ""
	cards = []
