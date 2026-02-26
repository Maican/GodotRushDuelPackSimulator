extends Node

## CardDatabase autoload singleton.
## Loads all CardResources at startup and provides O(1) lookup by card ID.
## This decouples user data (binders, decks, banlists) from resource file paths,
## so user data survives program updates.

var cards : Dictionary[String, CardResource] = {}

const CARD_FILE_LOCATION : String = "res://CardResources/"

func _ready() -> void:
	load_all_cards()

func load_all_cards() -> void:
	cards.clear()
	var dir := DirAccess.open(CARD_FILE_LOCATION)
	if dir == null:
		push_warning("CardDatabase: Cannot open CardResources folder — cards not yet imported?")
		return

	var time_before : int = Time.get_ticks_msec()
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res"):
			var card_path := CARD_FILE_LOCATION + file_name
			var card_resource : CardResource = ResourceLoader.load(card_path)
			if card_resource != null and !card_resource.id.is_empty():
				cards[card_resource.id] = card_resource
		file_name = dir.get_next()
	dir.list_dir_end()
	var time_after : int = Time.get_ticks_msec()
	print("CardDatabase: Loaded " + str(cards.size()) + " cards in " + str(time_after - time_before) + "ms")

func get_card(card_id: String) -> CardResource:
	if cards.has(card_id):
		return cards[card_id]
	push_warning("CardDatabase: Card not found with ID: " + card_id)
	return null

func has_card(card_id: String) -> bool:
	return cards.has(card_id)
