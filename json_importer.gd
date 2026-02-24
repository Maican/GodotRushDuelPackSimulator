extends Node

class_name JsonImporter

signal import_started
signal download_started
signal progress_string_changed
signal download_finished

var image_queue : Array[CardResource] = []
var pack_image_queue : Array[PackResource] = []
var image_paths : Dictionary[String, String] = {}
var pack_image_paths : Dictionary[String, String] = {}
var active_requests : int = 0
var active_pack_requests : int = 0
const MAX_CONCURRENT_REQUESTS : int = 40

const JSON_FILE_LOCATION : String = "res://Resources/Json/Sets/"
const PACK_FILE_LOCATION : String = "res://PackResources/"
const CARD_FILE_LOCATION : String = "res://CardResources/"
const ALL_RUSH_CARDS_JSON := "res://Resources/Json/all_rush_cards.json"
const RUSH_SETS_JSON := "res://Resources/Json/rush_sets.json"

var importing_card_name : String = ""
var downloading_card_text : String = ""
var progress_string : String = ""

# Dictionary to store created CardResources by konami_id to avoid duplicates
var card_resources_by_id : Dictionary = {}
# Dictionary mapping set codes to PackResources
var pack_resources_by_code : Dictionary = {}

func import_cards() -> void:
	import_started.emit()
	DirAccess.make_dir_absolute("res://PackResources")
	DirAccess.make_dir_absolute("res://PackResources/Images")
	DirAccess.make_dir_absolute("user://BinderResources")
	DirAccess.make_dir_absolute("user://DeckResources")
	DirAccess.make_dir_absolute("res://CardResources")
	
	# Step 1: Create PackResources from rush_sets.json
	create_pack_resources_from_sets()
	
	# Step 2: Load all cards from all_rush_cards.json and assign them to packs
	load_cards_and_assign_to_packs()
	
	# Step 3: Start downloading images
	_start_next_pack_image_batch()
	_start_next_image_batch()

func create_pack_resources_from_sets() -> void:
	if !FileAccess.file_exists(RUSH_SETS_JSON):
		push_error("rush_sets.json not found at " + RUSH_SETS_JSON)
		return
	
	var file = FileAccess.open(RUSH_SETS_JSON, FileAccess.READ)
	if file == null:
		push_error("Failed to open rush_sets.json")
		return
		
	var content = file.get_as_text()
	file.close()
	var packs_array : Array = JSON.parse_string(content)
	
	if packs_array == null:
		push_error("Failed to parse rush_sets.json")
		return
	
	# Iterate through each pack
	for pack_data : Dictionary in packs_array:
		var pack_name : String = pack_data.get("name", "")
		var pack_code : String = pack_data.get("code", "")
		var pack_type : String = pack_data.get("type", "")
		var release_date : String = pack_data.get("release_date", "")
		var cards_per_pack : int = pack_data.get("cards_per_pack", 5)
		
		if pack_code.is_empty():
			continue
		
		progress_string = "Creating pack: " + pack_name
		progress_string_changed.emit()
		
		# Create PackResource
		var pack_resource : PackResource = PackResource.new()
		pack_resource.resource_name = pack_name
		pack_resource.pack_name = pack_name
		pack_resource.pack_code = pack_code
		pack_resource.pack_type = pack_type
		pack_resource.release_date = release_date
		
		# Sanitize set code for filename (replace / with _)
		var sanitized_code : String = pack_code.replace("/", "_")
		pack_resource.resource_path = PACK_FILE_LOCATION + sanitized_code + ".res"
		
		# Set pack image path - we'll get the URL via API
		var pack_image_code : String = pack_code.replace("/", "")
		pack_resource.pack_image_path = PACK_FILE_LOCATION + "Images/" + pack_image_code + "-BoosterJP.png"
		pack_resource.pack_image_filename = pack_image_code + "-BoosterJP.png"
		
		# Queue pack for image download (we'll fetch the real URL via API)
		if !pack_image_paths.has(pack_code):
			pack_image_paths[pack_code] = pack_resource.pack_image_path
			pack_image_queue.append(pack_resource)
		
		# Set pack configuration based on cards per pack and type
		pack_resource.pack_size = cards_per_pack
		configure_pack_from_size_and_type(pack_resource, cards_per_pack, pack_type)
		
		# Save the pack resource
		ResourceSaver.save(pack_resource, pack_resource.resource_path)
		
		# Store in dictionary for later card assignment
		pack_resources_by_code[pack_code] = pack_resource
		
		await get_tree().create_timer(0.00000000001).timeout

func configure_pack_from_size_and_type(pack_resource: PackResource, cards_per_pack: int, pack_type: String) -> void:
	# Set default pull rates for Rush Duel
	pack_resource.rare_rarity = 5.0
	pack_resource.super_rare_rarity = 10.0
	pack_resource.ultra_rare_rarity = 24.0
	pack_resource.rush_rare_rarity = 48.0
	pack_resource.secret_rare_rarity = 96.0
	pack_resource.over_rush_rare_rarity = 192.0
	pack_resource.gold_rare_rarity = 384.0
	
	# Configure pack slots based on cards_per_pack and type
	if cards_per_pack == 1:
		# Single card packs - typically Over Rush Rare or promo
		pack_resource.commons_per_pack = 0
		pack_resource.guaranteed_rares_per_pack = 0
		pack_resource.high_rarity_slot_per_pack = 1
		# Adjust for Over Rush Rare packs
		if "Secret Ace" in pack_type or "Over" in pack_type:
			pack_resource.over_rush_rare_rarity = 1.0  # Guaranteed
	elif cards_per_pack == 2:
		# 2-card packs - 1 common, 1 rare or higher (Tournament/Battle Packs)
		pack_resource.commons_per_pack = 1
		pack_resource.guaranteed_rares_per_pack = 0
		pack_resource.high_rarity_slot_per_pack = 1
	elif cards_per_pack == 3:
		# 3-card packs - likely contains Maximum pieces or Victory packs
		pack_resource.commons_per_pack = 1
		pack_resource.guaranteed_rares_per_pack = 0
		pack_resource.high_rarity_slot_per_pack = 2
	elif cards_per_pack == 4:
		# 4-card packs - High-end packs (Over Rush, High-Grade Collection)
		pack_resource.commons_per_pack = 2
		pack_resource.guaranteed_rares_per_pack = 1
		pack_resource.high_rarity_slot_per_pack = 1
	elif cards_per_pack == 5:
		# 5-card packs - Standard booster packs
		pack_resource.commons_per_pack = 3
		pack_resource.guaranteed_rares_per_pack = 1
		pack_resource.high_rarity_slot_per_pack = 1
	else:
		# Default fallback
		pack_resource.commons_per_pack = max(0, cards_per_pack - 2)
		pack_resource.guaranteed_rares_per_pack = 1
		pack_resource.high_rarity_slot_per_pack = 1

func load_cards_and_assign_to_packs() -> void:
	if !FileAccess.file_exists(ALL_RUSH_CARDS_JSON):
		push_error("all_rush_cards.json not found at " + ALL_RUSH_CARDS_JSON)
		return
	
	var file = FileAccess.open(ALL_RUSH_CARDS_JSON, FileAccess.READ)
	if file == null:
		push_error("Failed to open all_rush_cards.json")
		return
		
	var content = file.get_as_text()
	file.close()
	var cards_array : Array = JSON.parse_string(content)
	
	if cards_array == null:
		push_error("Failed to parse all_rush_cards.json")
		return
	
	# Process each card
	for card_json : Dictionary in cards_array:
		var konami_id : int = card_json.get("yugipedia_page_id", 0)
		if konami_id == 0:
			continue
		
		# Check if we already created this card
		var card_resource : CardResource = null
		if card_resources_by_id.has(konami_id):
			card_resource = card_resources_by_id[konami_id]
		else:
			# Create new CardResource
			card_resource = CardResource.new()
			load_json_into_card(card_json, card_resource)
			
			if card_resource.id.is_empty():
				continue
			
			# Set image paths
			var dir_image_folder : String = CARD_FILE_LOCATION + "Images/"
			var res_dir = DirAccess.open("res://")
			if !res_dir.dir_exists(dir_image_folder):
				res_dir.make_dir(dir_image_folder)
			
			# If we've already downloaded this card's image
			if image_paths.has(card_resource.id):
				card_resource.image_path = image_paths.get(card_resource.id)
			else:
				card_resource.image_path = dir_image_folder + card_resource.id + ".webp"
				image_paths[card_resource.id] = card_resource.image_path
				if !card_resource.image_url.is_empty():
					image_queue.append(card_resource)
			
			# Save the CardResource once
			card_resource.resource_name = card_resource.name
			card_resource.resource_path = CARD_FILE_LOCATION + card_resource.id + ".res"
			ResourceSaver.save(card_resource, card_resource.resource_path)
			
			# Store in dictionary
			card_resources_by_id[konami_id] = card_resource
		
		progress_string = card_resource.name
		progress_string_changed.emit()
		
		# Now assign this card to all sets it appears in
		assign_card_to_sets(card_json, card_resource)
		
		await get_tree().create_timer(0.00000000001).timeout
	
	# Save all modified pack resources
	for set_code in pack_resources_by_code:
		var pack_resource : PackResource = pack_resources_by_code[set_code]
		if pack_resource.resource_path != "" and pack_resource.resource_path != null:
			ResourceSaver.save(pack_resource, pack_resource.resource_path)

func assign_card_to_sets(card_json: Dictionary, card_resource: CardResource) -> void:
	# The card_json contains a "sets" field with regional printings
	# We'll focus on the "ja" (Japanese) region for now
	var sets_data : Dictionary = card_json.get("sets", {})
	var ja_sets : Array = sets_data.get("ja", [])
	
	for printing : Dictionary in ja_sets:
		var set_number : String = printing.get("set_number", "")
		var rarities : Array = printing.get("rarities", [])
		
		if set_number.is_empty():
			continue
		
		# Extract set code from set_number (e.g., "RD/KP07-JP055" -> "RD/KP07")
		var set_code : String = extract_set_code_from_number(set_number)
		
		if !pack_resources_by_code.has(set_code):
			# This set doesn't exist in our rush_sets.json, skip
			continue
		
		var pack_resource : PackResource = pack_resources_by_code[set_code]
		
		# Store original rarity
		var original_rarity = card_resource.rarity
		
		# Process ALL rarities for this printing (a card can appear at multiple rarities)
		for rarity_raw : String in rarities:
			var rarity : CardHelper.Rarity = normalize_rarity(rarity_raw)
			
			# Temporarily set the card's rarity for this printing
			card_resource.rarity = rarity
			
			# Assign to the appropriate rarity array in the pack
			assign_card_to_pack(pack_resource, card_resource)
		
		# Restore original rarity
		card_resource.rarity = original_rarity

func normalize_rarity(rarity_raw: String) -> CardHelper.Rarity:
	# Normalize rarity string to match enum
	var rarity_str : String = rarity_raw.replace(" ", "_").replace("-", "_")
	
	# Handle special cases that don't directly map to enum
	match rarity_str:
		"Normal_Parallel_Rare":
			return CardHelper.Rarity.Common
		"Super_Parallel_Rare":
			return CardHelper.Rarity.Super_Rare
		"Ultra_Parallel_Rare":
			return CardHelper.Rarity.Ultra_Rare
		"Rush_Parallel_Rare":
			return CardHelper.Rarity.Rush_Rare
		_:
			if CardHelper.Rarity.keys().has(rarity_str):
				return CardHelper.Rarity[rarity_str]
			else:
				push_warning("Unknown rarity: " + rarity_raw + " - defaulting to Common")
				return CardHelper.Rarity.Common

func extract_set_code_from_number(set_number: String) -> String:
	# Examples: "RD/KP07-JP055" -> "RD/KP07"
	#           "RD/LGP1-JP042" -> "RD/LGP1"
	#           "RD/S224-JP002" -> "RD/S224"
	#           "RD/SA03-JP002" -> "RD/SA03"
	var parts : Array = set_number.split("-")
	if parts.size() > 0:
		return parts[0]
	return ""

func _start_next_pack_image_batch():
	while active_pack_requests < MAX_CONCURRENT_REQUESTS and pack_image_queue.size() > 0:
		var pack_resource : PackResource = pack_image_queue.pop_front()
		var http_request = HTTPRequest.new()
		add_child(http_request)
		active_pack_requests += 1
		http_request.request_completed.connect(_http_pack_api_request_completed.bind(pack_resource, http_request))
		
		# Use MediaWiki API to get the actual image URL
		var api_url = "https://yugipedia.com/api.php?action=query&titles=File:" + pack_resource.pack_image_filename.uri_encode() + "&prop=imageinfo&iiprop=url&format=json"
		var error = http_request.request(api_url)
		if error != OK:
			push_error("An error occurred in the API request for pack image: " + pack_resource.pack_name)
			active_pack_requests -= 1
	if pack_image_queue.size() == 0 and active_pack_requests == 0:
		pass  # All pack images downloaded

func _start_next_image_batch():
	download_started.emit()
	while active_requests < MAX_CONCURRENT_REQUESTS and image_queue.size() > 0:
		var card_resource : CardResource = image_queue.pop_front()
		var http_request = HTTPRequest.new()
		add_child(http_request)
		active_requests += 1
		http_request.request_completed.connect(_http_card_api_request_completed.bind(card_resource, http_request))
		
		# Use MediaWiki API to get the actual image URL from the filename
		var api_url = "https://yugipedia.com/api.php?action=query&titles=File:" + card_resource.image_url.uri_encode() + "&prop=imageinfo&iiprop=url&format=json"
		var error = http_request.request(api_url)
		if error != OK:
			push_error("An error occurred in the API request for card image: " + card_resource.name)
			active_requests -= 1
	if image_queue.size() == 0 and active_requests == 0:
		download_finished.emit()

func _http_pack_api_request_completed(result, response_code, headers, body, pack_resource, http_request):
	progress_string = "Getting pack image URL: " + pack_resource.pack_name
	progress_string_changed.emit()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_text = body.get_string_from_utf8()
		var json_result = JSON.parse_string(json_text)
		
		if json_result != null and json_result.has("query") and json_result.query.has("pages"):
			var pages = json_result.query.pages
			for page_id in pages:
				var page = pages[page_id]
				if page.has("imageinfo") and page.imageinfo.size() > 0:
					var image_url = page.imageinfo[0].get("url", "")
					if !image_url.is_empty():
						pack_resource.pack_image_url = image_url
						# Now download the actual image
						var download_request = HTTPRequest.new()
						add_child(download_request)
						download_request.request_completed.connect(_http_pack_image_download_completed.bind(pack_resource, download_request))
						var error = download_request.request(image_url)
						if error != OK:
							push_error("Failed to download pack image from: " + image_url)
							active_pack_requests -= 1
						return
		
		push_warning("Could not find image URL for pack: " + pack_resource.pack_name + " (File: " + pack_resource.pack_image_filename + ")")
		active_pack_requests -= 1
	else:
		push_warning("API request failed for pack image: " + pack_resource.pack_name)
		active_pack_requests -= 1
	
	http_request.queue_free()
	_start_next_pack_image_batch()

func _http_pack_image_download_completed(result, response_code, headers, body, pack_resource, http_request):
	progress_string = "Downloading pack image: " + pack_resource.pack_name
	progress_string_changed.emit()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		if body.size() > 0:
			var file = FileAccess.open(pack_resource.pack_image_path, FileAccess.WRITE)
			if file:
				file.store_buffer(body)
				file.close()
				pack_resource.pack_texture = ResourceLoader.load(pack_resource.pack_image_path)
				ResourceSaver.save(pack_resource)
			else:
				push_error("Failed to open file for writing: " + pack_resource.pack_image_path)
		else:
			push_error("Empty pack image data for: " + pack_resource.pack_image_url)
	else:
		push_warning("Pack image download failed for " + pack_resource.pack_name)
		push_warning("  URL: " + pack_resource.pack_image_url)
		push_warning("  Result: " + str(result) + ", Response code: " + str(response_code))
	
	active_pack_requests -= 1
	http_request.queue_free()
	_start_next_pack_image_batch()

func _http_card_api_request_completed(result, response_code, headers, body, card_resource, http_request):
	progress_string = "Getting image URL: " + card_resource.name
	progress_string_changed.emit()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_text = body.get_string_from_utf8()
		var json_result = JSON.parse_string(json_text)
		
		if json_result != null and json_result.has("query") and json_result.query.has("pages"):
			var pages = json_result.query.pages
			for page_id in pages:
				var page = pages[page_id]
				if page.has("imageinfo") and page.imageinfo.size() > 0:
					var image_url = page.imageinfo[0].get("url", "")
					if !image_url.is_empty():
						# Now download the actual image
						var download_request = HTTPRequest.new()
						add_child(download_request)
						download_request.request_completed.connect(_http_card_image_download_completed.bind(card_resource, download_request))
						var error = download_request.request(image_url)
						if error != OK:
							push_error("Failed to download card image from: " + image_url)
							active_requests -= 1
						http_request.queue_free()
						return
		
		push_warning("Could not find image URL for card: " + card_resource.name + " (File: " + card_resource.image_url + ")")
		active_requests -= 1
	else:
		push_warning("API request failed for card image: " + card_resource.name)
		active_requests -= 1
	
	http_request.queue_free()
	_start_next_image_batch()

func _http_card_image_download_completed(result, response_code, headers, body, card_resource, http_request):
	progress_string = "Downloading image: " + card_resource.name
	progress_string_changed.emit()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		if body.size() > 0:
			# Load the image from the downloaded buffer
			var image = Image.new()
			var error = image.load_png_from_buffer(body)
			if error != OK:
				# Try WebP if PNG fails
				error = image.load_webp_from_buffer(body)
			if error != OK:
				# Try PNG if JPG fails
				error = image.load_jpg_from_buffer(body)

			if error == OK:
				# Save as WebP with 0.85 compression
				var webp_data = image.save_webp_to_buffer(false, 0.85)
				var file = FileAccess.open(card_resource.image_path, FileAccess.WRITE)
				if file:
					file.store_buffer(webp_data)
					file.close()
				else:
					push_error("Failed to open file for writing: " + card_resource.image_path)
			else:
				push_error("Failed to load image from buffer for: " + card_resource.name)
		else:
			push_error("Empty image data for card: " + card_resource.name)
	else:
		push_error("Image download failed for " + card_resource.name + " (ID: " + card_resource.id + ")")
		push_error("  Result: " + str(result) + ", Response code: " + str(response_code))
	
	active_requests -= 1
	http_request.queue_free()
	_start_next_image_batch()
	
func assign_card_to_pack(pack_resource:PackResource, card_resource:CardResource) -> void:
	match card_resource.rarity:
		CardHelper.Rarity.Common:
			pack_resource.common_cards.append(card_resource)
		CardHelper.Rarity.Rare:
			pack_resource.rare_cards.append(card_resource)
		CardHelper.Rarity.Super_Rare:
			pack_resource.super_rare_cards.append(card_resource)
		CardHelper.Rarity.Ultra_Rare:
			pack_resource.ultra_rare_cards.append(card_resource)
		CardHelper.Rarity.Rush_Rare:
			pack_resource.rush_rare_cards.append(card_resource)
		CardHelper.Rarity.Secret_Rare:
			pack_resource.secret_rare_cards.append(card_resource)
		CardHelper.Rarity.Over_Rush_Rare:
			pack_resource.over_rush_rare_cards.append(card_resource)
		CardHelper.Rarity.Gold_Rare:
			pack_resource.gold_rare_cards.append(card_resource)
		CardHelper.Rarity.Promo:
			pack_resource.promo_cards.append(card_resource)

func clear_cards_and_packs() -> void:
	var dir_access := DirAccess.open("res://PackResources")
	
	for file in dir_access.get_files():
		if file.ends_with(".tres"):
			var pack_resource : PackResource = ResourceLoader.load("res://PackResources//" + file)
			pack_resource.clear_cards()
			ResourceSaver.save(pack_resource, pack_resource.resource_path)

func load_json_into_card(json:Dictionary, card_resource:CardResource) -> void:
	# Use yugipedia_page_id as the unique card ID
	if json.has("yugipedia_page_id"):
		card_resource.id = str(int(json.get("yugipedia_page_id")))
	
	# Store the official Konami password for YDKE export
	if json.has("konami_id"):
		if json.get("konami_id") != null:
			card_resource.password = json.get("konami_id")
	
	# Card name - handle multilingual data
	if json.has("name"):
		var name_data = json.get("name")
		if name_data is Dictionary:
			# Try to get English name first, then Japanese
			if name_data.has("en") and name_data.get("en") != null:
				card_resource.name = name_data.get("en")
		elif name_data is String:
			card_resource.name = name_data
	
	# Card type (Monster, Spell, Trap)
	if json.has("card_type"):
		var type_str : String = json.get("card_type").replace(" ", "_").replace("-", "_")
		if CardHelper.CardType.keys().has(type_str):
			card_resource.card_type = CardHelper.CardType[type_str]
	
	# Attribute (DARK, LIGHT, etc.) - for monsters
	if json.has("attribute"):
		var attr_str : String = json.get("attribute").replace(" ", "_").to_upper()
		if CardHelper.Attribute.keys().has(attr_str):
			card_resource.attribute = CardHelper.Attribute[attr_str]
	
	# Monster Type and Ability from monster_type_line (e.g., "Thunder / Effect")
	if json.has("monster_type_line"):
		var type_line : String = json.get("monster_type_line")
		var parts : Array = type_line.split(" / ")
		
		# First part is the monster type (Dragon, Warrior, Thunder, etc.)
		if parts.size() > 0:
			var monster_type_str : String = parts[0].strip_edges().replace(" ", "_").replace("-", "_")
			if CardHelper.MonsterType.keys().has(monster_type_str):
				card_resource.monster_type = CardHelper.MonsterType[monster_type_str]
		
		# Second part is the monster ability (Effect, Normal, etc.)
		if parts.size() > 1:
			var ability_str : String = parts[1].strip_edges().replace(" ", "_").replace("-", "_")
			if CardHelper.MonsterAbility.keys().has(ability_str):
				card_resource.monster_ability = CardHelper.MonsterAbility[ability_str]
	
	# Spell/Trap Property (Normal, Continuous, Equip, etc.)
	if json.has("property"):
		var prop_str : String = json.get("property").replace(" ", "_").replace("-", "_")
		if CardHelper.SpellTrapProperty.keys().has(prop_str):
			card_resource.spell_trap_property = CardHelper.SpellTrapProperty[prop_str]
	
	# Level
	if json.has("level"):
		card_resource.level = int(json.get("level"))
	
	# ATK
	if json.has("atk"):
		card_resource.atk = int(json.get("atk"))
	
	# DEF
	if json.has("def"):
		card_resource.def = int(json.get("def"))
	
	# Card effect text - handle multilingual data
	if json.has("effect"):
		var effect_data = json.get("effect")
		if effect_data is Dictionary:
			# Try to get English effect first, then Japanese
			if effect_data.has("en") and effect_data.get("en") != null:
				card_resource.card_effect = effect_data.get("en")
		elif effect_data is String:
			card_resource.card_effect = effect_data
	
	# Requirement text - handle multilingual data
	if json.has("requirement"):
		var req_data = json.get("requirement")
		if req_data is Dictionary:
			if req_data.has("en") and req_data.get("en") != null:
				var req_text = req_data.get("en")
				if !req_text.is_empty():
					card_resource.card_requirement = req_text
		elif req_data is String:
			if req_data != "None" and !req_data.is_empty():
				card_resource.card_requirement = req_data
	
	# Flavour text - handle multilingual data
	if json.has("text"):
		var text_data = json.get("text")
		if text_data is Dictionary:
			if text_data.has("en") and text_data.get("en") != null:
				card_resource.flavour_text = text_data.get("en")
		elif text_data is String:
			card_resource.flavour_text = text_data
	
	# Legend status
	if json.has("legend"):
		card_resource.is_legend = json.get("legend", false)
	
	# Flip image URL - use rushcard.io CDN
	if json.has("images") and json["images"].size() > 0 and json["images"][0].has("image"):
		card_resource.image_url = json["images"][0].get("image", "")
	
	# Set print IDs from sets information
	if json.has("sets"):
		var sets_data : Dictionary = json.get("sets")
		var ja_sets : Array = sets_data.get("ja", [])
		if ja_sets.size() > 0:
			# Use the first set number as the primary print ID
			var first_printing : Dictionary = ja_sets[0]
			card_resource.print_id = first_printing.get("set_number", card_resource.id)
			
			# Store all unique set print IDs
			for i in range(ja_sets.size()):
				var printing : Dictionary = ja_sets[i]
				var set_number : String = printing.get("set_number", "")
				if !set_number.is_empty():
					card_resource.unique_set_print_ids[i] = set_number
	
	# Default print_id if not set
	if card_resource.print_id.is_empty():
		card_resource.print_id = card_resource.id

func set_pack_textures() -> void:
	for pack : PackResource in PackOpenHelper.packs.values():
		pack.pack_texture = ResourceLoader.load(pack.pack_image_path)
		ResourceSaver.save(pack)
