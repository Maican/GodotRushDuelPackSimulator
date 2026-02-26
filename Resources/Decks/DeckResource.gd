extends Resource

class_name DeckResource

@export var name : String = "Deck"
## card_id → quantity (CardResource looked up via CardDatabase at runtime)
@export var main_deck : Dictionary[String, int] = {}
@export var inventory : Dictionary[String, int] = {}
@export var maybes : Dictionary[String, int] = {}
@export var deck_type : DeckHelper.DeckType = DeckHelper.DeckType.Standard

func export_deck() -> String:
	return "export deck"

func clear_deck() -> void:
	main_deck = {}
	inventory = {}
	maybes = {}
