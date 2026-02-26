extends Panel

class_name DeckEditor

@onready var main_deck_grid_container: GridContainer = $ScrollContainer/VBoxContainer/MainDeckGridContainer
@onready var inventory_grid_container: GridContainer = $ScrollContainer/VBoxContainer/InventoryGridContainer
@onready var extra_deck_grid_container: GridContainer = $ScrollContainer/VBoxContainer/ExtraDeckGridContainer

@onready var binder_cards : BinderCards = $BinderCards
@onready var binder_list: OptionButton = $BinderList
@onready var hover_panel: CardHoverPanel = $HoverPanel
@onready var banlist_list: OptionButton = $HBoxContainer/BanlistList


@onready var deck_label: Label = $ScrollContainer/VBoxContainer/DeckLabel
@onready var inventory_label: Label = $ScrollContainer/VBoxContainer/InventoryLabel
@onready var maybe_label: Label = $ScrollContainer/VBoxContainer/ExtraDeckLabel

@onready var deck_type_options: OptionButton = $HBoxContainer/DeckTypeOptions
@onready var add_deck_button: Button = $HBoxContainer/AddDeckButton
@onready var deck_list_options: OptionButton = $HBoxContainer/DeckListOptions
@onready var save_deck_button: Button = $HBoxContainer/SaveDeckButton
@onready var save_deck_as_button: Button = $HBoxContainer/SaveDeckAsButton
@onready var export_deck_button: Button = $HBoxContainer/ExportDeckButton

const DECK_CARD = preload("res://DeckEditor/deck_card.tscn")

var inventory_cards : Dictionary[String, Array] = {}
var maybe_cards : Dictionary[String, Array] = {}
var main_cards : Dictionary[String, Array] = {}

var current_deck : DeckResource
var current_banlist : BanlistResource

func _ready() -> void:
	fill_binder_list()
	fill_deck_list()
	fill_banlist_list()
	binder_list.item_selected.connect(binder_cards.binder_selected.bind(binder_list))
	banlist_list.item_selected.connect(set_banlist)
	banlist_list.item_selected.connect(binder_cards.set_banlist.bind(banlist_list))
	add_deck_button.pressed.connect(add_new_deck)
	save_deck_button.pressed.connect(save_cards_to_deck)
	save_deck_as_button.pressed.connect(add_new_deck.bind(true))
	export_deck_button.pressed.connect(export_deck)
	binder_cards.add_card_to_main.connect(add_card_to_main)
	binder_cards.add_card_to_inventory.connect(add_card_to_inventory)
	binder_cards.add_card_to_maybe.connect(add_card_to_maybe)
	binder_cards.show_hover_panel.connect(show_hover_panel)
	binder_cards.hide_hover_panel.connect(hide_hover_panel)
	save_deck_button.disabled = true
	export_deck_button.disabled = true
	deck_list_options.item_selected.connect(func(selected_idx):
		if selected_idx != 0:
			load_cards_from_deck()
			save_deck_button.disabled = false
			export_deck_button.disabled = false
		else:
			save_deck_button.disabled = true
			export_deck_button.disabled = true
	)
	binder_list.selected = 1
	binder_list.item_selected.emit(1)

func fill_binder_list() -> void:
	binder_list.clear()
	binder_list.add_item("")
	for new_binder_name : String in BinderHelper.binders.keys():
		var new_binder : BinderResource = BinderHelper.binders[new_binder_name]
		if new_binder != null and new_binder.resource_name != "":
			binder_list.add_item(new_binder.resource_name)

func fill_banlist_list() -> void:
	banlist_list.clear()
	banlist_list.add_item("")
	for banlist_index : int in BanlistHelper.banlists.size():
		var banlist_name : String = BanlistHelper.banlists.keys()[banlist_index]
		var banlist_resource : BanlistResource = BanlistHelper.banlists[banlist_name]
		if banlist_resource != null and banlist_name != "":
			banlist_list.add_item(banlist_name, banlist_index + 1)

func show_hover_panel(card_resource : CardResource, card_scene : Panel) -> void:
	hover_panel.show()
	match card_scene.card_location:
		DeckHelper.CardLocation.NONE:
			hover_panel.position = Vector2(495, 100)
		_:
			hover_panel.position = Vector2(982, 100)
		
	hover_panel.set_card_resource(card_resource)

func hide_hover_panel(_card_resource : CardResource) -> void:
	hover_panel.hide()

func _on_main_menu_button_pressed() -> void:
	SceneChanger.switch_to_main_menu_scene()

func get_total_copies_of_card(card_id: String) -> int:
	var total : int = 0
	if main_cards.has(card_id):
		total += main_cards[card_id][0]
	if inventory_cards.has(card_id):
		total += inventory_cards[card_id][0]
	if maybe_cards.has(card_id):
		total += maybe_cards[card_id][0]
	return total

func get_legend_count_for_type(card_type: CardHelper.CardType) -> int:
	var count : int = 0
	for card_id : String in main_cards:
		var card_resource : CardResource = main_cards[card_id][1]
		if card_resource.is_legend and card_resource.card_type == card_type:
			count += 1
	for card_id : String in inventory_cards:
		var card_resource : CardResource = inventory_cards[card_id][1]
		if card_resource.is_legend and card_resource.card_type == card_type:
			count += 1
	for card_id : String in maybe_cards:
		var card_resource : CardResource = maybe_cards[card_id][1]
		if card_resource.is_legend and card_resource.card_type == card_type:
			count += 1
	return count

func can_add_card(card_resource: CardResource, quantity: int) -> bool:
	var card_id : String = card_resource.id
	
	# Check total copies across all decks (max 3)
	var current_total : int = get_total_copies_of_card(card_id)
	if current_total + quantity > 3:
		print("Cannot add card: Maximum 3 copies allowed across all decks.")
		return false
	
	# Check legend restriction (max 1 legend per card type)
	if card_resource.is_legend:
		var legend_count : int = get_legend_count_for_type(card_resource.card_type)
		if legend_count >= 1:
			var type_name : String = CardHelper.CardType.keys()[card_resource.card_type]
			print("Cannot add card: Only 1 Legend " + type_name + " allowed in the deck.")
			return false
	
	return true

func add_card_to_main(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]
	var card_id = card_resource.id
	
	# Validate deck-building restrictions
	if not can_add_card(card_resource, quantity):
		return
	
	if main_cards.has(card_id):
		main_cards[card_id][0] += quantity
		var card_scene : DeckCard = main_deck_grid_container.get_node(card_id)
		if card_scene:
			card_scene.set_card_quantity(main_cards[card_id][0])
	else:
		main_cards[card_id] = [quantity, card_resource]
		var deck_card_scene : DeckCard = DECK_CARD.instantiate()
		deck_card_scene.name = card_id
		deck_card_scene.card_location = DeckHelper.CardLocation.MAIN
		deck_card_scene.card_resource = card_resource
		deck_card_scene.card_hovered.connect(show_hover_panel.bind(deck_card_scene))
		deck_card_scene.card_unhovered.connect(hide_hover_panel)
		deck_card_scene.card_remove.connect(remove_card)
		deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
		deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
		deck_card_scene.card_move_to_main.connect(move_card_to_main)
		main_deck_grid_container.add_child(deck_card_scene)
		if current_banlist:
			if card_id in current_banlist.cards:
				deck_card_scene.ban_card()
		deck_card_scene.set_card_quantity(quantity)
	populate_card_totals()

func add_card_to_inventory(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]
	var card_id = card_resource.id
	
	# Validate deck-building restrictions
	if not can_add_card(card_resource, quantity):
		return
	
	if inventory_cards.has(card_id):
		inventory_cards[card_id][0] += quantity
		var card_scene : DeckCard = inventory_grid_container.get_node(card_id)
		if card_scene:
			card_scene.set_card_quantity(inventory_cards[card_id][0])
	else:
		inventory_cards[card_id] = [quantity, card_resource]
		var deck_card_scene : DeckCard = DECK_CARD.instantiate()
		deck_card_scene.name = card_id
		deck_card_scene.card_location = DeckHelper.CardLocation.INVENTORY
		deck_card_scene.card_resource = card_resource
		deck_card_scene.card_hovered.connect(show_hover_panel.bind(deck_card_scene))
		deck_card_scene.card_unhovered.connect(hide_hover_panel)
		deck_card_scene.card_remove.connect(remove_card)
		deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
		deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
		deck_card_scene.card_move_to_main.connect(move_card_to_main)
		inventory_grid_container.add_child(deck_card_scene)
		deck_card_scene.set_card_quantity(quantity)
		if current_banlist:
			if card_id in current_banlist.cards:
				deck_card_scene.ban_card()
	populate_card_totals()

func add_card_to_maybe(quantity_and_card_array: Array):
	var quantity : int = quantity_and_card_array[0]
	var card_resource : CardResource = quantity_and_card_array[1]
	var card_id = card_resource.id
	
	# Validate deck-building restrictions
	if not can_add_card(card_resource, quantity):
		return
	
	if maybe_cards.has(card_id):
		maybe_cards[card_id][0] += quantity
		var card_scene : DeckCard = extra_deck_grid_container.get_node(card_id)
		if card_scene:
			card_scene.set_card_quantity(maybe_cards[card_id][0])
	else:
		maybe_cards[card_id] = [quantity, card_resource]
		var deck_card_scene : DeckCard = DECK_CARD.instantiate()
		deck_card_scene.name = card_id
		deck_card_scene.card_location = DeckHelper.CardLocation.EXTRADECK
		deck_card_scene.card_resource = card_resource
		deck_card_scene.card_hovered.connect(show_hover_panel.bind(deck_card_scene))
		deck_card_scene.card_unhovered.connect(hide_hover_panel)
		deck_card_scene.card_remove.connect(remove_card)
		deck_card_scene.card_move_to_inventory.connect(move_card_to_inventory)
		deck_card_scene.card_move_to_maybe.connect(move_card_to_maybe)
		deck_card_scene.card_move_to_main.connect(move_card_to_main)
		extra_deck_grid_container.add_child(deck_card_scene)
		deck_card_scene.set_card_quantity(quantity)
		if current_banlist:
			if card_id in current_banlist.cards:
				deck_card_scene.ban_card()
	populate_card_totals()

func fill_deck_list() -> void:
	deck_list_options.clear()
	deck_list_options.add_item("")
	for deck_index : int in DeckHelper.decks.size():
		var deck_name : String = DeckHelper.decks.keys()[deck_index]
		var deck_resource : DeckResource = DeckHelper.decks[deck_name]
		if deck_resource != null and deck_name != "":
			deck_list_options.add_item(deck_name, deck_index + 1)

func add_new_deck(and_save_deck : bool = false) -> void:
	var popup = Popup.new()
	popup.title = "Create Deck"
	popup.min_size = Vector2(300, 100)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20,0)
	vbox.custom_minimum_size = Vector2(250, 90)
	var label = Label.new()
	label.text = "Deck Name:"
	var name_edit = LineEdit.new()
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	vbox.add_child(name_edit)

	var confirm = Button.new()
	confirm.text = "Create"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(confirm)

	popup.add_child(vbox)
	add_child(popup)
	popup.popup_centered()

	confirm.pressed.connect(func():
		var deck_name = name_edit.text.strip_edges()
		if deck_name != "":
			var deck = DeckResource.new()
			var dir : DirAccess = DirAccess.open("user://")
			deck.resource_name = deck_name
			deck.name = deck_name
			var resource_path = "user://DeckResources/" + deck_name + ".res"
			if !dir.file_exists(resource_path):
				ResourceSaver.save(deck, resource_path)
			DeckHelper.decks[deck_name] = deck
			var saved_deck_index : int = DeckHelper.decks.keys().find(deck_name)
			fill_deck_list()
			deck_list_options.select(saved_deck_index + 1)
			if and_save_deck and deck_list_options.selected != 0:
				save_cards_to_deck()
			deck_list_options.item_selected.emit(deck_list_options.selected)
		popup.queue_free())
	
func save_cards_to_deck() -> void:
	var selected_idx = deck_list_options.selected
	if selected_idx == -1:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No deck selected to save cards to."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var deck_name : String = deck_list_options.get_item_text(selected_idx)
	var deck_path : String = "user://DeckResources/" + deck_name + ".res"
	var deck : DeckResource = ResourceLoader.load(deck_path)
	if deck == null:
		print("Deck resource not found: " + deck_path)
		return
	deck.clear_deck()
	for card_id : String in main_cards:
		deck.main_deck.set(card_id, main_cards[card_id][0])
	for card_id : String in inventory_cards:
		deck.inventory.set(card_id, inventory_cards[card_id][0])
	for card_id : String in maybe_cards:
		deck.maybes.set(card_id, maybe_cards[card_id][0])

	ResourceSaver.save(deck, deck.resource_path)

func load_cards_from_deck() -> void:
	var selected_idx = deck_list_options.get_selected_id()
	if selected_idx == 0:
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No deck selected to load from."
		dialog.title = "Warning"
		add_child(dialog)
		dialog.popup_centered()
		await dialog.confirmed
		return
	var deck_name : String = deck_list_options.get_item_text(selected_idx)
	var deck_path : String = "user://DeckResources/" + deck_name + ".res"
	var deck : DeckResource = ResourceLoader.load(deck_path)
	if deck == null:
		print("Deck resource not found: " + deck_path)
		return
	
	remove_all_cards()
	for card_id : String in deck.main_deck:
		var card_resource := CardDatabase.get_card(card_id)
		if card_resource != null:
			add_card_to_main([deck.main_deck[card_id], card_resource])
	for card_id : String in deck.inventory:
		var card_resource := CardDatabase.get_card(card_id)
		if card_resource != null:
			add_card_to_inventory([deck.inventory[card_id], card_resource])
	for card_id : String in deck.maybes:
		var card_resource := CardDatabase.get_card(card_id)
		if card_resource != null:
			add_card_to_maybe([deck.maybes[card_id], card_resource])

func remove_card(card_scene : DeckCard, quantity_to_remove : int = 1) -> void:
	var new_quantity: int = 0
	match card_scene.card_location:
		DeckHelper.CardLocation.MAIN:
			if main_cards.has(card_scene.card_resource.id):
				if main_cards[card_scene.card_resource.id][0] > quantity_to_remove:
					main_cards[card_scene.card_resource.id][0] -= quantity_to_remove
					new_quantity = main_cards[card_scene.card_resource.id][0]
				else:
					main_cards.erase(card_scene.card_resource.id)
		DeckHelper.CardLocation.INVENTORY:
			if inventory_cards.has(card_scene.card_resource.id):
				if inventory_cards[card_scene.card_resource.id][0] > quantity_to_remove:
					inventory_cards[card_scene.card_resource.id][0] -= quantity_to_remove
					new_quantity = inventory_cards[card_scene.card_resource.id][0]
				else:
					inventory_cards.erase(card_scene.card_resource.id)
		DeckHelper.CardLocation.EXTRADECK:
			if maybe_cards.has(card_scene.card_resource.id):
				if maybe_cards[card_scene.card_resource.id][0] > quantity_to_remove:
					maybe_cards[card_scene.card_resource.id][0] -= quantity_to_remove
					new_quantity = maybe_cards[card_scene.card_resource.id][0]
				else:
					maybe_cards.erase(card_scene.card_resource.id)
	card_scene.set_card_quantity(new_quantity)
	if new_quantity == 0:
		card_scene.queue_free()
	populate_card_totals()

func move_card_to_main(card_scene:DeckCard) -> void:
	var card_resource : CardResource = card_scene.card_resource
	add_card_to_main([1,card_resource])
	remove_card(card_scene)
	
func move_card_to_inventory(card_scene:DeckCard) -> void:
	var card_resource : CardResource = card_scene.card_resource
	add_card_to_inventory([1,card_resource])
	remove_card(card_scene)
	
func move_card_to_maybe(card_scene:DeckCard) -> void:
	var card_resource : CardResource = card_scene.card_resource
	add_card_to_maybe([1,card_resource])
	remove_card(card_scene)

func remove_all_cards() -> void:
	for card_scene :DeckCard in main_deck_grid_container.get_children():
		remove_card(card_scene,3)
	for card_scene :DeckCard in inventory_grid_container.get_children():
		remove_card(card_scene,3)
	for card_scene :DeckCard in extra_deck_grid_container.get_children():
		remove_card(card_scene,3)

func export_deck() -> void:
	var selected_idx = deck_list_options.get_selected_id()
	if selected_idx == -1:
		var no_deck_selected_dialog = AcceptDialog.new()
		no_deck_selected_dialog.dialog_text = "No deck selected to export"
		no_deck_selected_dialog.title = "Warning"
		add_child(no_deck_selected_dialog)
		no_deck_selected_dialog.popup_centered()
		await no_deck_selected_dialog.confirmed
		return
	var deck_name : String = deck_list_options.get_item_text(selected_idx)
	var deck_path : String = "user://DeckResources/" + deck_name + ".res"
	var deck : DeckResource = ResourceLoader.load(deck_path)
	if deck == null:
		print("Deck resource not found: " + deck_path)
		return

	# Build clipboard recipe format
	var monsters : Array = []
	var spells : Array = []
	var traps : Array = []
	
	# Group main deck cards by type
	for card_id : String in deck.main_deck:
		var card_resource : CardResource = CardDatabase.get_card(card_id)
		if card_resource == null:
			continue
		var quantity : int = deck.main_deck[card_id]
		var card_line : String = str(quantity) + " " + card_resource.name
		
		match card_resource.card_type:
			CardHelper.CardType.Monster:
				monsters.append(card_line)
			CardHelper.CardType.Spell:
				spells.append(card_line)
			CardHelper.CardType.Trap:
				traps.append(card_line)
	
	# Build the recipe string
	var recipe : String = ""
	
	if monsters.size() > 0:
		recipe += "Monster\n"
		for monster_line in monsters:
			recipe += monster_line + "\n"
	
	if spells.size() > 0:
		recipe += "Spell\n"
		for spell_line in spells:
			recipe += spell_line + "\n"
	
	if traps.size() > 0:
		recipe += "Trap\n"
		for trap_line in traps:
			recipe += trap_line + "\n"
	
	# Add Side (inventory) section if there are cards
	if deck.inventory.size() > 0:
		recipe += "Side\n"
		for card_id : String in deck.inventory:
			var card_resource : CardResource = CardDatabase.get_card(card_id)
			if card_resource == null:
				continue
			var quantity : int = deck.inventory[card_id]
			recipe += str(quantity) + " " + card_resource.name + "\n"
	
	# Add Extra Deck section if there are cards
	if deck.inventory.size() > 0:
		recipe += "Extra\n"
		for card_id : String in deck.maybes:
			var card_resource : CardResource = CardDatabase.get_card(card_id)
			if card_resource == null:
				continue
			var quantity : int = deck.maybes[card_id]
			recipe += str(quantity) + " " + card_resource.name + "\n"

	DisplayServer.clipboard_set(recipe)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Deck recipe copied to clipboard."
	dialog.title = "Success"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	return

func set_banlist(index : int) -> void:
	if index <= 0:
		current_banlist = null
		get_tree().call_group("bannable_card", "check_if_banned", null)
		return
	var banlist_name : String = banlist_list.get_item_text(index)
	var banlist : BanlistResource = BanlistHelper.banlists.get(banlist_name)
	current_banlist = banlist
	get_tree().call_group("bannable_card", "check_if_banned", banlist)

func populate_card_totals() -> void:
	var total_inventory_cards : int = 0
	var total_main_deck_cards : int = 0
	var total_maybe_cards : int = 0
	for main_deck_quantity_and_card_resource : Array in main_cards.values():
		total_main_deck_cards += main_deck_quantity_and_card_resource[0]
	for inventory_quantity_and_card_resource : Array in inventory_cards.values():
		total_inventory_cards += inventory_quantity_and_card_resource[0]
	for maybe_quantity_and_card_resource : Array in maybe_cards.values():
		total_maybe_cards += maybe_quantity_and_card_resource[0]
	deck_label.text = "Deck " + str(total_main_deck_cards)
	inventory_label.text = "Side " + str(total_inventory_cards)
	maybe_label.text = "Extra " + str(total_maybe_cards)
