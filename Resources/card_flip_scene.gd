extends TextureButton

class_name CardFlipScene

signal card_hovered
signal card_unhovered
signal card_flipped

var card_resource : CardResource
var is_flipped : bool = false
var is_flipping : bool = false
var next_texture : CompressedTexture2D
@onready var back_texture : CompressedTexture2D = texture_normal
@onready var rarity_texture_rect: TextureRect = $TextureRect
const COMMON = "res://Resources/Images/Rarities/common.png"
const FABLED = "res://Resources/Images/Rarities/fabled.png"
const LEGENDARY = "res://Resources/Images/Rarities/legendary.png"
const MAJESTIC = "res://Resources/Images/Rarities/majestic.png"
const MARVEL = "res://Resources/Images/Rarities/marvel.png"
const RARE = "res://Resources/Images/Rarities/rare.png"
const SUPER_RARE = "res://Resources/Images/Rarities/SuperRare.png"
const TOKEN = "res://Resources/Images/Rarities/token.png"
const RUSH_RARE = "res://Resources/Images/Rarities/rush_rare.png"



const EFFECT_BOX_EFFECT := preload("uid://cw50br10ltmks")
const EFFECT_BOX_FUSION := preload("uid://d3g8grcqyu0ci")
const EFFECT_BOX_NORMAL := preload("uid://7r6idky4ntek")
const EFFECT_BOX_SPELL := preload("uid://bxtric3t3kht2")
const EFFECT_BOX_TRAP := preload("uid://dlb5y5h6xnafb")

const TITLE_EFFECT_MONSTER := preload("uid://0po7kqpemwk4")
const TITLE_FUSION := preload("uid://cuau2onskvvrl")
const TITLE_NORMAL_MONSTER := preload("uid://blnetymjdm7t1")
const TITLE_SPELL := preload("uid://c8d5o3jevikgg")
const TITLE_TRAP := preload("uid://c03qafecwwi61")

@onready var title_texture_rect: TextureRect = $TitleTextureRect
@onready var effect_box_texture_rect: TextureRect = $EffectBoxTextureRect
@onready var title_label: Label = $TitleLabel
@onready var effect_label: RichTextLabel = $EffectLabel
@onready var type_texture_rect: TextureRect = $TypeTextureRect
@onready var type_label: Label = $TypeLabel


func _ready() -> void:
	pressed.connect(flip_card)
	mouse_entered.connect(emit_card_hovered)
	mouse_exited.connect(emit_card_unhovered)
	if card_resource != null:
		next_texture = card_resource.load_texture()

func emit_card_hovered() -> void:
	if is_flipped:
		card_hovered.emit(card_resource)

func emit_card_unhovered() -> void:
	if is_flipped:
		card_unhovered.emit(card_resource)

func flip_card(flip_time : float = 0.30) -> void:
	if !is_flipped and !is_flipping:
		is_flipping = true
		var original_size_x : float = get_rect().size.x
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.0, 1), flip_time / 2)
		tween.tween_property(self, "position", position + Vector2(original_size_x / 2, 0), flip_time / 2)
		await tween.finished
		var new_tween = create_tween()
		new_tween.set_parallel(true)
		texture_normal = next_texture
		rarity_texture_rect.texture = get_rarity_texture()
		rarity_texture_rect.show()
		new_tween.tween_property(self, "scale", Vector2(1, 1), flip_time / 2)
		new_tween.tween_property(self, "position", position - Vector2(original_size_x / 2, 0), flip_time / 2)
		translate_card()
		is_flipped = true
		is_flipping = false
		card_flipped.emit(card_resource)

func translate_card() -> void:
	title_texture_rect.show()
	effect_box_texture_rect.show()
	type_texture_rect.show()
	title_label.show()
	effect_label.show()
	type_label.show()
	title_label.text = card_resource.name
	if card_resource.name.length() <= 50:
		title_label.add_theme_font_size_override("font_size", 16)
	if card_resource.card_requirement:
		effect_label.text = "[Requirement] " + card_resource.card_requirement + "\n"
	
	if card_resource.card_effect:
		effect_label.text = "[Effect] " + card_resource.card_effect + "\n"
	else:
		effect_label.text = card_resource.flavour_text
	
	if card_resource.card_type == CardHelper.CardType.Monster:
		type_label.text = card_resource.pretty_print_monster_type() + " / " + card_resource.pretty_print_monster_ability()
	elif card_resource.card_type == CardHelper.CardType.Spell:
		type_label.text = CardHelper.SpellTrapProperty.keys()[card_resource.spell_trap_property]
	elif card_resource.card_type == CardHelper.CardType.Trap:
		type_label.text = CardHelper.SpellTrapProperty.keys()[card_resource.spell_trap_property]
	
	match card_resource.card_type:
		CardHelper.CardType.Monster:
			match card_resource.monster_ability:
				CardHelper.MonsterAbility.Normal:
					type_texture_rect.texture = TITLE_NORMAL_MONSTER
					title_texture_rect.texture = TITLE_NORMAL_MONSTER
					effect_box_texture_rect.texture = EFFECT_BOX_NORMAL
				CardHelper.MonsterAbility.Effect:
					type_texture_rect.texture = TITLE_EFFECT_MONSTER
					title_texture_rect.texture = TITLE_EFFECT_MONSTER
					effect_box_texture_rect.texture = EFFECT_BOX_EFFECT
				CardHelper.MonsterAbility.Maximum:
					type_texture_rect.texture = TITLE_EFFECT_MONSTER
					title_texture_rect.texture = TITLE_EFFECT_MONSTER
					effect_box_texture_rect.texture = EFFECT_BOX_EFFECT
				CardHelper.MonsterAbility.Fusion:
					type_texture_rect.texture = TITLE_FUSION
					title_texture_rect.texture = TITLE_FUSION
					effect_box_texture_rect.texture = EFFECT_BOX_FUSION
		CardHelper.CardType.Spell:
			type_texture_rect.texture = TITLE_SPELL
			title_texture_rect.texture = TITLE_SPELL
			effect_box_texture_rect.texture = EFFECT_BOX_SPELL
		CardHelper.CardType.Trap:
			type_texture_rect.texture = TITLE_TRAP
			title_texture_rect.texture = TITLE_TRAP
			effect_box_texture_rect.texture = EFFECT_BOX_TRAP

func get_rarity_texture() -> Texture2D:
	var path : String = COMMON
	match card_resource.rarity:
		CardHelper.Rarity.Common:
			path = COMMON
		CardHelper.Rarity.Rare:
			path = RARE
		CardHelper.Rarity.Super_Rare:
			path = SUPER_RARE
		CardHelper.Rarity.Ultra_Rare:
			path = MAJESTIC
		CardHelper.Rarity.Rush_Rare:
			path = RUSH_RARE
		CardHelper.Rarity.Secret_Rare:
			path = LEGENDARY
		CardHelper.Rarity.Over_Rush_Rare:
			path = MARVEL
		CardHelper.Rarity.Gold_Rare:
			path = FABLED
		CardHelper.Rarity.Promo:
			path = TOKEN
	return ResourceLoader.load(path, ".png")
