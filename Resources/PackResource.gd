@tool
extends Resource

class_name PackResource

@export var pack_name : String = ""
@export var pack_code : String = ""
@export var pack_type : String = ""
@export var release_date : String = ""
@export var pack_texture : Texture2D
@export var pack_image_path : String = ""
@export var pack_image_url : String = ""
@export var pack_image_filename : String = ""
@export var number_of_cards : int = 246
@export var pack_size : int = 16

func clear_cards():
	common_cards = []
	rare_cards = []
	super_rare_cards = []
	ultra_rare_cards = []
	rush_rare_cards = []
	secret_rare_cards = []
	over_rush_rare_cards = []
	gold_rare_cards = []
	promo_cards = []
	ResourceSaver.save(self, self.resource_path)
	
@export_tool_button("clear_cards") var clear_cards_action = clear_cards

@export_group("Pullrates")
@export var rare_rarity : float = 5
@export var super_rare_rarity : float = 10
@export var ultra_rare_rarity : float = 24
@export var rush_rare_rarity : float = 48
@export var secret_rare_rarity : float = 96
@export var over_rush_rare_rarity : float = 192
@export var gold_rare_rarity : float = 384
@export var expansion_slot_rarity : float = 15.0
@export_group("Pack contents")
@export var commons_per_pack : int = 4
@export var guaranteed_rares_per_pack : int = 1
@export var high_rarity_slot_per_pack : int = 1

@export_group("Cards")
@export var common_cards : Array[CardResource] = []
@export var rare_cards : Array[CardResource] = []
@export var super_rare_cards : Array[CardResource] = []
@export var ultra_rare_cards : Array[CardResource] = []
@export var rush_rare_cards : Array[CardResource] = []
@export var secret_rare_cards : Array[CardResource] = []
@export var over_rush_rare_cards : Array[CardResource] = []
@export var gold_rare_cards : Array[CardResource] = []
@export var promo_cards : Array[CardResource] = []

# Yu-Gi-Oh! Rush Duel pull rates
# Over Rush Rare: ~384 packs (1 per 16 boxes)
# Gold Rare: ~192 packs (1 per 8 boxes)
# Secret Rare: ~96 packs (1 per 4 boxes)
# Rush Rare: ~48 packs (1 per 2 boxes)
# Ultra Rare: ~24 packs (1 per box)
# Super Rare: ~10 packs (2-3 per box)
# Rare: ~5 packs (4-5 per box)

func get_number_of_cards() -> int:
	return common_cards.size() + rare_cards.size() + super_rare_cards.size() + ultra_rare_cards.size() +  rush_rare_cards.size() + secret_rare_cards.size() + over_rush_rare_cards.size() + gold_rare_cards.size() + promo_cards.size()
