extends Control

const Phase3State := preload("res://scripts/phase3/phase3_state.gd")
const UITheme := preload("res://scripts/ui/ui_theme.gd")
const UIViewModels := preload("res://scripts/ui/ui_view_models.gd")
const UI_THEME_PATH := "res://resources/themes/elders_courage_theme.tres"
const TITLE_PLAQUE_PATH := "res://assets/ui/title_plaque_full.png"
const ATTACK_BUTTON_PATH := "res://assets/ui/button_attack.png"
const INVENTORY_BUTTON_PATH := "res://assets/ui/button_inventory.png"
const QUEST_BUTTON_PATH := "res://assets/ui/button_quests.png"
const GRASS_TILE_PATH := "res://assets/terrain/grass_tile.png"
const STONE_TILE_PATH := "res://assets/terrain/stone_tile.png"
const ICE_TILE_PATH := "res://assets/terrain/ice_tile.png"
const LAVA_TILE_PATH := "res://assets/terrain/lava_tile.png"
const CHEST_PATH := "res://assets/items/chest.png"
const FIRE_RUNE_PATH := "res://assets/items/fire_rune.png"

var state
var map_grid: GridContainer
var header_label: Label
var header_zone_label: Label
var header_meta_label: Label
var header_debug_label: Label
var header_xp_bar: ProgressBar
var stats_label: Label
var health_label: Label
var mana_label: Label
var side_xp_label: Label
var health_bar: ProgressBar
var mana_bar: ProgressBar
var side_xp_bar: ProgressBar
var equipment_label: RichTextLabel
var location_details: RichTextLabel
var quest_box: VBoxContainer
var message_box: VBoxContainer
var enemy_panel: PanelContainer
var enemy_label: Label
var enemy_health: ProgressBar
var inventory_panel: PanelContainer
var inventory_grid: GridContainer
var item_details: RichTextLabel
var class_panel: PanelContainer
var bargain_panel: PanelContainer
var bargain_text: RichTextLabel
var merge_panel: PanelContainer
var merge_text: RichTextLabel
var merge_confirm_button: Button
var talent_panel: PanelContainer
var talent_box: VBoxContainer
var quest_panel: PanelContainer
var quest_panel_box: VBoxContainer
var skill_bar: HBoxContainer
var interact_button: Button
var shrine_button: Button
var attack_button: Button
var inventory_toggle_button: Button
var talent_toggle_button: Button
var quest_toggle_button: Button
var restart_button: Button
var texture_cache := {}
var last_animation_id := ""

func _ready() -> void:
	custom_minimum_size = Vector2(1120, 700)
	theme = load(UI_THEME_PATH)
	_ensure_inputs()
	state = Phase3State.new()
	state.state_changed.connect(_refresh)
	state.reset()
	_build_screen()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("phase3_move_north"):
		state.move_player("north")
	elif event.is_action_pressed("phase3_move_south"):
		state.move_player("south")
	elif event.is_action_pressed("phase3_move_east"):
		state.move_player("east")
	elif event.is_action_pressed("phase3_move_west"):
		state.move_player("west")
	elif event.is_action_pressed("phase3_inventory"):
		state.toggle_inventory()
	elif event.is_action_pressed("phase3_attack"):
		state.attack_enemy()
	elif event.is_action_pressed("phase3_interact"):
		_interact()
	elif event.is_action_pressed("phase3_talents"):
		state.toggle_talent_panel()
	elif event.is_action_pressed("phase3_quests"):
		state.toggle_panel("quests")
	elif event.is_action_pressed("phase3_debug"):
		state.toggle_debug_mode()
	elif event.is_action_pressed("phase3_skill_1"):
		_use_skill_slot(0)
	elif event.is_action_pressed("phase3_skill_2"):
		_use_skill_slot(1)
	elif event.is_action_pressed("ui_cancel"):
		state.handle_escape()

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = UITheme.color("deep_background")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITheme.OUTER_MARGIN)
	margin.add_theme_constant_override("margin_top", UITheme.OUTER_MARGIN)
	margin.add_theme_constant_override("margin_right", UITheme.OUTER_MARGIN)
	margin.add_theme_constant_override("margin_bottom", UITheme.OUTER_MARGIN)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", UITheme.SECTION_GAP)
	margin.add_child(root)
	root.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UITheme.SECTION_GAP)
	root.add_child(body)
	body.add_child(_build_map_panel())
	body.add_child(_build_side_panel())
	root.add_child(_build_action_bar())

	inventory_panel = _build_inventory_panel()
	inventory_panel.visible = false
	add_child(inventory_panel)
	talent_panel = _build_talent_panel()
	talent_panel.visible = false
	add_child(talent_panel)
	quest_panel = _build_quest_panel()
	quest_panel.visible = false
	add_child(quest_panel)
	class_panel = _build_class_panel()
	add_child(class_panel)
	bargain_panel = _build_bargain_panel()
	bargain_panel.visible = false
	add_child(bargain_panel)
	merge_panel = _build_merge_panel()
	merge_panel.visible = false
	add_child(merge_panel)

func _build_header() -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, 150)
	frame.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_dark"), UITheme.color("border_gold"), 2, 8))
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	frame.add_child(header)
	var logo := TextureRect.new()
	logo.texture = _load_texture(TITLE_PLAQUE_PATH)
	logo.custom_minimum_size = Vector2(360, 126)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(logo)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 4)
	header.add_child(stack)
	header_zone_label = _gold_label("")
	header_zone_label.add_theme_font_size_override("font_size", UITheme.FONT_HEADER)
	stack.add_child(header_zone_label)
	var divider := ColorRect.new()
	divider.color = Color(0.58, 0.43, 0.20, 0.65)
	divider.custom_minimum_size = Vector2(0, 2)
	stack.add_child(divider)
	header_meta_label = _gold_label("")
	header_meta_label.add_theme_font_size_override("font_size", 16)
	header_meta_label.add_theme_color_override("font_color", UITheme.color("text_secondary"))
	stack.add_child(header_meta_label)
	header_xp_bar = ProgressBar.new()
	header_xp_bar.custom_minimum_size = Vector2(360, 12)
	header_xp_bar.show_percentage = false
	stack.add_child(header_xp_bar)
	header_debug_label = _gold_label("")
	header_debug_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(header_debug_label)
	header_label = header_zone_label
	return frame

func _build_map_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_dark"), UITheme.color("border_muted"), 2, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UITheme.SECTION_GAP)
	panel.add_child(box)
	var title := _gold_label("Elder Road Outskirts")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UITheme.SECTION_GAP)
	box.add_child(content)
	map_grid = GridContainer.new()
	map_grid.columns = 5
	map_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_grid.add_theme_constant_override("h_separation", UITheme.TILE_GAP)
	map_grid.add_theme_constant_override("v_separation", UITheme.TILE_GAP)
	content.add_child(map_grid)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(220, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.10, 0.078, 0.055), UITheme.color("border_muted"), 1, 6))
	content.add_child(detail_panel)
	location_details = RichTextLabel.new()
	location_details.bbcode_enabled = true
	location_details.fit_content = true
	location_details.custom_minimum_size = Vector2(200, 0)
	location_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	location_details.add_theme_font_size_override("normal_font_size", 14)
	detail_panel.add_child(location_details)
	return panel

func _build_side_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_parchment"), Color(0.40, 0.25, 0.12), 2, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UITheme.SECTION_GAP)
	panel.add_child(box)
	var character_box := _add_section(box, "Character Summary")
	stats_label = _dark_label("")
	character_box.add_child(stats_label)
	health_label = _dark_label("")
	health_label.add_theme_font_size_override("font_size", 13)
	character_box.add_child(health_label)
	health_bar = _stat_bar()
	character_box.add_child(health_bar)
	mana_label = _dark_label("")
	mana_label.add_theme_font_size_override("font_size", 13)
	character_box.add_child(mana_label)
	mana_bar = _stat_bar()
	character_box.add_child(mana_bar)
	side_xp_label = _dark_label("")
	side_xp_label.add_theme_font_size_override("font_size", 13)
	character_box.add_child(side_xp_label)
	side_xp_bar = _stat_bar()
	character_box.add_child(side_xp_bar)
	var equipment_box := _add_section(box, "Equipment")
	equipment_label = RichTextLabel.new()
	equipment_label.bbcode_enabled = true
	equipment_label.fit_content = true
	equipment_label.custom_minimum_size = Vector2(340, 70)
	equipment_box.add_child(equipment_label)
	var quest_section := _add_section(box, "The Elder Road")
	quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 2)
	quest_section.add_child(quest_box)
	enemy_panel = PanelContainer.new()
	enemy_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.12, 0.08, 0.07), Color(0.58, 0.20, 0.12), 2, 6))
	var enemy_box := VBoxContainer.new()
	enemy_panel.add_child(enemy_box)
	enemy_label = _gold_label("")
	enemy_box.add_child(enemy_label)
	enemy_health = ProgressBar.new()
	enemy_health.show_percentage = false
	enemy_box.add_child(enemy_health)
	box.add_child(enemy_panel)
	var log_section := _add_section(box, "Messages")
	message_box = VBoxContainer.new()
	message_box.add_theme_constant_override("separation", 4)
	log_section.add_child(message_box)
	return panel

func _build_action_bar() -> Control:
	var bar := HFlowContainer.new()
	bar.custom_minimum_size = Vector2(0, 104)
	bar.add_theme_constant_override("h_separation", 10)
	bar.add_theme_constant_override("v_separation", 8)
	bar.add_child(_action_group("Move", _movement_pad()))
	var location_group := HBoxContainer.new()
	location_group.add_theme_constant_override("separation", UITheme.BUTTON_GAP)
	interact_button = _text_button("Open Container", "Use the primary action on this tile", "secondary")
	interact_button.pressed.connect(_interact)
	location_group.add_child(interact_button)
	shrine_button = _text_button("Activate Shrine", "Activate a shrine on this tile", "success")
	shrine_button.pressed.connect(state.activate_current_shrine)
	location_group.add_child(shrine_button)
	bar.add_child(_action_group("Location", location_group))
	var combat_group := HBoxContainer.new()
	combat_group.add_theme_constant_override("separation", UITheme.BUTTON_GAP)
	attack_button = _image_button(_load_texture(ATTACK_BUTTON_PATH), "Attack active enemy", "primary")
	attack_button.pressed.connect(state.attack_enemy)
	combat_group.add_child(attack_button)
	bar.add_child(_action_group("Combat", combat_group))
	skill_bar = HBoxContainer.new()
	skill_bar.add_theme_constant_override("separation", UITheme.BUTTON_GAP)
	bar.add_child(_action_group("Skills", skill_bar))
	var panel_group := HBoxContainer.new()
	panel_group.add_theme_constant_override("separation", UITheme.BUTTON_GAP)
	inventory_toggle_button = _image_button(_load_texture(INVENTORY_BUTTON_PATH), "Toggle inventory", "panel")
	inventory_toggle_button.pressed.connect(state.toggle_inventory)
	panel_group.add_child(inventory_toggle_button)
	talent_toggle_button = _text_button("Talents", "Toggle talent panel", "panel")
	talent_toggle_button.pressed.connect(state.toggle_talent_panel)
	panel_group.add_child(talent_toggle_button)
	quest_toggle_button = _image_button(_load_texture(QUEST_BUTTON_PATH), "Quest tracker", "panel")
	quest_toggle_button.pressed.connect(func() -> void: state.toggle_panel("quests"))
	panel_group.add_child(quest_toggle_button)
	restart_button = _text_button("Restart", "Restart Phase 3", "danger")
	restart_button.pressed.connect(state.restart_game)
	panel_group.add_child(restart_button)
	bar.add_child(_action_group("Panels", panel_group))
	return bar

func _movement_pad() -> GridContainer:
	var pad := GridContainer.new()
	pad.columns = 3
	pad.custom_minimum_size = Vector2(150, 88)
	pad.add_child(_blank_spacer())
	pad.add_child(_move_button("N", "north"))
	pad.add_child(_blank_spacer())
	pad.add_child(_move_button("W", "west"))
	pad.add_child(_blank_spacer())
	pad.add_child(_move_button("E", "east"))
	pad.add_child(_blank_spacer())
	pad.add_child(_move_button("S", "south"))
	pad.add_child(_blank_spacer())
	return pad

func _build_inventory_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_configure_overlay(panel, Vector2(620, 430))
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_deep"), UITheme.color("border_gold"), 3, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := _gold_label("Inventory and Equipment")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var close := _text_button("Close", "Close inventory")
	close.pressed.connect(state.close_panel)
	box.add_child(close)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	box.add_child(content)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(inventory_grid)
	var details_box := VBoxContainer.new()
	content.add_child(details_box)
	item_details = RichTextLabel.new()
	item_details.bbcode_enabled = true
	item_details.custom_minimum_size = Vector2(250, 250)
	item_details.fit_content = true
	details_box.add_child(item_details)
	var equip := _text_button("Equip", "Equip selected item")
	equip.pressed.connect(func() -> void: state.equip_item(state.selected_item_id))
	details_box.add_child(equip)
	var use := _text_button("Use", "Use selected item")
	use.pressed.connect(func() -> void: state.use_item(state.selected_item_id))
	details_box.add_child(use)
	var merge := _text_button("Merge", "Open a merge recipe for the selected item", "magic")
	merge.pressed.connect(func() -> void: state.open_merge_panel_for_item(state.selected_item_id))
	details_box.add_child(merge)
	var cancel_identify := _text_button("Cancel Identify", "Cancel item target mode")
	cancel_identify.pressed.connect(state.cancel_item_target_mode)
	details_box.add_child(cancel_identify)
	return panel

func _build_talent_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_configure_overlay(panel, Vector2(380, 500))
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_deep"), UITheme.color("border_gold"), 3, 8))
	talent_box = VBoxContainer.new()
	talent_box.add_theme_constant_override("separation", 8)
	panel.add_child(talent_box)
	return panel

func _build_quest_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_configure_overlay(panel, Vector2(560, 500))
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_deep"), UITheme.color("border_gold"), 3, 8))
	quest_panel_box = VBoxContainer.new()
	quest_panel_box.add_theme_constant_override("separation", 8)
	panel.add_child(quest_panel_box)
	return panel

func _build_class_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_configure_overlay(panel, Vector2(960, 540))
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_deep"), Color(0.76, 0.58, 0.28), 4, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := _gold_label("Choose Your Class")
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	box.add_child(cards)
	for class_id in ["roadwarden", "ember_sage", "gravebound_scout"]:
		cards.add_child(_class_card(class_id))
	return panel

func _class_card(class_id: String) -> PanelContainer:
	var class_definition: Dictionary = state.classes_by_id.get(class_id, {})
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 400)
	card.add_theme_stylebox_override("panel", _stylebox(Color(0.13, 0.10, 0.07), Color(0.55, 0.40, 0.20), 2, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = _load_texture(str(class_definition.get("portrait", "")))
	portrait.custom_minimum_size = Vector2(128, 128)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)
	var name := _gold_label(str(class_definition.get("name", class_id)))
	name.add_theme_font_size_override("font_size", 22)
	box.add_child(name)
	var subtitle := _gold_label(str(class_definition.get("subtitle", "")))
	subtitle.add_theme_font_size_override("font_size", 15)
	box.add_child(subtitle)
	var description := _gold_label(str(class_definition.get("description", "")))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 13)
	box.add_child(description)
	var stats: Dictionary = class_definition.get("baseStats", {})
	var preview := _gold_label("STR %d  DEF %d  SPELL %d\nHP %d  Mana %d\nSkills: %s" % [
		int(stats.get("strength", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("spellPower", 0)),
		int(class_definition.get("startingHealth", 0)),
		int(class_definition.get("startingMana", 0)),
		", ".join(_skill_names(class_definition.get("startingSkillIds", []))),
	])
	preview.add_theme_font_size_override("font_size", 13)
	box.add_child(preview)
	var begin := _text_button("Begin Journey", "Start as %s" % class_definition.get("name", class_id), "primary")
	begin.pressed.connect(func() -> void: state.start_class(class_id))
	box.add_child(begin)
	return card

func _build_bargain_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_configure_overlay(panel, Vector2(520, 300))
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_deep"), UITheme.color("curse"), 3, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _gold_label("Breath for Flame")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	bargain_text = RichTextLabel.new()
	bargain_text.bbcode_enabled = true
	bargain_text.fit_content = true
	bargain_text.custom_minimum_size = Vector2(460, 150)
	box.add_child(bargain_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var accept := _text_button("Accept", "Pay health and accept Varn's bargain", "danger")
	accept.pressed.connect(state.accept_pending_bargain)
	buttons.add_child(accept)
	var reject := _text_button("Reject", "Refuse Varn's bargain", "secondary")
	reject.pressed.connect(state.reject_pending_bargain)
	buttons.add_child(reject)
	return panel

func _build_merge_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_configure_overlay(panel, Vector2(560, 330))
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_deep"), UITheme.color("magic"), 3, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _gold_label("Item Merge")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	merge_text = RichTextLabel.new()
	merge_text.bbcode_enabled = true
	merge_text.fit_content = true
	merge_text.custom_minimum_size = Vector2(500, 180)
	box.add_child(merge_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	merge_confirm_button = _text_button("Prepare", "Prepare or confirm this merge", "magic")
	merge_confirm_button.pressed.connect(state.confirm_pending_merge)
	buttons.add_child(merge_confirm_button)
	var cancel := _text_button("Cancel", "Cancel item merge", "secondary")
	cancel.pressed.connect(state.cancel_pending_merge)
	buttons.add_child(cancel)
	return panel

func _refresh() -> void:
	if map_grid == null:
		return
	_refresh_header()
	_refresh_map()
	_refresh_location_details()
	_refresh_stats()
	_refresh_quest()
	_refresh_enemy()
	_refresh_messages()
	_refresh_inventory()
	_refresh_skills()
	_refresh_talents()
	_refresh_quest_panel()
	_refresh_bargain_panel()
	_refresh_merge_panel()
	_refresh_actions()
	_play_last_animation()
	class_panel.visible = not state.class_selected

func _refresh_header() -> void:
	var vm: Dictionary = UIViewModels.get_header_view_model(state)
	header_zone_label.text = str(vm.get("zone", "Elder Road Outskirts"))
	header_meta_label.text = "%s - Level %d    XP %d/%d    Gold %d" % [
		vm.get("className", "Choose Class"),
		int(vm.get("level", 1)),
		int(vm.get("xp", 0)),
		int(vm.get("xpToNextLevel", 50)),
		int(vm.get("gold", 0)),
	]
	header_xp_bar.max_value = float(maxi(1, int(vm.get("xpToNextLevel", 50))))
	header_xp_bar.value = float(vm.get("xp", 0))
	header_debug_label.visible = bool(vm.get("debugVisible", false))
	header_debug_label.text = str(vm.get("debugText", ""))

func _refresh_location_details() -> void:
	var vm: Dictionary = UIViewModels.get_location_details_view_model(state)
	location_details.text = "[b][color=#f0d680]%s[/color][/b]\n%s\n\nExits: %s\nAvailable: %s\nStatus: %s" % [
		vm.get("name", "Unknown Road"),
		vm.get("description", ""),
		", ".join(vm.get("exits", [])),
		vm.get("available", "None"),
		vm.get("status", "Unknown"),
	]

func _current_exits() -> Array[String]:
	var exits: Array[String] = []
	var position: Dictionary = state.player.get("position", {})
	for direction in ["north", "south", "east", "west"]:
		var target := position.duplicate()
		match direction:
			"north":
				target["y"] = int(target["y"]) - 1
			"south":
				target["y"] = int(target["y"]) + 1
			"east":
				target["x"] = int(target["x"]) + 1
			"west":
				target["x"] = int(target["x"]) - 1
		var tile: Dictionary = state.tile_at(target)
		if not tile.is_empty() and not bool(tile.get("blocksMovement", false)):
			exits.append(direction.capitalize())
	return exits

func _current_location_actions(tile: Dictionary) -> Array[String]:
	var actions: Array[String] = []
	if tile.has("containerId"):
		var container: Dictionary = state.containers_by_id.get(str(tile["containerId"]), {})
		actions.append("Container opened" if bool(container.get("opened", false)) else "Open Container")
	if tile.has("shrineId"):
		var shrine: Dictionary = state.shrines_by_id.get(str(tile["shrineId"]), {})
		actions.append("Shrine spent" if bool(shrine.get("activated", false)) else "Activate Shrine")
	if tile.has("encounterId") and not state.completed_encounters.has(str(tile["encounterId"])):
		actions.append("Enemy nearby")
	if str(tile.get("kind", "")) == "elder_stone":
		actions.append("Quest objective")
	return actions

func _location_description(tile: Dictionary) -> String:
	if tile.has("containerId"):
		var container: Dictionary = state.containers_by_id.get(str(tile["containerId"]), {})
		if bool(container.get("opened", false)):
			return "The cache hangs open. Whatever courage it held is now yours."
	if tile.has("shrineId"):
		var shrine: Dictionary = state.shrines_by_id.get(str(tile["shrineId"]), {})
		if bool(shrine.get("activated", false)):
			return "The shrine is quiet now, its old light spent."
	if tile.has("encounterId") and state.completed_encounters.has(str(tile["encounterId"])):
		return "The road is still scarred by combat, but the threat has ended."
	return str(tile.get("description", "The Elder Road waits in ash and old stone."))

func _refresh_map() -> void:
	for child in map_grid.get_children():
		child.queue_free()
	var tiles: Array = state.zone.get("tiles", [])
	tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ap := _tile_position(a)
		var bp := _tile_position(b)
		if int(ap.y) == int(bp.y):
			return int(ap.x) < int(bp.x)
		return int(ap.y) < int(bp.y)
	)
	for tile in tiles:
		var button := Button.new()
		button.custom_minimum_size = Vector2(126, 96)
		button.focus_mode = Control.FOCUS_ALL
		var texture := _tile_texture(str(tile.get("kind", "road")))
		button.icon = texture
		button.expand_icon = true
		button.text = _tile_text(tile)
		button.tooltip_text = str(UIViewModels.get_tile_view_model(state, tile).get("tooltip", ""))
		button.add_theme_stylebox_override("normal", _tile_style(tile))
		button.add_theme_stylebox_override("hover", _stylebox(Color(0.18, 0.14, 0.09), Color(0.95, 0.73, 0.34), 2, 5))
		button.pressed.connect(func(tile_position := _tile_position(tile)) -> void: _move_to_adjacent(tile_position))
		map_grid.add_child(button)

func _refresh_stats() -> void:
	var stats: Dictionary = state.effective_stats()
	stats_label.text = "%s - Level %d\nSTR %d   DEF %d   SPELL %d" % [
		state.current_class().get("name", "Choose Class"),
		int(state.player.get("level", 1)),
		int(stats.get("strength", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("spellPower", 0)),
	]
	health_label.text = "Health  %d/%d" % [int(state.player.get("health", 0)), state.effective_max_health()]
	health_bar.max_value = float(maxi(1, state.effective_max_health()))
	health_bar.value = float(state.player.get("health", 0))
	mana_label.text = "Mana    %d/%d" % [int(state.player.get("mana", 0)), state.effective_max_mana()]
	mana_bar.max_value = float(maxi(1, state.effective_max_mana()))
	mana_bar.value = float(state.player.get("mana", 0))
	side_xp_label.text = "XP      %d/%d" % [int(state.player.get("xp", 0)), int(state.player.get("xpToNextLevel", 50))]
	side_xp_bar.max_value = float(maxi(1, int(state.player.get("xpToNextLevel", 50))))
	side_xp_bar.value = float(state.player.get("xp", 0))
	var equipment: Dictionary = state.player.get("equipment", {})
	equipment_label.text = "Weapon   %s\nArmor    %s\nTrinket  %s" % [
		_equipped_name_rich(str(equipment.get("weapon", ""))),
		_equipped_name_rich(str(equipment.get("armor", ""))),
		_equipped_name_rich(str(equipment.get("trinket", ""))),
	]

func _refresh_skills() -> void:
	for child in skill_bar.get_children():
		child.queue_free()
	for model in UIViewModels.get_skill_button_view_models(state):
		var button := _text_button(str(model.get("name", "")), str(model.get("tooltip", "")), "magic", str(model.get("sublabel", "")))
		button.custom_minimum_size = Vector2(136, 58)
		button.disabled = bool(model.get("disabled", false))
		_apply_skill_button_style(button)
		button.pressed.connect(func(id := str(model.get("id", ""))) -> void: state.use_skill(id))
		skill_bar.add_child(button)

func _refresh_talents() -> void:
	talent_panel.visible = str(state.ui.get("activePanel", "")) == "talents"
	for child in talent_box.get_children():
		child.queue_free()
	var tree: Dictionary = state.current_talent_tree()
	var close := _text_button("Close", "Close talents", "panel")
	close.pressed.connect(state.close_panel)
	talent_box.add_child(close)
	var title := _gold_label("%s  Points: %d" % [tree.get("name", "Talents"), int(state.player.get("talents", {}).get("availablePoints", 0))])
	title.add_theme_font_size_override("font_size", 22)
	talent_box.add_child(title)
	var ranks: Dictionary = state.player.get("talents", {}).get("ranks", {})
	for talent in tree.get("nodes", []):
		var rank := int(ranks.get(str(talent.get("id", "")), 0))
		var button := _text_button("%s %d/%d" % [
			talent.get("name", "Talent"),
			rank,
			int(talent.get("maxRank", 1)),
		], "Spend talent point", "success", "Lvl %d - %s" % [int(talent.get("requiredLevel", 1)), talent.get("description", "")])
		button.custom_minimum_size = Vector2(320, 64)
		button.disabled = not state.can_spend_talent(talent)
		button.pressed.connect(func(id := str(talent.get("id", ""))) -> void: state.spend_talent_point(id))
		talent_box.add_child(button)

func _refresh_quest_panel() -> void:
	quest_panel.visible = str(state.ui.get("activePanel", "")) == "quests" or str(state.ui.get("activePanel", "")) == "log"
	for child in quest_panel_box.get_children():
		child.queue_free()
	var close := _text_button("Close", "Close panel", "panel")
	close.pressed.connect(state.close_panel)
	quest_panel_box.add_child(close)
	var title := _gold_label("Quest and Log")
	title.add_theme_font_size_override("font_size", 26)
	quest_panel_box.add_child(title)
	var quest_title := _gold_label(str(state.quest_chain.get("title", "The Elder Road")))
	quest_title.add_theme_font_size_override("font_size", 20)
	quest_panel_box.add_child(quest_title)
	for stage in state.quest_chain.get("stages", []):
		var stage_line := _gold_label("%s %s" % ["[x]" if bool(stage.get("completed", false)) else "[ ]", stage.get("title", "Stage")])
		stage_line.add_theme_font_size_override("font_size", 16)
		quest_panel_box.add_child(stage_line)
		for objective in stage.get("objectives", []):
			var objective_line := _gold_label("  %s %s" % ["[x]" if bool(objective.get("completed", false)) else "[ ]", objective.get("label", "")])
			objective_line.add_theme_font_size_override("font_size", 13)
			quest_panel_box.add_child(objective_line)
	var log_title := _gold_label("Recent Log")
	log_title.add_theme_font_size_override("font_size", 20)
	quest_panel_box.add_child(log_title)
	var visible_messages: Array = state.messages.duplicate()
	visible_messages.reverse()
	for message in visible_messages:
		var line := _gold_label("[%s] %s" % [_message_label(str(message.get("type", "info"))), message.get("text", "")])
		line.add_theme_font_size_override("font_size", 13)
		line.add_theme_color_override("font_color", _message_color(str(message.get("type", "info"))))
		quest_panel_box.add_child(line)

func _refresh_quest() -> void:
	for child in quest_box.get_children():
		child.queue_free()
	var stages: Array = state.quest_chain.get("stages", [])
	var active: int = state.active_stage_index()
	for index in range(stages.size()):
		var stage: Dictionary = stages[index]
		var title := _dark_label("%s%s" % ["> " if index == active else "", stage.get("title", "Stage")])
		title.add_theme_color_override("font_color", Color(0.12, 0.30, 0.12) if bool(stage.get("completed", false)) else Color(0.25, 0.14, 0.06))
		quest_box.add_child(title)
		if index == active or bool(stage.get("completed", false)):
			for objective in stage.get("objectives", []):
				var line := _dark_label("  %s %s" % ["[x]" if bool(objective.get("completed", false)) else "[ ]", objective.get("label", "")])
				line.add_theme_font_size_override("font_size", 13)
				quest_box.add_child(line)

func _refresh_enemy() -> void:
	enemy_panel.visible = not state.active_enemy.is_empty() and not bool(state.active_enemy.get("defeated", false))
	if not enemy_panel.visible:
		return
	enemy_label.text = "%s  HP %d/%d" % [
		state.active_enemy.get("name", "Enemy"),
		int(state.active_enemy.get("health", 0)),
		int(state.active_enemy.get("maxHealth", 1)),
	]
	enemy_health.max_value = float(state.active_enemy.get("maxHealth", 1))
	enemy_health.value = float(state.active_enemy.get("health", 0))

func _refresh_messages() -> void:
	for child in message_box.get_children():
		child.queue_free()
	var visible_messages: Array = state.messages.duplicate()
	visible_messages = UIViewModels.get_visible_messages(state, 6)
	for message in visible_messages:
		var line := Label.new()
		var type := str(message.get("type", "info"))
		line.text = "[%s] %s" % [_message_label(type), str(message.get("text", ""))]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 13)
		line.add_theme_color_override("font_color", _message_color(type))
		message_box.add_child(line)

func _refresh_inventory() -> void:
	inventory_panel.visible = str(state.ui.get("activePanel", "")) == "inventory"
	for child in inventory_grid.get_children():
		child.queue_free()
	var inventory: Array = state.player.get("inventory", [])
	for index in range(20):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(58, 58)
		slot.focus_mode = Control.FOCUS_ALL
		slot.add_theme_stylebox_override("normal", _stylebox(Color(0.10, 0.085, 0.065), Color(0.42, 0.33, 0.18), 2, 4))
		if index < inventory.size():
			var item: Dictionary = inventory[index]
			var item_definition: Dictionary = state.item_definition(item)
			slot.icon = _load_texture(state.display_icon(item))
			slot.expand_icon = true
			slot.text = "x%d" % int(item.get("quantity", 1))
			slot.tooltip_text = state.display_name(item)
			if str(state.inventory_interaction.get("mode", "normal")) == "identify_target":
				if state.can_identify_item(item):
					slot.add_theme_stylebox_override("normal", _stylebox(Color(0.12, 0.16, 0.11), Color(0.44, 0.74, 0.35), 2, 4))
				else:
					slot.add_theme_stylebox_override("normal", _stylebox(Color(0.08, 0.075, 0.065), Color(0.25, 0.22, 0.17), 2, 4))
			slot.pressed.connect(func(instance_id := str(item.get("instanceId", ""))) -> void: state.select_item(instance_id))
		inventory_grid.add_child(slot)
	var selected: Dictionary = state.selected_item()
	if selected.is_empty():
		var prompt := "[color=#e8d39c]Select an item.[/color]"
		if str(state.inventory_interaction.get("mode", "normal")) == "identify_target":
			prompt = "[color=#e8d39c]Choose an item to identify.[/color]"
		item_details.text = prompt
	else:
		var selected_definition: Dictionary = state.item_definition(selected)
		item_details.text = "[b][color=#f0d680]%s[/color][/b]\n%s\nKnowledge: %s\n\n%s\n\nQuantity: %d%s%s%s%s%s" % [
			state.display_name(selected),
			selected_definition.get("type", "item"),
			selected.get("knowledgeState", "known"),
			state.display_description(selected),
			int(selected.get("quantity", 1)),
			_stats_text(selected_definition.get("stats", {})),
			_discovery_text(selected),
			_soul_text(selected),
			_resonance_text(selected),
			_merge_text(selected),
		]

func _refresh_bargain_panel() -> void:
	var pending: Dictionary = state.ui.get("pendingBargain", {})
	bargain_panel.visible = not pending.is_empty()
	if not bargain_panel.visible:
		return
	var item: Dictionary = state.inventory_item(str(pending.get("itemInstanceId", "")))
	var bargain: Dictionary = state._ring_bargain_definition(item, str(pending.get("bargainId", "")))
	if item.is_empty() or bargain.is_empty():
		bargain_text.text = "[color=#e8d39c]The bargain is no longer available.[/color]"
		return
	var cost: Dictionary = bargain.get("healthCost", {})
	bargain_text.text = "[color=#e8d39c]%s[/color]\n\nCost: %d health, not below 1.\nReward: Ember Bolt +2 damage.\n\nAccept or reject the ring's offer." % [
		bargain.get("offerLine", ""),
		int(cost.get("amount", 0)),
	]

func _refresh_merge_panel() -> void:
	var pending: Dictionary = state.ui.get("pendingMerge", {})
	merge_panel.visible = not pending.is_empty()
	if not merge_panel.visible:
		return
	var recipe_id := str(pending.get("recipeId", ""))
	var recipe: Dictionary = state.item_merges_by_id.get(recipe_id, {})
	if recipe.is_empty():
		merge_text.text = "[color=#e8d39c]That merge recipe is gone.[/color]"
		merge_confirm_button.disabled = true
		return
	var result_definition: Dictionary = state.items_by_id.get(str(recipe.get("resultItemId", "")), {})
	var ready: bool = state.can_merge_recipe(recipe_id)
	var requirements := _merge_requirements_text(recipe)
	merge_text.text = "[color=#e8d39c]%s[/color]\n%s\n\nResult: %s\nConsumes source items: %s\n\n%s" % [
		recipe.get("name", recipe_id),
		recipe.get("description", ""),
		result_definition.get("name", recipe.get("resultItemId", "")),
		"yes" if bool(recipe.get("consumesItems", true)) else "no",
		requirements,
	]
	merge_confirm_button.disabled = not ready
	merge_confirm_button.text = "Confirm Merge" if bool(pending.get("confirm", false)) else "Prepare"
	merge_confirm_button.tooltip_text = "Bind these items into the merged result." if ready else "Requirements are not complete."

func _refresh_actions() -> void:
	var vm: Dictionary = UIViewModels.get_action_availability_view_model(state)
	var container: Dictionary = vm.get("container", {})
	var shrine: Dictionary = vm.get("shrine", {})
	var attack: Dictionary = vm.get("attack", {})
	interact_button.disabled = not bool(container.get("enabled", false))
	interact_button.tooltip_text = str(container.get("label", "Action")) if bool(container.get("enabled", false)) else str(container.get("reason", "No location action here."))
	interact_button.text = "%s\n%s" % [container.get("label", "Action"), "Ready" if bool(container.get("enabled", false)) else "Unavailable"]
	shrine_button.disabled = not bool(shrine.get("enabled", false))
	shrine_button.tooltip_text = "Activate the shrine here." if bool(shrine.get("enabled", false)) else str(shrine.get("reason", "No unused shrine here."))
	shrine_button.text = "Activate Shrine\nReady" if bool(shrine.get("enabled", false)) else "Activate Shrine\nNo shrine"
	attack_button.disabled = not bool(attack.get("enabled", false))
	attack_button.tooltip_text = "Attack active enemy." if bool(attack.get("enabled", false)) else str(attack.get("reason", "No active enemy target."))
	attack_button.text = "" if bool(attack.get("enabled", false)) else "No target"
	restart_button.visible = bool(vm.get("restartVisible", false))
	var active_panel := str(state.ui.get("activePanel", ""))
	_apply_button_variant(inventory_toggle_button, "panel", active_panel == "inventory")
	_apply_button_variant(talent_toggle_button, "panel", active_panel == "talents")
	_apply_button_variant(quest_toggle_button, "panel", active_panel == "quests" or active_panel == "log")

func _interact() -> void:
	var tile: Dictionary = state.current_tile()
	if bool(state.can_transition_from_current_tile().get("available", false)):
		state.transition_from_current_tile()
	elif tile.has("containerId"):
		state.open_current_container()
	elif tile.has("shrineId"):
		state.activate_current_shrine()
	elif tile.has("encounterId"):
		state.start_encounter(str(tile["encounterId"]))
	else:
		state.add_message("There is nothing to interact with here.", "warning")

func _use_skill_slot(index: int) -> void:
	var skills: Array = state.player.get("skills", {}).get("knownSkillIds", [])
	if index < 0 or index >= skills.size():
		state.add_message("No skill is assigned to that slot.", "warning")
		return
	state.use_skill(str(skills[index]))

func _move_to_adjacent(target: Vector2i) -> void:
	var position: Dictionary = state.player.get("position", {})
	var dx := target.x - int(position.get("x", 0))
	var dy := target.y - int(position.get("y", 0))
	if abs(dx) + abs(dy) != 1:
		state.add_message("You can only move to adjacent tiles.", "warning")
	elif dx == 1:
		state.move_player("east")
	elif dx == -1:
		state.move_player("west")
	elif dy == 1:
		state.move_player("south")
	elif dy == -1:
		state.move_player("north")

func _tile_text(tile: Dictionary) -> String:
	return str(UIViewModels.get_tile_view_model(state, tile).get("label", tile.get("name", "Tile")))

func _tile_marker(tile: Dictionary) -> String:
	return str(UIViewModels.get_tile_view_model(state, tile).get("marker", "Road"))

func _tile_position(tile: Dictionary) -> Vector2i:
	var raw: Array = tile.get("position", [0, 0])
	return Vector2i(int(raw[0]), int(raw[1]))

func _tile_texture(kind: String) -> Texture2D:
	match kind:
		"camp":
			return _load_texture(GRASS_TILE_PATH)
		"woods":
			return _load_texture(GRASS_TILE_PATH)
		"chest":
			return _load_texture(CHEST_PATH)
		"shrine":
			return _load_texture(FIRE_RUNE_PATH)
		"ruins":
			return _load_texture(STONE_TILE_PATH)
		"gate":
			return _load_texture(ICE_TILE_PATH)
		"elder_stone":
			return _load_texture(LAVA_TILE_PATH)
		_:
			return _load_texture(STONE_TILE_PATH)

func _tile_style(tile: Dictionary) -> StyleBoxFlat:
	var position := _tile_position(tile)
	var player_position: Dictionary = state.player.get("position", {})
	if position.x == int(player_position.get("x", 0)) and position.y == int(player_position.get("y", 0)):
		return _stylebox(Color(0.20, 0.15, 0.06), Color(1.0, 0.77, 0.22), 4, 6)
	if tile.has("encounterId") and not state.completed_encounters.has(str(tile["encounterId"])):
		return _stylebox(Color(0.14, 0.07, 0.06), Color(0.72, 0.20, 0.12), 3, 5)
	if tile.has("containerId"):
		var container: Dictionary = state.containers_by_id.get(str(tile["containerId"]), {})
		if bool(container.get("opened", false)):
			return _stylebox(Color(0.10, 0.09, 0.075), Color(0.35, 0.30, 0.22), 2, 5)
		return _stylebox(Color(0.13, 0.10, 0.06), Color(0.76, 0.54, 0.22), 3, 5)
	if tile.has("shrineId"):
		var shrine: Dictionary = state.shrines_by_id.get(str(tile["shrineId"]), {})
		if bool(shrine.get("activated", false)):
			return _stylebox(Color(0.08, 0.085, 0.08), Color(0.28, 0.34, 0.30), 2, 5)
		return _stylebox(Color(0.08, 0.10, 0.09), Color(0.30, 0.62, 0.48), 3, 5)
	if str(tile.get("kind", "")) == "elder_stone":
		return _stylebox(Color(0.12, 0.08, 0.12), Color(0.70, 0.45, 0.86), 3, 5)
	if str(tile.get("state", "")) == "visited":
		return _stylebox(Color(0.13, 0.11, 0.08), Color(0.46, 0.36, 0.20), 2, 5)
	return _stylebox(Color(0.09, 0.085, 0.075), Color(0.28, 0.24, 0.18), 2, 5)

func _move_button(text: String, direction: String) -> Button:
	var button := _text_button(text, "Move %s" % direction, "secondary")
	button.custom_minimum_size = Vector2(44, 28)
	button.pressed.connect(func() -> void: state.move_player(direction))
	return button

func _skill_disabled_reason(skill: Dictionary, cooldown: int, cost: int) -> String:
	if state.active_enemy.is_empty() and str(skill.get("targetType", "")) == "enemy" and not state.current_tile().has("encounterId"):
		return "Need target"
	if cooldown > 0:
		return "CD %d" % cooldown
	if str(skill.get("resource", "")) == "mana" and int(state.player.get("mana", 0)) < cost:
		return "Need %d Mana" % cost
	return ""

func _skill_tooltip(skill: Dictionary, cooldown: int, cost: int, disabled_reason: String) -> String:
	var lines: Array[String] = [
		str(skill.get("description", "")),
		"Cost: %d Mana" % cost if str(skill.get("resource", "")) == "mana" else "Cost: None",
		"Cooldown: %s" % ("None" if int(skill.get("cooldownTurns", 0)) == 0 else "%d turns" % int(skill.get("cooldownTurns", 0))),
	]
	if cooldown > 0:
		lines.append("Current cooldown: %d" % cooldown)
	if disabled_reason != "":
		lines.append("Unavailable: %s" % disabled_reason)
	return "\n".join(lines)

func _apply_skill_button_style(button: Button) -> void:
	match state.selected_class_id:
		"roadwarden":
			button.add_theme_stylebox_override("normal", _stylebox(Color(0.12, 0.12, 0.11), Color(0.75, 0.58, 0.27), 2, 5))
		"ember_sage":
			button.add_theme_stylebox_override("normal", _stylebox(Color(0.16, 0.07, 0.04), Color(0.86, 0.36, 0.16), 2, 5))
		"gravebound_scout":
			button.add_theme_stylebox_override("normal", _stylebox(Color(0.08, 0.11, 0.09), Color(0.38, 0.62, 0.48), 2, 5))

func _text_button(text: String, tooltip: String, variant: String = "secondary", sublabel: String = "") -> Button:
	var button := Button.new()
	button.text = text if sublabel == "" else "%s\n%s" % [text, sublabel]
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(132, 42)
	_apply_button_variant(button, variant)
	button.add_theme_color_override("font_color", UITheme.color("text_primary"))
	button.add_theme_color_override("font_disabled_color", UITheme.color("disabled_text"))
	button.add_theme_font_size_override("font_size", UITheme.FONT_BUTTON)
	return button

func _image_button(texture: Texture2D, tooltip: String, variant: String = "panel") -> Button:
	var button := Button.new()
	button.icon = texture
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(92, 54)
	button.tooltip_text = tooltip
	_apply_button_variant(button, variant)
	return button

func _apply_button_variant(button: Button, variant: String, selected := false) -> void:
	var fill := Color(0.15, 0.10, 0.06)
	var hover := Color(0.20, 0.13, 0.07)
	var border := UITheme.color("border_gold")
	match variant:
		"primary":
			fill = Color(0.18, 0.10, 0.045)
			hover = Color(0.24, 0.13, 0.05)
			border = Color(0.92, 0.54, 0.20)
		"danger":
			fill = Color(0.14, 0.06, 0.045)
			hover = Color(0.20, 0.075, 0.045)
			border = UITheme.color("danger")
		"magic":
			fill = Color(0.065, 0.09, 0.12)
			hover = Color(0.075, 0.12, 0.16)
			border = UITheme.color("magic")
		"success":
			fill = Color(0.065, 0.11, 0.075)
			hover = Color(0.08, 0.15, 0.095)
			border = UITheme.color("success")
		"panel":
			fill = Color(0.10, 0.075, 0.052)
			hover = Color(0.15, 0.10, 0.06)
			border = Color(0.58, 0.43, 0.20)
	if selected:
		border = Color(1.0, 0.82, 0.34)
	button.add_theme_stylebox_override("normal", _stylebox(fill, border, 2 if not selected else 3, 5))
	button.add_theme_stylebox_override("hover", _stylebox(hover, Color(0.90, 0.66, 0.28), 2, 5))
	button.add_theme_stylebox_override("focus", _stylebox(hover, Color(1.0, 0.82, 0.34), 3, 5))
	button.add_theme_stylebox_override("pressed", _stylebox(fill.darkened(0.15), border, 2, 5))
	button.add_theme_stylebox_override("disabled", _stylebox(UITheme.color("disabled_fill"), UITheme.color("disabled_border"), 2, 5))

func _add_section(parent: Control, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("section_parchment"), Color(0.43, 0.28, 0.12), 1, 6))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UITheme.SECTION_GAP)
	panel.add_child(box)
	var label := _dark_label(title)
	label.add_theme_font_size_override("font_size", UITheme.FONT_SECTION)
	box.add_child(label)
	return box

func _stat_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 12)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _stylebox(Color(0.16, 0.12, 0.08), Color(0.32, 0.24, 0.14), 1, 4))
	bar.add_theme_stylebox_override("fill", _stylebox(Color(0.64, 0.33, 0.14), Color(0.64, 0.33, 0.14), 0, 4))
	return bar

func _action_group(title: String, content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(UITheme.color("panel_dark"), UITheme.color("border_muted"), 1, 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var label := _gold_label(title)
	label.add_theme_font_size_override("font_size", 12)
	box.add_child(label)
	box.add_child(content)
	return panel

func _configure_overlay(panel: PanelContainer, overlay_size: Vector2) -> void:
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = overlay_size
	panel.size = overlay_size
	panel.offset_left = -overlay_size.x / 2.0
	panel.offset_top = -overlay_size.y / 2.0
	panel.offset_right = overlay_size.x / 2.0
	panel.offset_bottom = overlay_size.y / 2.0

func _play_last_animation() -> void:
	var animation: Dictionary = state.ui.get("lastAnimation", {})
	var animation_id := str(animation.get("id", ""))
	if animation_id == "" or animation_id == last_animation_id:
		return
	last_animation_id = animation_id
	var target := _animation_target(str(animation.get("type", "")), str(animation.get("targetId", "")))
	if target == null:
		return
	var original := target.modulate
	var flash := Color(1.0, 0.86, 0.45)
	match str(animation.get("type", "")):
		"hit":
			flash = Color(1.0, 0.42, 0.30)
		"invalid":
			flash = Color(1.0, 0.34, 0.22)
		"quest":
			flash = Color(0.62, 0.86, 1.0)
		"level":
			flash = Color(0.7, 1.0, 0.52)
	var tween := create_tween()
	target.modulate = flash
	tween.tween_property(target, "modulate", original, 0.28)

func _animation_target(event_type: String, target_id: String) -> Control:
	match event_type:
		"movement":
			return map_grid
		"hit":
			return enemy_panel
		"quest":
			return quest_box
		"level":
			return header_zone_label
		"invalid":
			return message_box
		_:
			match target_id:
				"map":
					return map_grid
				"enemy":
					return enemy_panel
				"quest":
					return quest_box
				"header":
					return header_zone_label
				"messages":
					return message_box
	return null

func _load_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.45, 0.34, 0.18, 1.0))
	var texture := ImageTexture.create_from_image(image)
	texture_cache[path] = texture
	return texture

func _blank_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(44, 28)
	return spacer

func _dark_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	label.add_theme_color_override("font_color", UITheme.color("text_dark"))
	return label

func _gold_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UITheme.color("text_heading"))
	label.add_theme_font_size_override("font_size", 18)
	return label

func _stylebox(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return UITheme.stylebox(fill, border, border_width, radius)

func _equipped_name(instance_id: String) -> String:
	if instance_id == "":
		return "empty"
	var item: Dictionary = state.inventory_item(instance_id)
	if item.is_empty():
		return "empty"
	return state.display_name(item)

func _equipped_name_rich(instance_id: String) -> String:
	var name := _equipped_name(instance_id)
	if name == "empty":
		return "[color=#6f5f43]Empty[/color]"
	return "[color=#f0d680]%s[/color]" % name

func _stats_text(stats) -> String:
	if typeof(stats) != TYPE_DICTIONARY or stats.is_empty():
		return ""
	var parts: Array[String] = []
	for key in stats.keys():
		parts.append("%s %+d" % [str(key), int(stats[key])])
	return "\n\nStats: %s" % ", ".join(parts)

func _discovery_text(item: Dictionary) -> String:
	var definition: Dictionary = state.item_definition(item)
	var lines: Array[String] = []
	if bool(definition.get("attunable", false)):
		var attunement: Dictionary = item.get("attunement", { "points": 0, "level": 0 })
		lines.append("Attunement: Level %d - %d points" % [int(attunement.get("level", 0)), int(attunement.get("points", 0))])
	for property in definition.get("properties", []):
		var revealed: bool = state._instance_has_revealed_property(item, str(property.get("id", "")))
		if revealed:
			var label := "Curse" if bool(property.get("cursed", false)) else "Revealed"
			lines.append("%s: %s - %s" % [label, property.get("name", "Property"), property.get("description", "")])
		elif state._property_has_requirement(property, "attunement"):
			lines.append("Locked Property: Requires Attunement %d" % state._property_requirement_value(property, "attunement"))
		elif state._property_has_requirement(property, "player_level"):
			lines.append("Locked Property: Requires Level %d" % state._property_requirement_value(property, "player_level"))
		elif str(item.get("knowledgeState", "known")) != "known":
			lines.append("Unknown Property: ???")
	if lines.is_empty():
		return ""
	return "\n\n%s" % "\n".join(lines)

func _soul_text(item: Dictionary) -> String:
	if not item.has("soul"):
		return ""
	var soul: Dictionary = item.get("soul", {})
	var soul_definition: Dictionary = state.ring_soul_definition(item)
	var lines: Array[String] = []
	var stage: int = state.ring_soul_reveal_stage(item)
	if stage <= 0:
		lines.append("Soul: ???")
	elif stage == 1:
		lines.append("Soul: A presence stirs inside the ring.")
	else:
		lines.append("Soul: %s, %s" % [soul_definition.get("name", "Unknown"), soul_definition.get("epithet", "the bound")])
		lines.append("Trust: %+d" % int(soul.get("trust", 0)))
	if stage >= 3:
		lines.append("Motivation: %s" % soul_definition.get("motivation", ""))
	var memory_ids: Array = soul.get("memoryIdsRevealed", [])
	if not memory_ids.is_empty():
		lines.append("Memories:")
		for memory in soul_definition.get("memories", []):
			if memory_ids.has(str(memory.get("id", ""))):
				lines.append("- %s: %s" % [memory.get("title", "Memory"), memory.get("text", "")])
	var offered: Array = soul.get("bargainIdsOffered", [])
	var accepted: Array = soul.get("bargainIdsAccepted", [])
	var rejected: Array = soul.get("bargainIdsRejected", [])
	if not offered.is_empty() or not accepted.is_empty() or not rejected.is_empty():
		lines.append("Bargains:")
		for bargain in soul_definition.get("bargains", []):
			var bargain_id := str(bargain.get("id", ""))
			if accepted.has(bargain_id):
				lines.append("- %s: accepted" % bargain.get("name", bargain_id))
			elif rejected.has(bargain_id):
				lines.append("- %s: rejected" % bargain.get("name", bargain_id))
			elif offered.has(bargain_id):
				lines.append("- %s: offered" % bargain.get("name", bargain_id))
	if lines.is_empty():
		return ""
	return "\n\n[color=#d6c4ff][b]Ring Soul[/b][/color]\n%s" % "\n".join(lines)

func _resonance_text(item: Dictionary) -> String:
	var item_id := str(item.get("itemId", ""))
	var lines: Array[String] = []
	for resonance in state.active_resonances():
		if not _resonance_involves_item(resonance, item_id):
			continue
		var resonance_id := str(resonance.get("id", ""))
		if state.is_resonance_discovered(resonance_id):
			var prefix := "Cursed, active" if bool(resonance.get("cursed", false)) else "Active"
			lines.append("%s: %s - %s" % [prefix, resonance.get("name", resonance_id), _resonance_effect_summary(resonance)])
		elif str(resonance.get("visibility", "")) == "hinted" or str(resonance.get("visibility", "")) == "visible":
			lines.append("Hint: %s" % resonance.get("hint", "Something stirs between these items."))
	for resonance in state.item_resonances_by_id.values():
		var resonance_id := str(resonance.get("id", ""))
		if state.is_resonance_discovered(resonance_id) and _resonance_involves_item(resonance, item_id) and not state.active_resonances().has(resonance):
			lines.append("Inactive: %s" % resonance.get("name", resonance_id))
	if lines.is_empty():
		return ""
	return "\n\n[color=#94c7b8][b]Resonance[/b][/color]\n%s" % "\n".join(lines)

func _merge_text(item: Dictionary) -> String:
	var item_id := str(item.get("itemId", ""))
	var lines: Array[String] = []
	for recipe in state.hinted_merge_recipes():
		if not _merge_recipe_involves_item(recipe, item_id):
			continue
		var recipe_id := str(recipe.get("id", ""))
		var prefix := "Ready" if state.can_merge_recipe(recipe_id) else "Hint"
		lines.append("%s: %s" % [prefix, recipe.get("hint", recipe.get("name", recipe_id))])
	if lines.is_empty():
		return ""
	return "\n\n[color=#b8d6ff][b]Merge[/b][/color]\n%s" % "\n".join(lines)

func _resonance_involves_item(resonance: Dictionary, item_id: String) -> bool:
	for required_item_id in resonance.get("requiredItemIds", []):
		if str(required_item_id) == item_id:
			return true
	return false

func _merge_recipe_involves_item(recipe: Dictionary, item_id: String) -> bool:
	for required_item_id in recipe.get("requiredItemIds", []):
		if str(required_item_id) == item_id:
			return true
	return false

func _merge_requirements_text(recipe: Dictionary) -> String:
	var lines: Array[String] = ["Requirements:"]
	for item_id in recipe.get("requiredItemIds", []):
		var item_definition: Dictionary = state.items_by_id.get(str(item_id), {})
		var owned: bool = state.has_item(str(item_id))
		lines.append("- %s: %s" % [item_definition.get("name", item_id), "ready" if owned else "missing"])
	for condition in recipe.get("requiredConditions", []):
		match str(condition.get("type", "")):
			"resonance_discovered":
				var resonance: Dictionary = state.item_resonances_by_id.get(str(condition.get("resonanceId", "")), {})
				var discovered: bool = state.is_resonance_discovered(str(condition.get("resonanceId", "")))
				lines.append("- %s discovered: %s" % [resonance.get("name", condition.get("resonanceId", "")), "ready" if discovered else "missing"])
			"attunement_level":
				var item_definition: Dictionary = state.items_by_id.get(str(condition.get("itemId", "")), {})
				var held_item: Dictionary = state.first_inventory_item_by_item_id(str(condition.get("itemId", "")))
				var level := int(held_item.get("attunement", {}).get("level", 0)) if not held_item.is_empty() else 0
				lines.append("- %s attunement %d/%d" % [item_definition.get("name", condition.get("itemId", "")), level, int(condition.get("value", 0))])
			"soul_name_revealed":
				lines.append("- Bound soul name revealed")
	return "\n".join(lines)

func _resonance_effect_summary(resonance: Dictionary) -> String:
	var parts: Array[String] = []
	for effect in resonance.get("effects", []):
		match str(effect.get("type", "")):
			"stat_bonus", "stat_penalty":
				parts.append("%s %+d" % [effect.get("stat", "stat"), int(effect.get("amount", 0))])
			"skill_damage_bonus":
				parts.append("%s damage %+d" % [state.skills_by_id.get(str(effect.get("skillId", "")), {}).get("name", effect.get("skillId", "skill")), int(effect.get("amount", 0))])
			"skill_heal_bonus":
				parts.append("%s healing %+d" % [state.skills_by_id.get(str(effect.get("skillId", "")), {}).get("name", effect.get("skillId", "skill")), int(effect.get("amount", 0))])
			"skill_cost_modifier":
				parts.append("skill cost %+d" % int(effect.get("amount", 0)))
			"curse_health_cost":
				parts.append("skill use health cost %+d" % int(effect.get("amount", 0)))
	if parts.is_empty():
		return str(resonance.get("description", ""))
	return ", ".join(parts)

func _skill_names(skill_ids: Array) -> Array[String]:
	var names: Array[String] = []
	for skill_id in skill_ids:
		names.append(str(state.skills_by_id.get(str(skill_id), {}).get("name", skill_id)))
	return names

func _message_color(type: String) -> Color:
	match type:
		"success":
			return UITheme.color("success")
		"warning":
			return Color(0.75, 0.42, 0.12)
		"combat":
			return UITheme.color("danger")
		"loot":
			return UITheme.color("text_heading")
		"discovery":
			return UITheme.color("magic")
		"curse":
			return UITheme.color("curse")
		"ring_whisper":
			return Color(0.72, 0.61, 0.95)
		"memory":
			return Color(0.55, 0.78, 0.90)
		"bargain":
			return Color(0.95, 0.66, 0.36)
		"resonance":
			return Color(0.58, 0.78, 0.72)
		"merge":
			return Color(0.95, 0.78, 0.42)
		_:
			return UITheme.color("text_dark")

func _message_label(type: String) -> String:
	match type:
		"success":
			return "Success"
		"warning":
			return "Warning"
		"combat":
			return "Combat"
		"loot":
			return "Loot"
		"discovery":
			return "Discovery"
		"curse":
			return "Curse"
		"ring_whisper":
			return "Whisper"
		"memory":
			return "Memory"
		"bargain":
			return "Bargain"
		"resonance":
			return "Resonance"
		"merge":
			return "Merge"
		_:
			return "Info"

func _ensure_inputs() -> void:
	_add_key_action("phase3_move_north", KEY_W)
	_add_key_action("phase3_move_south", KEY_S)
	_add_key_action("phase3_move_west", KEY_A)
	_add_key_action("phase3_move_east", KEY_D)
	_add_key_action("phase3_inventory", KEY_I)
	_add_key_action("phase3_attack", KEY_SPACE)
	_add_key_action("phase3_interact", KEY_E)
	_add_key_action("phase3_talents", KEY_Y)
	_add_key_action("phase3_talents", KEY_T)
	_add_key_action("phase3_quests", KEY_Q)
	_add_key_action("phase3_debug", KEY_F3)
	_add_key_action("phase3_skill_1", KEY_1)
	_add_key_action("phase3_skill_2", KEY_2)
	_add_key_action("phase3_move_north", KEY_UP)
	_add_key_action("phase3_move_south", KEY_DOWN)
	_add_key_action("phase3_move_west", KEY_LEFT)
	_add_key_action("phase3_move_east", KEY_RIGHT)

func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)
