extends Panel

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer

const CARD_OPENED_LABEL = preload("res://Resources/Cards/card_opened_label.tscn")
const CARD_FLIP_SCENE = preload("res://Resources/card_flip_scene.tscn")
@onready var next_pack_button: Button = $HBoxContainer2/NextPackButton
@onready var flip_cards_button: Button = $HBoxContainer2/FlipCardsButton
@onready var auto_flip_button: CheckButton = $HBoxContainer2/AutoFlipButton
@onready var open_remaining_button: Button = $HBoxContainer2/OpenRemainingButton
@onready var cards_opened_container: VBoxContainer = $ScrollContainer2/CardsOpenedContainer

@onready var fabled_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Fabled
@onready var marvel_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Marvel
@onready var legendary_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Legendary
@onready var majestic_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Majestic
@onready var super_rare_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/SuperRare
@onready var rare_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Rare
@onready var common_labels: VBoxContainer = $ScrollContainer2/CardsOpenedContainer/Common

@onready var add_binder_button: Button = $HBoxContainer/AddBinderButton
@onready var binder_list: OptionButton = $HBoxContainer/BinderList
@onready var save_cards_button: Button = $HBoxContainer/SaveCardsButton
@onready var save_as_cards_button: Button = $HBoxContainer/SaveAsCardsButton

@onready var hover_panel: CardHoverPanel = $HoverPanel
@onready var total_label: Label = $ScrollContainer2/CardsOpenedContainer/TotalLabel

var cards_saved : bool = false
var opened_card_labels : Dictionary = {}
var binders_cards_saved_to : Array[String] = []
var total_cards_opened : int = 0
func _ready() -> void:
	PackOpenHelper.opened_cards = {}
	await generate_pack()
	next_pack_button.pressed.connect(next_pack)
	flip_cards_button.pressed.connect(flip_all_cards)
	auto_flip_button.toggled.connect(autoflip_toggled)
	open_remaining_button.pressed.connect(open_remaining_packs)
	add_binder_button.pressed.connect(add_binder)
	save_cards_button.pressed.connect(save_cards)
	save_as_cards_button.pressed.connect(add_binder.bind(true))
	fill_binder_list()
	save_cards_button.disabled = true
	save_as_cards_button.disabled = true
	
func next_pack() -> void:
	for child : CardFlipScene in grid_container.get_children():
		if !child.is_flipped:
			return

	for child in grid_container.get_children():
		child.queue_free()
		
	if PackOpenHelper.packs_to_open <= 1:
		save_cards_button.disabled = false
		save_as_cards_button.disabled = false
	
	if PackOpenHelper.packs_to_open > 0:
		scroll_container.scroll_vertical = 0
		await generate_pack()
	if auto_flip_button.button_pressed:
		flip_all_cards()

func flip_all_cards(flip_time : float = 0.30) -> void:
	for card : CardFlipScene in grid_container.get_children():
		await card.flip_card(flip_time)

func autoflip_toggled(toggled : bool) -> void:
	if toggled:
		flip_all_cards()

func open_remaining_packs() -> void:
	open_remaining_button.disabled = true
	next_pack_button.disabled = true
	auto_flip_button.button_pressed = false
	for i in range(0, PackOpenHelper.packs_to_open):
		await flip_all_cards(0.02)
		await next_pack()
	await flip_all_cards(0.02)
	save_cards_button.disabled = false
	save_as_cards_button.disabled = false
	
func generate_pack() -> void:
	print("packs to open " + str(PackOpenHelper.packs_to_open))
	PackOpenHelper.packs_to_open -= 1
	var pack_resource : PackResource = PackOpenHelper.opening_pack_resource
	var total_cards : int = pack_resource.commons_per_pack + pack_resource.guaranteed_rares_per_pack + pack_resource.high_rarity_slot_per_pack
	
	match total_cards:
		1:
			# 1 card pack: Over Rush Rare only
			await generate_over_rush_rare_pack(pack_resource)
		2:
			# 2 card pack: 1 common + 1 rare or higher
			await generate_two_card_pack(pack_resource)
		3:
			# 3 card pack: Maximum monster (all 3 parts)
			await generate_maximum_pack(pack_resource)
		5:
			# 5 card pack: 4 commons + 1 rare or higher
			await generate_five_card_pack(pack_resource)
		_:
			# Default behavior for other pack sizes
			await generate_standard_pack(pack_resource)

func generate_over_rush_rare_pack(pack_resource: PackResource) -> void:
	# 1 card pack: Over Rush Rare only
	var card_flip_scene : CardFlipScene = instantiate_card_scene()
	var card_resource : CardResource = null
	if pack_resource.over_rush_rare_cards.size() > 0:
		card_resource = pack_resource.over_rush_rare_cards.pick_random()
	if card_resource == null:
		printerr("Generated null card_resource for Over Rush Rare pack")
	else:
		card_resource.rarity = CardHelper.Rarity.Over_Rush_Rare
		card_flip_scene.card_resource = card_resource
		grid_container.add_child(card_flip_scene)
	await get_tree().create_timer(0.00001).timeout

func generate_two_card_pack(pack_resource: PackResource) -> void:
	# 2 card pack: Typically 1 common + 1 rare or higher
	# But we check what's actually available in the pack
	var available_pools : Array[Dictionary] = []
	
	# Build list of available card pools with their rarities
	if pack_resource.common_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Common, "cards": pack_resource.common_cards})
	if pack_resource.rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Rare, "cards": pack_resource.rare_cards})
	if pack_resource.super_rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Super_Rare, "cards": pack_resource.super_rare_cards})
	if pack_resource.ultra_rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Ultra_Rare, "cards": pack_resource.ultra_rare_cards})
	if pack_resource.rush_rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Rush_Rare, "cards": pack_resource.rush_rare_cards})
	if pack_resource.secret_rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Secret_Rare, "cards": pack_resource.secret_rare_cards})
	if pack_resource.over_rush_rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Over_Rush_Rare, "cards": pack_resource.over_rush_rare_cards})
	if pack_resource.gold_rare_cards.size() > 0:
		available_pools.append({"rarity": CardHelper.Rarity.Gold_Rare, "cards": pack_resource.gold_rare_cards})
	
	print("2-card pack - Available pools: ", available_pools.size())
	for pool in available_pools:
		print("  - Rarity: ", CardHelper.Rarity.keys()[pool["rarity"]], " (", pool["cards"].size(), " cards)")
	
	# Generate 2 cards based on what's available
	if available_pools.size() == 0:
		printerr("No cards available in 2-card pack")
		return
	elif available_pools.size() == 1:
		# Only one pool available, pick 2 cards from it
		var pool : Array[CardResource] = available_pools[0]["cards"].duplicate()
		var pool_rarity : CardHelper.Rarity = available_pools[0]["rarity"]
		pool.shuffle()
		for i in range(2):
			var card_flip_scene : CardFlipScene = instantiate_card_scene()
			var card_resource = pool.pop_back() if pool.size() > 0 else available_pools[0]["cards"].pick_random()
			if card_resource != null:
				card_resource.rarity = pool_rarity
				card_flip_scene.card_resource = card_resource
				grid_container.add_child(card_flip_scene)
	else:
		# Multiple pools available
		# First card: pick from lowest rarity available (usually common)
		var first_pool : Array[CardResource] = available_pools[0]["cards"].duplicate()
		var first_rarity : CardHelper.Rarity = available_pools[0]["rarity"]
		first_pool.shuffle()
		var first_scene : CardFlipScene = instantiate_card_scene()
		var first_card = first_pool.pick_random()
		if first_card == null:
			printerr("Generated null card_resource for first card in 2-card pack")
		else:
			first_card.rarity = first_rarity
			first_scene.card_resource = first_card
			grid_container.add_child(first_scene)
		
		# Second card: pick from higher rarity using weighted random
		var second_scene : CardFlipScene = instantiate_card_scene()
		var rarity : CardHelper.Rarity = pick_random_high_rarity(pack_resource)
		var second_card : CardResource = get_card_by_rarity(pack_resource, rarity)
		if second_card == null:
			# Fallback: pick from highest available pool
			var fallback_pool = available_pools[available_pools.size() - 1]
			second_card = fallback_pool["cards"].pick_random()
			if second_card != null:
				second_card.rarity = fallback_pool["rarity"]
		if second_card == null:
			printerr("Generated null card_resource for second card in 2-card pack")
		else:
			second_scene.card_resource = second_card
			grid_container.add_child(second_scene)
	
	await get_tree().create_timer(0.00001).timeout

func generate_maximum_pack(pack_resource: PackResource) -> void:
	# 3 card pack: Maximum monster (all 3 parts)
	# Maximum monsters are typically stored together, pick a random set of 3 consecutive cards
	# or pick from ultra_rare/rush_rare cards if they contain Maximum parts
	var maximum_cards : Array[CardResource] = []
	var maximum_rarity : CardHelper.Rarity = CardHelper.Rarity.Ultra_Rare
	
	# Try to find Maximum monster parts from ultra_rare or rush_rare pools
	# Maximum monsters usually have 3 parts (Left, Center, Right)
	if pack_resource.ultra_rare_cards.size() >= 1:
		maximum_cards += pack_resource.ultra_rare_cards.duplicate()
		maximum_rarity = CardHelper.Rarity.Ultra_Rare
	elif pack_resource.rush_rare_cards.size() >= 1:
		maximum_cards += pack_resource.rush_rare_cards.duplicate()
		maximum_rarity = CardHelper.Rarity.Rush_Rare
	elif pack_resource.super_rare_cards.size() >= 1:
		maximum_cards += pack_resource.super_rare_cards.duplicate()
		maximum_rarity = CardHelper.Rarity.Super_Rare
	elif pack_resource.secret_rare_cards.size() >= 1:
		maximum_cards += pack_resource.secret_rare_cards.duplicate()
		maximum_rarity = CardHelper.Rarity.Secret_Rare
	elif pack_resource.over_rush_rare_cards.size() >= 1:
		maximum_cards += pack_resource.over_rush_rare_cards.duplicate()
		maximum_rarity = CardHelper.Rarity.Over_Rush_Rare
	else:
		# Fallback to any available high rarity cards
		maximum_cards += pack_resource.rare_cards.duplicate()
		maximum_rarity = CardHelper.Rarity.Rare
	
	maximum_cards.shuffle()
	
	for i in range(3):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource : CardResource = null
		if maximum_cards.size() > 0:
			card_resource = maximum_cards.pop_back()
		if card_resource == null:
			printerr("Generated null card_resource for Maximum pack part " + str(i + 1))
		else:
			card_resource.rarity = maximum_rarity
			card_flip_scene.card_resource = card_resource
			grid_container.add_child(card_flip_scene)
	await get_tree().create_timer(0.00001).timeout

func generate_five_card_pack(pack_resource: PackResource) -> void:
	# 5 card pack: 4 commons + 1 rare or higher
	var pack_commons : Array[CardResource] = pack_resource.common_cards.duplicate()
	pack_commons.shuffle()
	
	# Generate 4 commons
	for i in range(4):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = pack_commons.pop_back()
		if card_resource == null:
			printerr("Generated null card_resource for common in 5-card pack")
		else:
			card_resource.rarity = CardHelper.Rarity.Common
			card_flip_scene.card_resource = card_resource
			grid_container.add_child(card_flip_scene)
	
	# Generate 1 rare or higher
	var rare_scene : CardFlipScene = instantiate_card_scene()
	var rarity : CardHelper.Rarity = pick_random_high_rarity(pack_resource)
	var rare_card : CardResource = get_card_by_rarity(pack_resource, rarity)
	if rare_card == null:
		printerr("Generated null card_resource for rare+ in 5-card pack")
	else:
		rare_scene.card_resource = rare_card
		grid_container.add_child(rare_scene)
	await get_tree().create_timer(0.00001).timeout

func generate_standard_pack(pack_resource: PackResource) -> void:
	# Standard pack generation (original logic)
	var pack_commons : Array[CardResource] = pack_resource.common_cards.duplicate()
	pack_commons.shuffle()

	# Generate commons
	for i in range(0, pack_resource.commons_per_pack):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = pack_commons.pop_back()
		if card_resource == null:
			printerr("Generated null card_resource for commons")
		else:
			card_resource.rarity = CardHelper.Rarity.Common
			card_flip_scene.card_resource = card_resource
			grid_container.add_child(card_flip_scene)
	
	# Generate guaranteed rares (from rare card pool)
	for i in range(0, pack_resource.guaranteed_rares_per_pack):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var card_resource = pack_resource.rare_cards.pick_random()
		if card_resource == null:
			printerr("Generated null card_resource for guaranteed rare")
		else:
			card_resource.rarity = CardHelper.Rarity.Rare
			card_flip_scene.card_resource = card_resource
			grid_container.add_child(card_flip_scene)
	
	# Generate high rarity slots (weighted random selection)
	for i in range(0, pack_resource.high_rarity_slot_per_pack):
		var card_flip_scene : CardFlipScene = instantiate_card_scene()
		var rarity : CardHelper.Rarity = pick_random_high_rarity(pack_resource)
		var card_resource : CardResource = get_card_by_rarity(pack_resource, rarity)
		
		if card_resource == null:
			printerr("Generated null card_resource for high rarity slot (rarity: " + str(rarity) + ")")
		else:
			card_flip_scene.card_resource = card_resource
			grid_container.add_child(card_flip_scene)
	await get_tree().create_timer(0.00001).timeout

func get_card_by_rarity(pack_resource: PackResource, rarity: CardHelper.Rarity) -> CardResource:
	var card_resource : CardResource = null
	match rarity:
		CardHelper.Rarity.Gold_Rare:
			card_resource = pack_resource.gold_rare_cards.pick_random()
		CardHelper.Rarity.Over_Rush_Rare:
			card_resource = pack_resource.over_rush_rare_cards.pick_random()
		CardHelper.Rarity.Secret_Rare:
			card_resource = pack_resource.secret_rare_cards.pick_random()
		CardHelper.Rarity.Rush_Rare:
			card_resource = pack_resource.rush_rare_cards.pick_random()
		CardHelper.Rarity.Ultra_Rare:
			card_resource = pack_resource.ultra_rare_cards.pick_random()
		CardHelper.Rarity.Super_Rare:
			card_resource = pack_resource.super_rare_cards.pick_random()
		CardHelper.Rarity.Rare:
			card_resource = pack_resource.rare_cards.pick_random()
	# Set the card's rarity to match the pool it was pulled from
	if card_resource != null:
		card_resource.rarity = rarity
	return card_resource

func pick_random_high_rarity(pack_resource: PackResource) -> CardHelper.Rarity:
	var rarities : Array[CardHelper.Rarity] = []
	var weights : Array[float] = []

	# Only include rarities that exist in this set (pull rate > 0 and card array not empty)
	# Order matters - rarest first for push_front
	if pack_resource.gold_rare_rarity > 0 and pack_resource.gold_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Gold_Rare)
		weights.push_front(1.0 / pack_resource.gold_rare_rarity)
	if pack_resource.over_rush_rare_rarity > 0 and pack_resource.over_rush_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Over_Rush_Rare)
		weights.push_front(1.0 / pack_resource.over_rush_rare_rarity)
	if pack_resource.secret_rare_rarity > 0 and pack_resource.secret_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Secret_Rare)
		weights.push_front(1.0 / pack_resource.secret_rare_rarity)
	if pack_resource.rush_rare_rarity > 0 and pack_resource.rush_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Rush_Rare)
		weights.push_front(1.0 / pack_resource.rush_rare_rarity)
	if pack_resource.ultra_rare_rarity > 0 and pack_resource.ultra_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Ultra_Rare)
		weights.push_front(1.0 / pack_resource.ultra_rare_rarity)
	if pack_resource.super_rare_rarity > 0 and pack_resource.super_rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Super_Rare)
		weights.push_front(1.0 / pack_resource.super_rare_rarity)
	# Include Rare cards in the high rarity slot
	if pack_resource.rare_rarity > 0 and pack_resource.rare_cards.size() > 0:
		rarities.push_front(CardHelper.Rarity.Rare)
		weights.push_front(1.0 / pack_resource.rare_rarity)

	# Normalize weights and do cumulative sum
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var cumulative_weights : Array[float] = []
	var acc = 0.0
	for w in weights:
		acc += w / total_weight
		cumulative_weights.append(acc)

	# Weighted random selection
	var r = randf()
	for i in range(rarities.size()):
		if r < cumulative_weights[i]:
			return rarities[i]

	# Fallback to rare if available, otherwise first available rarity
	if pack_resource.rare_cards.size() > 0:
		return CardHelper.Rarity.Rare
	elif rarities.size() > 0:
		return rarities[0]
	else:
		return CardHelper.Rarity.Common

func show_hover_panel(card_resource : CardResource) -> void:
	hover_panel.show()
	hover_panel.set_card_resource(card_resource)

func hide_hover_panel(_card_resource : CardResource) -> void:
	hover_panel.hide()

func instantiate_card_scene() -> CardFlipScene:
	var card_flip_scene : CardFlipScene = CARD_FLIP_SCENE.instantiate()
	card_flip_scene.card_hovered.connect(show_hover_panel)
	card_flip_scene.card_unhovered.connect(hide_hover_panel)
	card_flip_scene.card_flipped.connect(card_flipped_handler)
	return card_flip_scene

func add_binder(and_save_cards : bool = false) -> void:
	var popup = Popup.new()
	popup.title = "Create Binder"
	popup.min_size = Vector2(300, 100)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20,0)
	vbox.custom_minimum_size = Vector2(250, 90)
	var label = Label.new()
	label.text = "Binder Name:"
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
		var binder_name = name_edit.text.strip_edges()
		if binder_name != "":
			var binder = BinderResource.new()
			binder.resource_name = binder_name
			var resource_path = "user://BinderResources/" + binder_name + ".res"
			var dir : DirAccess = DirAccess.open("user://")
			if !dir.file_exists(resource_path):
				ResourceSaver.save(binder, resource_path)
			BinderHelper.binders[binder_name] = binder
			var saved_binder_index : int = BinderHelper.binders.keys().find(binder_name)
			fill_binder_list()
			binder_list.select(saved_binder_index + 1)
			if and_save_cards and binder_list.selected != 0:
				save_cards()
		popup.queue_free())
		
func save_cards() -> void:
	var total_cards_saved : int = 0
	var selected_idx = binder_list.selected
	if selected_idx == 0:
		var no_binder_selected_dialog = AcceptDialog.new()
		no_binder_selected_dialog.dialog_text = "No binder selected to save cards to."
		no_binder_selected_dialog.title = "Warning"
		add_child(no_binder_selected_dialog)
		no_binder_selected_dialog.popup_centered()
		await no_binder_selected_dialog.confirmed
		return
	var binder_name : String = binder_list.get_item_text(selected_idx)
	var binder_path : String = "user://BinderResources/" + binder_name + ".res"
	var binder : BinderResource = ResourceLoader.load(binder_path)
	if binder == null:
		print("Binder resource not found: " + binder_path)
		return
	if binder.name in binders_cards_saved_to:
		var already_saved_dialog = AcceptDialog.new()
		already_saved_dialog.dialog_text = "Cards already saved to this binder."
		already_saved_dialog.title = "Oopsie Poopsie"
		add_child(already_saved_dialog)
		already_saved_dialog.popup_centered()
		await already_saved_dialog.confirmed
		return
	for card_key : String in PackOpenHelper.opened_cards.keys():
		if binder.cards.has(card_key):
			binder.cards[card_key][0] += PackOpenHelper.opened_cards[card_key][0]
		else:
			binder.cards[card_key] = PackOpenHelper.opened_cards[card_key]
		total_cards_saved += PackOpenHelper.opened_cards[card_key][0]

	ResourceSaver.save(binder, binder.resource_path)
	cards_saved = true
	binders_cards_saved_to.append(binder.name)
	var dialog = AcceptDialog.new()
	dialog.dialog_text = str(total_cards_saved) + " pulled cards saved to binder.\n"
	dialog.title = "Success"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed

func fill_binder_list() -> void:
	binder_list.clear()
	binder_list.add_item("")
	for binder_index : int in BinderHelper.binders.size():
		var binder_name : String = BinderHelper.binders.keys()[binder_index]
		var binder_resource : BinderResource = BinderHelper.binders[binder_name]
		if binder_resource != null and binder_name != "":
			binder_list.add_item(binder_name, binder_index + 1)

func _on_main_menu_button_pressed() -> void:
	if !cards_saved:
		var confirmation_dialog = ConfirmationDialog.new()
		confirmation_dialog.dialog_text = "Are you sure you want to leave without saving cards?"
		confirmation_dialog.title = "Warning"
		add_child(confirmation_dialog)
		confirmation_dialog.popup_centered()
		confirmation_dialog.confirmed.connect(SceneChanger.switch_to_main_menu_scene)
	else:
		SceneChanger.switch_to_main_menu_scene()

func card_flipped_handler(card_resource : CardResource) -> void:
	if PackOpenHelper.opened_cards.has(card_resource.id):
		PackOpenHelper.opened_cards[card_resource.id][0] += 1
		var label : Label = opened_card_labels[card_resource.id]
		label.text = str(PackOpenHelper.opened_cards[card_resource.id][0]) + "x " + card_resource.name
	else:
		PackOpenHelper.opened_cards.set(card_resource.id, [1, card_resource])
		var new_label : Label  = CARD_OPENED_LABEL.instantiate()
		new_label.text = "1x " + card_resource.name
		new_label.name = card_resource.id
		add_label_to_rarity_child(card_resource, new_label)
		opened_card_labels[card_resource.id] = new_label
	total_cards_opened += 1
	total_label.text = "Total: " + str(total_cards_opened)
		
func add_label_to_rarity_child(card_resource, new_label) -> void:
	match card_resource.rarity:
		CardHelper.Rarity.Common:
			common_labels.add_child(new_label)
		CardHelper.Rarity.Rare:
			rare_labels.add_child(new_label)
		CardHelper.Rarity.Super_Rare:
			super_rare_labels.add_child(new_label)
		CardHelper.Rarity.Ultra_Rare:
			majestic_labels.add_child(new_label)
		CardHelper.Rarity.Rush_Rare:
			legendary_labels.add_child(new_label)
		CardHelper.Rarity.Secret_Rare:
			marvel_labels.add_child(new_label)
		CardHelper.Rarity.Over_Rush_Rare:
			fabled_labels.add_child(new_label)
		CardHelper.Rarity.Gold_Rare:
			legendary_labels.add_child(new_label)
		CardHelper.Rarity.Promo:
			common_labels.add_child(new_label)
