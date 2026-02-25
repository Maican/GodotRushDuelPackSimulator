extends Resource

class_name CardResource

@export var id : String = ""
@export var password : int = 0
@export var name : String = "Rush Dragon"
@export var card_type : CardHelper.CardType = CardHelper.CardType.Monster
@export var attribute : CardHelper.Attribute = CardHelper.Attribute.NONE
@export var monster_type : CardHelper.MonsterType = CardHelper.MonsterType.NONE
@export var monster_ability : CardHelper.MonsterAbility = CardHelper.MonsterAbility.Normal
@export var spell_trap_property : CardHelper.SpellTrapProperty = CardHelper.SpellTrapProperty.NONE
@export var level : int = 0
@export var atk : int = 0
@export var def : int = 0
@export var subtypes : Array[CardHelper.SubType] = []
@export var rarity : CardHelper.Rarity = CardHelper.Rarity.Common
@export var is_legend : bool = false
@export var keywords : Array[CardHelper.Keyword] = []
@export var card_requirement : String = ""
@export var card_effect : String = ""
@export var flavour_text : String = ""
@export var artist_name = ""
@export var image_url : String = ""
@export var image_path : String = ""
@export var small_image_path : String = ""
@export var print_id : String = ""
@export var unique_set_print_ids : Dictionary[int, String] = {}
@export var rarities : Array[CardHelper.Rarity] = []
@export var series : CardHelper.Series = CardHelper.Series.None

func load_texture() -> CompressedTexture2D:
	return ResourceLoader.load(image_path, ".webp")

func pretty_print_card_type() -> String:
	return CardHelper.CardType.keys()[card_type].replace("_", " ")

func pretty_print_attribute() -> String:
	if attribute == CardHelper.Attribute.NONE:
		return ""
	return CardHelper.Attribute.keys()[attribute].replace("_", " ")

func pretty_print_monster_type() -> String:
	if monster_type == CardHelper.MonsterType.NONE:
		return ""
	return CardHelper.MonsterType.keys()[monster_type].replace("_", " ")

func pretty_print_monster_ability() -> String:
	var pretty_string : String = ""
	pretty_string += CardHelper.MonsterAbility.keys()[monster_ability].replace("_", " ") + ", "
	return pretty_string

func pretty_print_subtypes() -> String:
	var pretty_string : String = ""
	for card_subtype : CardHelper.SubType in subtypes:
		pretty_string += CardHelper.SubType.keys()[card_subtype].replace("_", " ") + ", "
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string

func pretty_print_keywords() -> String:
	var pretty_string : String = ""
	for card_keyword : CardHelper.Keyword in keywords:
		pretty_string += CardHelper.Keyword.keys()[card_keyword].replace("_", " ") + ", "
	pretty_string = pretty_string.trim_suffix(", ")
	return pretty_string

func pretty_print_effect_text() -> String:
	var card_effect_text : String = card_effect.replace("\n\n", "\n")
	# Rush Duel doesn't have the same icon system, keep text as-is
	var split_card_effect_text : Array = card_effect_text.split("**")
	var return_text : String = ""
	for i : int in split_card_effect_text.size():
		if i % 2 == 1:
			split_card_effect_text[i] = "[b][i]" + split_card_effect_text[i] + "[/i][/b]"
		return_text += split_card_effect_text[i]
	return return_text
