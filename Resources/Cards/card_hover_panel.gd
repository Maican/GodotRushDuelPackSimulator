extends TextureRect

class_name CardHoverPanel

const flip_card_left_pos : Vector2 = Vector2(-308,0)
const flip_card_right_pos : Vector2 = Vector2(375, 0)

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
@onready var type_texture_rect: TextureRect = $TypeTextureRect
@onready var effect_box_texture_rect: TextureRect = $EffectBoxTextureRect
@onready var title_label: Label = $TitleLabel
@onready var type_label: Label = $TypeLabel
@onready var effect_label: RichTextLabel = $EffectLabel

var card_resource : CardResource

func set_card_resource(new_card_resource : CardResource) -> void:
	card_resource = new_card_resource
	translate_card()
	texture = card_resource.load_texture()

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
