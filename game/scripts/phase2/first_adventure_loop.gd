extends Control

const Phase2State := preload("res://scripts/phase2/phase2_state.gd")
const TitlePlaqueTexture := preload("res://assets/ui/title_plaque.png")
const AttackButtonTexture := preload("res://assets/ui/button_attack.png")
const InventoryButtonTexture := preload("res://assets/ui/button_inventory.png")
const QuestButtonTexture := preload("res://assets/ui/button_quests.png")
const ParchmentTexture := preload("res://assets/ui/parchment_panel.png")
const InventoryPanelTexture := preload("res://assets/ui/inventory_panel.png")
const HealthBarTexture := preload("res://assets/ui/health_bar_frame.png")
const ManaBarTexture := preload("res://assets/ui/mana_bar_frame.png")
const GrassTileTexture := preload("res://assets/terrain/grass_tile.png")
const StoneTileTexture := preload("res://assets/terrain/stone_tile.png")
const ChestTexture := preload("res://assets/items/chest.png")
const SwordTexture := preload("res://assets/items/sword.png")
const GoldTexture := preload("res://assets/items/gold_coins.png")
const PotionTexture := preload("res://assets/items/potion_blue.png")
const ScoutTexture := preload("res://assets/portraits/elf_scout.png")

var state
var root_margin: MarginContainer
var health_label: Label
var mana_label: Label
var gold_label: Label
var quest_title: Label
var quest_description: Label
var objective_list: VBoxContainer
var message_log: VBoxContainer
var inventory_panel: PanelContainer
var inventory_grid: GridContainer
var item_details: RichTextLabel
var chest_button: TextureButton
var chest_label: Label
var enemy_button: TextureButton
var enemy_label: Label
var enemy_health_bar: ProgressBar
var attack_button: TextureButton
var inventory_button: TextureButton
var quest_button: TextureButton
var quest_panel: PanelContainer

func _ready() -> void:
	custom_minimum_size = Vector2(960, 640)
	state = Phase2State.new()
	state.state_changed.connect(_refresh)
	state.reset()
	_build_screen()
	_refresh()

func _build_screen() -> void:
	_add_background()
	root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 18)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(root_margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	root_margin.add_child(main)

	main.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	main.add_child(body)

	body.add_child(_build_play_area())
	quest_panel = _build_status_panel()
	body.add_child(quest_panel)

	main.add_child(_build_action_bar())
	inventory_panel = _build_inventory_panel()
	inventory_panel.visible = false
	add_child(inventory_panel)

func _add_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.055, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 90)
	header.add_theme_constant_override("separation", 18)

	var logo := TextureRect.new()
	logo.texture = TitlePlaqueTexture
	logo.custom_minimum_size = Vector2(300, 86)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(logo)

	var parchment := _texture_panel(ParchmentTexture)
	parchment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	parchment.add_child(title_box)
	var title := Label.new()
	title.text = "First Courage"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.20, 0.12, 0.05))
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Open the chest. Take the blade. Face the road scout."
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.25, 0.17, 0.09))
	title_box.add_child(subtitle)
	header.add_child(parchment)
	return header

func _build_play_area() -> Control:
	var play_frame := PanelContainer.new()
	play_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_frame.add_theme_stylebox_override("panel", _stylebox(Color(0.09, 0.075, 0.055), Color(0.48, 0.38, 0.22), 3, 8))

	var field := Control.new()
	field.custom_minimum_size = Vector2(560, 390)
	play_frame.add_child(field)

	for x in range(0, 7):
		for y in range(0, 5):
			var tile := TextureRect.new()
			tile.texture = GrassTileTexture if (x + y) % 3 == 0 else StoneTileTexture
			tile.position = Vector2(18 + x * 82, 24 + y * 70)
			tile.size = Vector2(96, 64)
			tile.modulate = Color(0.76, 0.76, 0.70, 0.72)
			field.add_child(tile)

	chest_button = TextureButton.new()
	chest_button.texture_normal = ChestTexture
	chest_button.texture_hover = ChestTexture
	chest_button.texture_pressed = ChestTexture
	chest_button.position = Vector2(130, 230)
	chest_button.custom_minimum_size = Vector2(96, 64)
	chest_button.focus_mode = Control.FOCUS_ALL
	chest_button.tooltip_text = "Open abandoned chest"
	chest_button.pressed.connect(state.open_chest)
	field.add_child(chest_button)

	chest_label = _scene_label("Abandoned Chest", Vector2(94, 298))
	field.add_child(chest_label)

	enemy_button = TextureButton.new()
	enemy_button.texture_normal = ScoutTexture
	enemy_button.texture_hover = ScoutTexture
	enemy_button.texture_pressed = ScoutTexture
	enemy_button.position = Vector2(405, 150)
	enemy_button.custom_minimum_size = Vector2(128, 128)
	enemy_button.focus_mode = Control.FOCUS_ALL
	enemy_button.tooltip_text = "Target scout"
	enemy_button.pressed.connect(func() -> void: state.select_enemy("ash_road_scout"))
	field.add_child(enemy_button)

	enemy_label = _scene_label("", Vector2(390, 280))
	field.add_child(enemy_label)
	enemy_health_bar = ProgressBar.new()
	enemy_health_bar.position = Vector2(390, 315)
	enemy_health_bar.size = Vector2(160, 20)
	enemy_health_bar.show_percentage = false
	field.add_child(enemy_health_bar)
	return play_frame

func _build_status_panel() -> PanelContainer:
	var panel := _texture_panel(ParchmentTexture)
	panel.custom_minimum_size = Vector2(330, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	health_label = _dark_label("")
	mana_label = _dark_label("")
	gold_label = _dark_label("")
	stats.add_child(health_label)
	stats.add_child(mana_label)
	stats.add_child(gold_label)
	box.add_child(stats)

	quest_title = _dark_label("")
	quest_title.add_theme_font_size_override("font_size", 22)
	box.add_child(quest_title)
	quest_description = _dark_label("")
	quest_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(quest_description)
	objective_list = VBoxContainer.new()
	objective_list.add_theme_constant_override("separation", 3)
	box.add_child(objective_list)

	var log_title := _dark_label("Messages")
	log_title.add_theme_font_size_override("font_size", 18)
	box.add_child(log_title)
	message_log = VBoxContainer.new()
	message_log.add_theme_constant_override("separation", 3)
	box.add_child(message_log)
	return panel

func _build_action_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 82)
	bar.add_theme_constant_override("separation", 12)

	bar.add_child(_resource_bar(HealthBarTexture, "Health", Color(0.75, 0.05, 0.04)))
	bar.add_child(_resource_bar(ManaBarTexture, "Mana", Color(0.08, 0.42, 0.85)))
	quest_button = _image_button(QuestButtonTexture, "Focus quest tracker")
	quest_button.pressed.connect(func() -> void: quest_panel.grab_focus())
	bar.add_child(quest_button)
	attack_button = _image_button(AttackButtonTexture, "Attack selected enemy")
	attack_button.pressed.connect(state.attack_selected_enemy)
	bar.add_child(attack_button)
	inventory_button = _image_button(InventoryButtonTexture, "Toggle inventory")
	inventory_button.pressed.connect(state.toggle_inventory)
	bar.add_child(inventory_button)
	return bar

func _build_inventory_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(250, 105)
	panel.size = Vector2(560, 420)
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.055, 0.045, 0.035, 0.96), Color(0.68, 0.52, 0.24), 3, 8))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.43))
	box.add_child(title)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	box.add_child(content)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(inventory_grid)

	item_details = RichTextLabel.new()
	item_details.bbcode_enabled = true
	item_details.custom_minimum_size = Vector2(210, 260)
	item_details.fit_content = true
	content.add_child(item_details)
	return panel

func _refresh() -> void:
	if health_label == null:
		return
	health_label.text = "Health: %d / %d" % [state.player.get("health", 0), state.player.get("maxHealth", 0)]
	mana_label.text = "Mana: %d / %d" % [state.player.get("mana", 0), state.player.get("maxMana", 0)]
	gold_label.text = "Gold: %d" % state.player.get("gold", 0)
	_refresh_quest()
	_refresh_messages()
	_refresh_scene_objects()
	_refresh_inventory()

func _refresh_quest() -> void:
	quest_title.text = str(state.quest.get("title", "Quest"))
	quest_description.text = str(state.quest.get("description", ""))
	for child in objective_list.get_children():
		child.queue_free()
	for objective in state.quest.get("objectives", []):
		var done := bool(objective.get("completed", false))
		var line := _dark_label("%s %s" % ["[x]" if done else "[ ]", objective.get("label", "")])
		line.add_theme_color_override("font_color", Color(0.10, 0.34, 0.13) if done else Color(0.25, 0.17, 0.09))
		objective_list.add_child(line)

func _refresh_messages() -> void:
	for child in message_log.get_children():
		child.queue_free()
	for message in state.messages:
		var line := Label.new()
		line.text = str(message.get("text", ""))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 14)
		line.add_theme_color_override("font_color", _message_color(str(message.get("type", "info"))))
		message_log.add_child(line)

func _refresh_scene_objects() -> void:
	chest_button.disabled = state.chest_state == "opened"
	chest_button.modulate = Color(0.72, 0.70, 0.66, 0.9) if chest_button.disabled else Color.WHITE
	chest_label.text = "Opened Chest" if chest_button.disabled else "Abandoned Chest"

	enemy_label.text = "%s%s" % [
		state.enemy.get("name", "Enemy"),
		" - defeated" if bool(state.enemy.get("defeated", false)) else "",
	]
	enemy_health_bar.max_value = float(state.enemy.get("maxHealth", 1))
	enemy_health_bar.value = float(state.enemy.get("health", 0))
	enemy_button.disabled = bool(state.enemy.get("defeated", false))
	if bool(state.enemy.get("defeated", false)):
		enemy_button.modulate = Color(0.35, 0.35, 0.35, 0.75)
	elif state.selected_enemy_id == state.enemy.get("id", ""):
		enemy_button.modulate = Color(1.0, 0.82, 0.44, 1.0)
	else:
		enemy_button.modulate = Color.WHITE

func _refresh_inventory() -> void:
	inventory_panel.visible = state.inventory_visible
	for child in inventory_grid.get_children():
		child.queue_free()
	var inventory: Array = state.player.get("inventory", [])
	for index in range(20):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(54, 54)
		slot.focus_mode = Control.FOCUS_ALL
		slot.add_theme_stylebox_override("normal", _stylebox(Color(0.10, 0.085, 0.065), Color(0.42, 0.33, 0.18), 2, 4))
		slot.add_theme_stylebox_override("hover", _stylebox(Color(0.16, 0.13, 0.09), Color(0.80, 0.62, 0.28), 2, 4))
		if index < inventory.size():
			var item: Dictionary = inventory[index]
			slot.icon = load(str(item.get("icon", "")))
			slot.text = "x%d" % int(item.get("quantity", 1))
			slot.tooltip_text = str(item.get("name", "Item"))
			slot.pressed.connect(func(item_id := str(item.get("id", ""))) -> void: state.select_inventory_item(item_id))
		inventory_grid.add_child(slot)
	var selected: Dictionary = state.selected_item()
	if selected.is_empty():
		item_details.text = "[color=#e8d39c]Select an item.[/color]"
	else:
		item_details.text = "[b][color=#f0d680]%s[/color][/b]\n%s\n\n%s\n\nQuantity: %d" % [
			selected.get("name", "Item"),
			selected.get("type", "item"),
			selected.get("description", ""),
			int(selected.get("quantity", 1)),
		]

func _image_button(texture: Texture2D, tooltip: String) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(180, 58)
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.tooltip_text = tooltip
	return button

func _resource_bar(texture: Texture2D, label_text: String, color: Color) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(210, 58)
	var frame := TextureRect.new()
	frame.texture = texture
	frame.position = Vector2.ZERO
	frame.size = Vector2(210, 34)
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(frame)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = Vector2(22, 9)
	fill.size = Vector2(150, 13)
	box.add_child(fill)
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(62, 34)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.64))
	box.add_child(label)
	return box

func _texture_panel(texture: Texture2D) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(Color(0.80, 0.64, 0.38, 0.88), Color(0.45, 0.29, 0.12), 2, 8))
	return panel

func _dark_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.25, 0.17, 0.09))
	return label

func _scene_label(text: String, scene_position: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = scene_position
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.60))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _stylebox(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_top = 8
	box.content_margin_right = 10
	box.content_margin_bottom = 8
	return box

func _message_color(type: String) -> Color:
	match type:
		"success":
			return Color(0.15, 0.42, 0.18)
		"warning":
			return Color(0.58, 0.18, 0.08)
		"combat":
			return Color(0.45, 0.08, 0.06)
		"loot":
			return Color(0.35, 0.23, 0.02)
		_:
			return Color(0.22, 0.16, 0.10)
