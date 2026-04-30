extends Control

const Phase3State := preload("res://scripts/phase3/phase3_state.gd")
const TitlePlaqueTexture := preload("res://assets/ui/title_plaque.png")
const AttackButtonTexture := preload("res://assets/ui/button_attack.png")
const InventoryButtonTexture := preload("res://assets/ui/button_inventory.png")
const QuestButtonTexture := preload("res://assets/ui/button_quests.png")
const GrassTileTexture := preload("res://assets/terrain/grass_tile.png")
const StoneTileTexture := preload("res://assets/terrain/stone_tile.png")
const IceTileTexture := preload("res://assets/terrain/ice_tile.png")
const LavaTileTexture := preload("res://assets/terrain/lava_tile.png")
const ChestTexture := preload("res://assets/items/chest.png")
const FireRuneTexture := preload("res://assets/items/fire_rune.png")
const PlayerTexture := preload("res://assets/sprites/player/gravebound_knight.png")
const ScoutTexture := preload("res://assets/portraits/elf_scout.png")
const WarriorTexture := preload("res://assets/portraits/elder_warrior.png")

var state
var map_grid: GridContainer
var header_label: Label
var stats_label: Label
var equipment_label: RichTextLabel
var quest_box: VBoxContainer
var message_box: VBoxContainer
var enemy_panel: PanelContainer
var enemy_label: Label
var enemy_health: ProgressBar
var inventory_panel: PanelContainer
var inventory_grid: GridContainer
var item_details: RichTextLabel
var class_panel: PanelContainer
var talent_panel: PanelContainer
var talent_box: VBoxContainer
var skill_bar: HBoxContainer
var interact_button: Button
var shrine_button: Button
var attack_button: TextureButton
var restart_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2(1120, 700)
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

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color(0.055, 0.048, 0.042)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
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
	class_panel = _build_class_panel()
	add_child(class_panel)

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 80)
	header.add_theme_constant_override("separation", 14)
	var logo := TextureRect.new()
	logo.texture = TitlePlaqueTexture
	logo.custom_minimum_size = Vector2(260, 72)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(logo)
	header_label = Label.new()
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.add_theme_font_size_override("font_size", 24)
	header_label.add_theme_color_override("font_color", Color(0.94, 0.80, 0.42))
	header.add_child(header_label)
	return header

func _build_map_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.08, 0.067, 0.052), Color(0.54, 0.39, 0.20), 3, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := _gold_label("Elder Road Outskirts")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	map_grid = GridContainer.new()
	map_grid.columns = 5
	map_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_grid.add_theme_constant_override("h_separation", 8)
	map_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(map_grid)
	return panel

func _build_side_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.74, 0.58, 0.34), Color(0.40, 0.25, 0.12), 2, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	stats_label = _dark_label("")
	box.add_child(stats_label)
	equipment_label = RichTextLabel.new()
	equipment_label.bbcode_enabled = true
	equipment_label.fit_content = true
	equipment_label.custom_minimum_size = Vector2(340, 95)
	box.add_child(equipment_label)
	var quest_title := _dark_label("The Elder Road")
	quest_title.add_theme_font_size_override("font_size", 20)
	box.add_child(quest_title)
	quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 2)
	box.add_child(quest_box)
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
	var log_title := _dark_label("Messages")
	log_title.add_theme_font_size_override("font_size", 18)
	box.add_child(log_title)
	message_box = VBoxContainer.new()
	message_box.add_theme_constant_override("separation", 2)
	box.add_child(message_box)
	return panel

func _build_action_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 92)
	bar.add_theme_constant_override("separation", 10)
	bar.add_child(_movement_pad())
	interact_button = _text_button("Open Container", "Open a container on this tile")
	interact_button.pressed.connect(state.open_current_container)
	bar.add_child(interact_button)
	shrine_button = _text_button("Activate Shrine", "Activate a shrine on this tile")
	shrine_button.pressed.connect(state.activate_current_shrine)
	bar.add_child(shrine_button)
	attack_button = _image_button(AttackButtonTexture, "Attack active enemy")
	attack_button.pressed.connect(state.attack_enemy)
	bar.add_child(attack_button)
	skill_bar = HBoxContainer.new()
	skill_bar.add_theme_constant_override("separation", 6)
	bar.add_child(skill_bar)
	var inventory_button := _image_button(InventoryButtonTexture, "Toggle inventory")
	inventory_button.pressed.connect(state.toggle_inventory)
	bar.add_child(inventory_button)
	var talent_button := _text_button("Talents", "Toggle talent panel")
	talent_button.pressed.connect(state.toggle_talent_panel)
	bar.add_child(talent_button)
	var quest_button := _image_button(QuestButtonTexture, "Quest tracker")
	quest_button.pressed.connect(func() -> void: quest_box.grab_focus())
	bar.add_child(quest_button)
	restart_button = _text_button("Restart", "Restart Phase 3")
	restart_button.pressed.connect(state.restart_game)
	bar.add_child(restart_button)
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
	panel.position = Vector2(260, 120)
	panel.size = Vector2(620, 430)
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.055, 0.045, 0.035, 0.97), Color(0.68, 0.52, 0.24), 3, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := _gold_label("Inventory and Equipment")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
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
	var cancel_identify := _text_button("Cancel Identify", "Cancel item target mode")
	cancel_identify.pressed.connect(state.cancel_item_target_mode)
	details_box.add_child(cancel_identify)
	return panel

func _build_talent_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(890, 105)
	panel.size = Vector2(360, 500)
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.06, 0.05, 0.04, 0.98), Color(0.68, 0.52, 0.24), 3, 8))
	talent_box = VBoxContainer.new()
	talent_box.add_theme_constant_override("separation", 8)
	panel.add_child(talent_box)
	return panel

func _build_class_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(160, 90)
	panel.size = Vector2(960, 540)
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.055, 0.045, 0.035, 0.98), Color(0.76, 0.58, 0.28), 4, 8))
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
	portrait.texture = load(str(class_definition.get("portrait", "")))
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
	var begin := _text_button("Begin Journey", "Start as %s" % class_definition.get("name", class_id))
	begin.pressed.connect(func() -> void: state.start_class(class_id))
	box.add_child(begin)
	return card

func _refresh() -> void:
	if map_grid == null:
		return
	_refresh_header()
	_refresh_map()
	_refresh_stats()
	_refresh_quest()
	_refresh_enemy()
	_refresh_messages()
	_refresh_inventory()
	_refresh_skills()
	_refresh_talents()
	_refresh_actions()
	class_panel.visible = not state.class_selected

func _refresh_header() -> void:
	var position: Dictionary = state.player.get("position", {})
	var tile: Dictionary = state.current_tile()
	header_label.text = "%s | %s | Level %d | XP %d/%d | Talent Pts %d | Gold %d | Position %d,%d | %s" % [
		state.zone.get("name", "Elder Road"),
		state.current_class().get("name", "Choose Class"),
		int(state.player.get("level", 1)),
		int(state.player.get("xp", 0)),
		int(state.player.get("xpToNextLevel", 50)),
		int(state.player.get("talents", {}).get("availablePoints", 0)),
		int(state.player.get("gold", 0)),
		int(position.get("x", 0)),
		int(position.get("y", 0)),
		tile.get("name", "Unknown"),
	]

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
		button.custom_minimum_size = Vector2(120, 84)
		button.focus_mode = Control.FOCUS_ALL
		var texture := _tile_texture(str(tile.get("kind", "road")))
		button.icon = texture
		button.expand_icon = true
		button.text = _tile_text(tile)
		button.tooltip_text = str(tile.get("description", ""))
		button.add_theme_stylebox_override("normal", _tile_style(tile))
		button.add_theme_stylebox_override("hover", _stylebox(Color(0.18, 0.14, 0.09), Color(0.95, 0.73, 0.34), 2, 5))
		button.pressed.connect(func(tile_position := _tile_position(tile)) -> void: _move_to_adjacent(tile_position))
		map_grid.add_child(button)

func _refresh_stats() -> void:
	var stats: Dictionary = state.effective_stats()
	stats_label.text = "Health: %d/%d  Mana: %d/%d\nStrength: %d  Defense: %d  Spell: %d" % [
		int(state.player.get("health", 0)),
		state.effective_max_health(),
		int(state.player.get("mana", 0)),
		state.effective_max_mana(),
		int(stats.get("strength", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("spellPower", 0)),
	]
	var equipment: Dictionary = state.player.get("equipment", {})
	equipment_label.text = "[b]Equipment[/b]\nWeapon: %s\nArmor: %s\nTrinket: %s" % [
		_equipped_name(str(equipment.get("weapon", ""))),
		_equipped_name(str(equipment.get("armor", ""))),
		_equipped_name(str(equipment.get("trinket", ""))),
	]

func _refresh_skills() -> void:
	for child in skill_bar.get_children():
		child.queue_free()
	for skill_id in state.player.get("skills", {}).get("knownSkillIds", []):
		var skill: Dictionary = state.skills_by_id.get(str(skill_id), {})
		if skill.is_empty():
			continue
		var cooldown: int = int(state.player.get("skills", {}).get("cooldowns", {}).get(str(skill_id), 0))
		var cost: int = state.effective_skill_cost(skill)
		var button := _text_button("%s\n%dM%s" % [skill.get("name", skill_id), cost, " CD:%d" % cooldown if cooldown > 0 else ""], str(skill.get("description", "")))
		button.custom_minimum_size = Vector2(130, 54)
		button.disabled = cooldown > 0 or (str(skill.get("resource", "")) == "mana" and int(state.player.get("mana", 0)) < cost)
		button.pressed.connect(func(id := str(skill_id)) -> void: state.use_skill(id))
		skill_bar.add_child(button)

func _refresh_talents() -> void:
	talent_panel.visible = state.talent_panel_visible
	for child in talent_box.get_children():
		child.queue_free()
	var tree: Dictionary = state.current_talent_tree()
	var title := _gold_label("%s  Points: %d" % [tree.get("name", "Talents"), int(state.player.get("talents", {}).get("availablePoints", 0))])
	title.add_theme_font_size_override("font_size", 22)
	talent_box.add_child(title)
	var ranks: Dictionary = state.player.get("talents", {}).get("ranks", {})
	for talent in tree.get("nodes", []):
		var rank := int(ranks.get(str(talent.get("id", "")), 0))
		var button := _text_button("%s %d/%d\nLvl %d - %s" % [
			talent.get("name", "Talent"),
			rank,
			int(talent.get("maxRank", 1)),
			int(talent.get("requiredLevel", 1)),
			talent.get("description", ""),
		], "Spend talent point")
		button.custom_minimum_size = Vector2(320, 64)
		button.disabled = not state.can_spend_talent(talent)
		button.pressed.connect(func(id := str(talent.get("id", ""))) -> void: state.spend_talent_point(id))
		talent_box.add_child(button)

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
	for message in state.messages:
		var line := Label.new()
		line.text = str(message.get("text", ""))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 13)
		line.add_theme_color_override("font_color", _message_color(str(message.get("type", "info"))))
		message_box.add_child(line)

func _refresh_inventory() -> void:
	inventory_panel.visible = state.inventory_visible
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
			slot.icon = load(state.display_icon(item))
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
		item_details.text = "[b][color=#f0d680]%s[/color][/b]\n%s\nKnowledge: %s\n\n%s\n\nQuantity: %d%s%s" % [
			state.display_name(selected),
			selected_definition.get("type", "item"),
			selected.get("knowledgeState", "known"),
			state.display_description(selected),
			int(selected.get("quantity", 1)),
			_stats_text(selected_definition.get("stats", {})),
			_discovery_text(selected),
		]

func _refresh_actions() -> void:
	var tile: Dictionary = state.current_tile()
	interact_button.disabled = not state.class_selected or not tile.has("containerId")
	shrine_button.disabled = not state.class_selected or not tile.has("shrineId")
	attack_button.disabled = state.defeated or not state.class_selected
	restart_button.visible = state.defeated or bool(state.zone.get("completed", false))

func _interact() -> void:
	var tile: Dictionary = state.current_tile()
	if tile.has("containerId"):
		state.open_current_container()
	elif tile.has("shrineId"):
		state.activate_current_shrine()
	elif tile.has("encounterId"):
		state.start_encounter(str(tile["encounterId"]))
	else:
		state.add_message("There is nothing to interact with here.", "warning")

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
	var position := _tile_position(tile)
	var player_position: Dictionary = state.player.get("position", {})
	var marker := "You\n" if position.x == int(player_position.get("x", 0)) and position.y == int(player_position.get("y", 0)) else ""
	var suffix := ""
	if tile.has("encounterId") and not state.completed_encounters.has(str(tile["encounterId"])):
		suffix = "\nEnemy"
	elif tile.has("containerId"):
		var container: Dictionary = state.containers_by_id.get(str(tile["containerId"]), {})
		suffix = "\nOpened" if bool(container.get("opened", false)) else "\nChest"
	elif tile.has("shrineId"):
		var shrine: Dictionary = state.shrines_by_id.get(str(tile["shrineId"]), {})
		suffix = "\nSpent" if bool(shrine.get("activated", false)) else "\nShrine"
	return "%s%s%s" % [marker, tile.get("name", "Tile"), suffix]

func _tile_position(tile: Dictionary) -> Vector2i:
	var raw: Array = tile.get("position", [0, 0])
	return Vector2i(int(raw[0]), int(raw[1]))

func _tile_texture(kind: String) -> Texture2D:
	match kind:
		"camp":
			return GrassTileTexture
		"woods":
			return GrassTileTexture
		"chest":
			return ChestTexture
		"shrine":
			return FireRuneTexture
		"ruins":
			return StoneTileTexture
		"gate":
			return IceTileTexture
		"elder_stone":
			return LavaTileTexture
		_:
			return StoneTileTexture

func _tile_style(tile: Dictionary) -> StyleBoxFlat:
	var position := _tile_position(tile)
	var player_position: Dictionary = state.player.get("position", {})
	if position.x == int(player_position.get("x", 0)) and position.y == int(player_position.get("y", 0)):
		return _stylebox(Color(0.18, 0.14, 0.07), Color(0.95, 0.73, 0.30), 3, 5)
	if str(tile.get("state", "")) == "visited":
		return _stylebox(Color(0.13, 0.11, 0.08), Color(0.46, 0.36, 0.20), 2, 5)
	return _stylebox(Color(0.09, 0.085, 0.075), Color(0.28, 0.24, 0.18), 2, 5)

func _move_button(text: String, direction: String) -> Button:
	var button := _text_button(text, "Move %s" % direction)
	button.custom_minimum_size = Vector2(44, 28)
	button.pressed.connect(func() -> void: state.move_player(direction))
	return button

func _text_button(text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(132, 42)
	button.add_theme_stylebox_override("normal", _stylebox(Color(0.15, 0.10, 0.06), Color(0.66, 0.48, 0.22), 2, 5))
	button.add_theme_color_override("font_color", Color(0.95, 0.83, 0.54))
	return button

func _image_button(texture: Texture2D, tooltip: String) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(150, 54)
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.tooltip_text = tooltip
	return button

func _blank_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(44, 28)
	return spacer

func _dark_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.22, 0.14, 0.07))
	return label

func _gold_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.42))
	label.add_theme_font_size_override("font_size", 18)
	return label

func _stylebox(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8
	box.content_margin_top = 7
	box.content_margin_right = 8
	box.content_margin_bottom = 7
	return box

func _equipped_name(instance_id: String) -> String:
	if instance_id == "":
		return "empty"
	var item: Dictionary = state.inventory_item(instance_id)
	if item.is_empty():
		return "empty"
	return state.display_name(item)

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

func _skill_names(skill_ids: Array) -> Array[String]:
	var names: Array[String] = []
	for skill_id in skill_ids:
		names.append(str(state.skills_by_id.get(str(skill_id), {}).get("name", skill_id)))
	return names

func _message_color(type: String) -> Color:
	match type:
		"success":
			return Color(0.12, 0.38, 0.14)
		"warning":
			return Color(0.58, 0.18, 0.08)
		"combat":
			return Color(0.44, 0.08, 0.05)
		"loot":
			return Color(0.34, 0.22, 0.02)
		"discovery":
			return Color(0.18, 0.22, 0.50)
		"curse":
			return Color(0.50, 0.04, 0.16)
		_:
			return Color(0.20, 0.13, 0.07)

func _ensure_inputs() -> void:
	_add_key_action("phase3_move_north", KEY_W)
	_add_key_action("phase3_move_south", KEY_S)
	_add_key_action("phase3_move_west", KEY_A)
	_add_key_action("phase3_move_east", KEY_D)
	_add_key_action("phase3_inventory", KEY_I)
	_add_key_action("phase3_attack", KEY_SPACE)
	_add_key_action("phase3_interact", KEY_E)
	_add_key_action("phase3_talents", KEY_Y)
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
