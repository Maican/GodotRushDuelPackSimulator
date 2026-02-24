extends Resource

class_name DeckResource

@export var name : String = "Deck"
# CardName Key - [quantity, card_resource]
@export var main_deck : Dictionary[String, Array] = {}
@export var inventory : Dictionary[String, Array] = {}
@export var maybes : Dictionary[String, Array] = {}
@export var deck_type : DeckHelper.DeckType = DeckHelper.DeckType.Standard

func export_deck() -> String:
	return "export deck"

func clear_deck() -> void:
	main_deck = {}
	inventory = {}
	maybes = {}
