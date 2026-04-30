extends Node2D

const PlayerScene := preload("res://scripts/player.gd")
const BoneThrallScene := preload("res://scripts/bone_thrall.gd")
const AshWitchScene := preload("res://scripts/ash_witch.gd")
const HollowedBruteScene := preload("res://scripts/hollowed_brute.gd")
const DamageNumberScene := preload("res://scripts/damage_number.gd")
const ItemDatabaseScene := preload("res://scripts/item_database.gd")
const LootDropScene := preload("res://scripts/loot_drop.gd")
const RewardChestScene := preload("res://scripts/reward_chest.gd")
const ItemEchoEffectScene := preload("res://scripts/item_echo_effect.gd")
const DeathEchoScene := preload("res://scripts/death_echo.gd")
const BurningGroundScene := preload("res://scripts/burning_ground.gd")
const ExitPortalScene := preload("res://scripts/exit_portal.gd")
const BossBellRingerScene := preload("res://scripts/boss_bell_ringer.gd")
const EldersTheme := preload("res://assets/ui/theme/elders_theme.tres")
const FloorTexture := preload("res://assets/tiles/ashen_catacombs_floor.png")
const WallTexture := preload("res://assets/tiles/ashen_catacombs_wall.png")
const CrackedFloorTexture := preload("res://assets/tiles/ashen_catacombs_cracked_floor.png")
const BloodMarkTexture := preload("res://assets/tiles/ashen_catacombs_blood_mark.png")

const SAVE_PATH := "user://elders_save.json"

var player: Node2D
var enemies: Array = []
var item_database
var hud: Label
var message: Label
var inventory_panel: PanelContainer
var inventory_label: RichTextLabel
var inventory_visible := false
var reward_chest_spawned := false
var death_echo: Node2D
var haunted_room := false
var death_echo_reclaimed := false
var current_room_index := 0
var room_cleared := false
var dungeon_complete := false
var active_loot_table := ""
var elite_entries: Array[Dictionary] = []
var enemy_definitions := {}
var elite_modifier_definitions := {}
var item_echo_definitions := {}
var death_echo_definition := {}
var dungeon_rooms := [
	{ "id": "entrance", "name": "Entrance", "type": "entrance", "encounter": [] },
	{ "id": "combat_1", "name": "Bone Hall", "type": "combat", "encounter": ["bone_thrall", "bone_thrall"] },
	{ "id": "combat_2", "name": "Ash Gallery", "type": "combat", "encounter": ["bone_thrall", "ash_witch"] },
	{ "id": "combat_3", "name": "Hollow Crossing", "type": "combat", "encounter": ["ash_witch", "hollowed_brute"] },
	{ "id": "elite_1", "name": "Cursed Ossuary", "type": "elite", "encounter": ["bone_thrall", "ash_witch", "hollowed_brute"], "modifiers": ["burning", "vampiric", "echoing"] },
	{ "id": "treasure_1", "name": "Burial Reliquary", "type": "treasure", "encounter": [] },
	{ "id": "boss", "name": "Bell Pit", "type": "boss", "encounter": ["bell_ringer_below"] },
]

func _ready() -> void:
	_ensure_inputs()
	item_database = ItemDatabaseScene.new()
	item_database.load_data()
	_load_enemy_data()
	_load_elite_modifier_data()
	_load_item_echo_data()
	_load_death_echo_data()
	_load_dungeon_data()
	_build_arena()
	_spawn_player()
	_build_hud()
	_start_room(0)

func _load_dungeon_data() -> void:
	var payload := FileAccess.get_file_as_string("res://data/dungeons/ashen_catacombs.json")
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dungeon data must be an object.")
		return
	var rooms: Array = parsed.get("rooms", [])
	if rooms.is_empty():
		push_error("Dungeon data contains no rooms.")
		return
	var loaded_rooms: Array[Dictionary] = []
	for raw_room in rooms:
		if typeof(raw_room) != TYPE_DICTIONARY:
			continue
		var room: Dictionary = raw_room.duplicate(true)
		if not room.has("name"):
			room["name"] = str(room.get("id", "Room")).capitalize()
		if not room.has("encounter"):
			room["encounter"] = []
		loaded_rooms.append(room)
	if not loaded_rooms.is_empty():
		dungeon_rooms = loaded_rooms

func _load_enemy_data() -> void:
	var payload := FileAccess.get_file_as_string("res://data/enemies/enemies.json")
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Enemy data must be an array.")
		return
	for raw_enemy in parsed:
		if typeof(raw_enemy) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = raw_enemy
		var enemy_id := str(enemy.get("id", ""))
		if enemy_id != "":
			enemy_definitions[enemy_id] = enemy.duplicate(true)

func _load_elite_modifier_data() -> void:
	var payload := FileAccess.get_file_as_string("res://data/modifiers/elite_modifiers.json")
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Elite modifier data must be an array.")
		return
	for raw_modifier in parsed:
		if typeof(raw_modifier) != TYPE_DICTIONARY:
			continue
		var modifier: Dictionary = raw_modifier
		var modifier_id := str(modifier.get("id", ""))
		if modifier_id != "":
			elite_modifier_definitions[modifier_id] = modifier.duplicate(true)

func _load_item_echo_data() -> void:
	var payload := FileAccess.get_file_as_string("res://data/echoes/item_echoes.json")
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Item echo data must be an array.")
		return
	for raw_echo in parsed:
		if typeof(raw_echo) != TYPE_DICTIONARY:
			continue
		var echo: Dictionary = raw_echo
		var echo_id := str(echo.get("id", ""))
		if echo_id != "":
			item_echo_definitions[echo_id] = echo.duplicate(true)

func _load_death_echo_data() -> void:
	var payload := FileAccess.get_file_as_string("res://data/echoes/death_echoes.json")
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Death echo data must be an array.")
		return
	for raw_echo in parsed:
		if typeof(raw_echo) != TYPE_DICTIONARY:
			continue
		death_echo_definition = raw_echo.duplicate(true)
		return

func _process(delta: float) -> void:
	_update_elite_modifiers(delta)
	if Input.is_action_just_pressed("restart_arena"):
		if is_instance_valid(player) and not player.alive and is_instance_valid(death_echo):
			player.respawn_at(Vector2(360, 360))
			message.text = "Respawned. Reclaim your Death Echo."
		else:
			get_tree().reload_current_scene()
	if Input.is_action_just_pressed("advance_room") and room_cleared and not dungeon_complete:
		_start_room(current_room_index + 1)
	if Input.is_action_just_pressed("save_game"):
		message.text = _save_game()
	if Input.is_action_just_pressed("load_game"):
		message.text = _load_game()
	if Input.is_action_just_pressed("toggle_inventory"):
		inventory_visible = not inventory_visible
		_update_inventory_panel()
	if Input.is_action_just_pressed("equip_1"):
		player.equip_inventory_index(0)
		_update_inventory_panel()
		_save_game()
	if Input.is_action_just_pressed("equip_2"):
		player.equip_inventory_index(1)
		_update_inventory_panel()
		_save_game()
	if Input.is_action_just_pressed("equip_3"):
		player.equip_inventory_index(2)
		_update_inventory_panel()
		_save_game()
	if Input.is_action_just_pressed("equip_4"):
		player.equip_inventory_index(3)
		_update_inventory_panel()
		_save_game()
	if Input.is_action_just_pressed("unequip_weapon"):
		_unequip_slot("weapon")
	if Input.is_action_just_pressed("unequip_armor"):
		_unequip_slot("armor")
	if Input.is_action_just_pressed("unequip_ring1"):
		_unequip_slot("ring1")
	if Input.is_action_just_pressed("unequip_ring2"):
		_unequip_slot("ring2")
	if Input.is_action_just_pressed("use_consumable"):
		message.text = player.use_first_consumable()
		_update_inventory_panel()
		_save_game()
	if Input.is_action_just_pressed("identify_item"):
		message.text = player.use_identify_scroll()
		_update_inventory_panel()
		_save_game()
	if is_instance_valid(player):
		var room: Dictionary = dungeon_rooms[current_room_index]
		hud.text = "Room %d/%d: %s  Health: %d/%d  Will: %d/%d  Armor: %d  Grave Marks: %d  Scrolls: %d  Enemies: %d%s\nLMB Strike | Q Cleave | E Step %.1f | R Bell %.1f | I Inv | 1-4 Equip | 5-8 Unequip | C Consume | Z ID | N Next | F5 Save | F9 Load | T Restart" % [
			current_room_index + 1,
			dungeon_rooms.size(),
			room["name"],
			player.current_health,
			player.max_health,
			player.current_will,
			player.max_will,
			player.armor,
			player.grave_marks,
			player.identify_scrolls,
			_alive_enemy_count(),
			"  HAUNTED" if haunted_room else "",
			player.grave_step_timer,
			player.bell_timer,
		]

func _build_arena() -> void:
	var floor := ColorRect.new()
	floor.color = Color(0.10, 0.09, 0.08)
	floor.size = Vector2(1280, 720)
	add_child(floor)

	for x in range(80, 1210, 64):
		for y in range(80, 650, 64):
			var texture := FloorTexture
			if (x + y) % 256 == 0:
				texture = CrackedFloorTexture
			_add_texture_sprite(texture, Vector2(x, y), Vector2(64, 64), 0.85)
	_add_texture_sprite(BloodMarkTexture, Vector2(640, 360), Vector2(96, 96), 0.75)
	for x in range(64, 1240, 64):
		_add_texture_sprite(WallTexture, Vector2(x, 48), Vector2(64, 64), 1.0)
		_add_texture_sprite(WallTexture, Vector2(x, 672), Vector2(64, 64), 1.0)
	for y in range(112, 640, 64):
		_add_texture_sprite(WallTexture, Vector2(48, y), Vector2(64, 64), 1.0)
		_add_texture_sprite(WallTexture, Vector2(1232, y), Vector2(64, 64), 1.0)

	var border := Line2D.new()
	border.width = 4
	border.default_color = Color(0.35, 0.30, 0.24)
	border.closed = true
	border.points = PackedVector2Array([
		Vector2(40, 40),
		Vector2(1240, 40),
		Vector2(1240, 680),
		Vector2(40, 680),
	])
	add_child(border)

func _add_texture_sprite(texture: Texture2D, sprite_position: Vector2, size: Vector2, alpha: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = sprite_position
	sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	sprite.modulate = Color(1, 1, 1, alpha)
	add_child(sprite)

func _ensure_inputs() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_mouse_action("basic_attack", MOUSE_BUTTON_LEFT)
	_add_key_action("blood_cleave", KEY_Q)
	_add_key_action("grave_step", KEY_E)
	_add_key_action("bell_of_the_dead", KEY_R)
	_add_key_action("toggle_inventory", KEY_I)
	_add_key_action("equip_1", KEY_1)
	_add_key_action("equip_2", KEY_2)
	_add_key_action("equip_3", KEY_3)
	_add_key_action("equip_4", KEY_4)
	_add_key_action("unequip_weapon", KEY_5)
	_add_key_action("unequip_armor", KEY_6)
	_add_key_action("unequip_ring1", KEY_7)
	_add_key_action("unequip_ring2", KEY_8)
	_add_key_action("use_consumable", KEY_C)
	_add_key_action("identify_item", KEY_Z)
	_add_key_action("advance_room", KEY_N)
	_add_key_action("save_game", KEY_F5)
	_add_key_action("load_game", KEY_F9)
	_add_key_action("restart_arena", KEY_T)

func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)

func _add_mouse_action(action_name: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event := InputEventMouseButton.new()
		event.button_index = button_index
		InputMap.action_add_event(action_name, event)

func _spawn_player() -> void:
	player = PlayerScene.new()
	player.name = "Player"
	player.position = Vector2(360, 360)
	player.damage_dealt.connect(_show_damage)
	player.died.connect(_on_player_died)
	player.basic_attack_hit.connect(_on_player_basic_attack_hit)
	add_child(player)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.zoom = Vector2(1.0, 1.0)
	player.add_child(camera)
	camera.make_current()

func _start_room(room_index: int, should_save := true) -> void:
	if room_index >= dungeon_rooms.size():
		_complete_dungeon()
		return
	_clear_room_nodes()
	current_room_index = room_index
	room_cleared = false
	reward_chest_spawned = false
	var room: Dictionary = dungeon_rooms[current_room_index]
	active_loot_table = str(room.get("lootTable", ""))
	player.global_position = _vector_from_array(room.get("playerStart", [360, 360]), Vector2(360, 360))
	player.enemies = enemies
	match room["type"]:
		"entrance":
			room_cleared = true
			message.text = "The Ashen Catacombs wait. Press N to enter."
		"treasure":
			room_cleared = true
			message.text = "Burial Reliquary. Open the chest, then press N."
			_spawn_reward_chest()
		"boss":
			message.text = "The Bell-Ringer Below descends."
			_spawn_encounter(room)
		_:
			message.text = "%s. Clear the room." % room["name"]
			_spawn_encounter(room)
	if should_save:
		_save_game()

func _clear_room_nodes() -> void:
	for arena_enemy in enemies:
		if is_instance_valid(arena_enemy):
			arena_enemy.queue_free()
	enemies.clear()
	elite_entries.clear()
	for child in get_children():
		if child.get_script() in [LootDropScene, RewardChestScene, ExitPortalScene, BurningGroundScene, ItemEchoEffectScene]:
			child.queue_free()

func _spawn_encounter(room: Dictionary) -> void:
	var spawn_positions := _spawn_points_for_room(room)
	var encounter: Array = room.get("encounter", [])
	var modifiers: Array = room.get("modifiers", [])
	for index in range(encounter.size()):
		var enemy_id := str(encounter[index])
		var modifier := str(room.get("modifier", ""))
		if not modifiers.is_empty():
			modifier = str(modifiers[index % modifiers.size()])
		_spawn_enemy_by_id(enemy_id, spawn_positions[index % spawn_positions.size()], modifier)
	player.enemies = enemies

func _spawn_points_for_room(room: Dictionary) -> Array[Vector2]:
	var fallback: Array[Vector2] = [
		Vector2(850, 275),
		Vector2(980, 470),
		Vector2(760, 510),
		Vector2(930, 260),
	]
	var raw_points: Array = room.get("spawnPoints", [])
	if raw_points.is_empty():
		return fallback
	var points: Array[Vector2] = []
	for raw_point in raw_points:
		points.append(_vector_from_array(raw_point, fallback[points.size() % fallback.size()]))
	return points if not points.is_empty() else fallback

func _vector_from_array(value, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var values: Array = value
	if values.size() < 2:
		return fallback
	return Vector2(float(values[0]), float(values[1]))

func _spawn_enemy_by_id(enemy_id: String, spawn_position: Vector2, modifier := "") -> void:
	match enemy_id:
		"bone_thrall":
			_spawn_enemy(BoneThrallScene, spawn_position, modifier)
		"ash_witch":
			_spawn_enemy(AshWitchScene, spawn_position, modifier)
		"hollowed_brute":
			_spawn_enemy(HollowedBruteScene, spawn_position, modifier)
		"bell_ringer_below":
			_spawn_boss(spawn_position)

func _spawn_enemy(enemy_scene: Script, spawn_position: Vector2, modifier := "") -> void:
	var spawned_enemy: Node2D = enemy_scene.new()
	spawned_enemy.position = spawn_position
	spawned_enemy.target = player
	_apply_enemy_definition(spawned_enemy)
	if haunted_room:
		_apply_haunted_modifier(spawned_enemy)
	if modifier != "":
		_apply_elite_modifier(spawned_enemy, modifier)
	spawned_enemy.damage_dealt.connect(_show_damage)
	spawned_enemy.damage_dealt.connect(func(amount: int, at_position: Vector2, _color: Color) -> void:
		_on_enemy_damage(spawned_enemy, amount, at_position)
	)
	spawned_enemy.died.connect(func() -> void:
		_on_enemy_died(spawned_enemy)
	)
	enemies.append(spawned_enemy)
	add_child(spawned_enemy)

func _apply_enemy_definition(arena_enemy: Node, enemy_id := "") -> void:
	if enemy_id == "":
		enemy_id = _enemy_id_for_node(arena_enemy)
	var definition: Dictionary = enemy_definitions.get(enemy_id, {})
	if definition.is_empty():
		return
	if arena_enemy.get("max_health") != null:
		arena_enemy.set("max_health", int(definition.get("maxHealth", arena_enemy.get("max_health"))))
		arena_enemy.set("current_health", arena_enemy.get("max_health"))
	if arena_enemy.get("attack_damage") != null:
		arena_enemy.set("attack_damage", int(definition.get("attackDamage", arena_enemy.get("attack_damage"))))
	if arena_enemy.get("echo_toll_damage") != null:
		arena_enemy.set("echo_toll_damage", maxi(1, int(roundi(float(definition.get("attackDamage", arena_enemy.get("echo_toll_damage"))) * 0.65))))

func _enemy_id_for_node(arena_enemy: Node) -> String:
	var script: Script = arena_enemy.get_script()
	if script == BoneThrallScene:
		return "bone_thrall"
	if script == AshWitchScene:
		return "ash_witch"
	if script == HollowedBruteScene:
		return "hollowed_brute"
	if script == BossBellRingerScene:
		return "bell_ringer_below"
	return ""

func _spawn_boss(spawn_position: Vector2) -> void:
	var boss := BossBellRingerScene.new()
	boss.position = spawn_position
	boss.target = player
	_apply_enemy_definition(boss, "bell_ringer_below")
	boss.damage_dealt.connect(_show_damage)
	boss.summon_requested.connect(func(spawn_position_requested: Vector2) -> void:
		_spawn_enemy(BoneThrallScene, spawn_position_requested)
		message.text = "The Bell-Ringer calls the buried."
	)
	boss.died.connect(func() -> void:
		_on_enemy_died(boss)
	)
	enemies.append(boss)
	add_child(boss)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 20)
	canvas.add_child(hud)

	message = Label.new()
	message.position = Vector2(360, 300)
	message.add_theme_font_size_override("font_size", 36)
	canvas.add_child(message)

	inventory_panel = PanelContainer.new()
	inventory_panel.theme = EldersTheme
	inventory_panel.position = Vector2(805, 24)
	inventory_panel.size = Vector2(445, 470)
	inventory_panel.visible = false
	canvas.add_child(inventory_panel)

	inventory_label = RichTextLabel.new()
	inventory_label.fit_content = true
	inventory_label.bbcode_enabled = true
	inventory_label.custom_minimum_size = Vector2(420, 440)
	inventory_panel.add_child(inventory_label)

func _show_damage(amount: int, at_position: Vector2, color: Color) -> void:
	var number := DamageNumberScene.new()
	number.text = str(amount)
	number.position = at_position
	number.modulate = color
	add_child(number)

func _on_player_died() -> void:
	_create_death_echo(player.global_position)
	message.text = "You died. A Death Echo haunts the room. Press T to respawn."
	_save_game()

func _on_enemy_died(enemy: Node2D) -> void:
	var enemy_position := enemy.global_position
	_drop_loot_near_enemy(enemy_position)
	player.grave_marks += randi_range(3, 8)
	if randf() < 0.35:
		player.identify_scrolls += 1
	var xp_award := 10
	if _elite_modifier_for(enemy) != "":
		xp_award = 25
	if enemy.get_script() == BossBellRingerScene:
		xp_award = 50
	var reveal_messages: Array[String] = player.award_attunement_xp(xp_award)
	var echo_messages: Array[String] = _trigger_item_echoes(enemy_position)
	if not reveal_messages.is_empty():
		message.text = reveal_messages[0]
	elif not echo_messages.is_empty():
		message.text = echo_messages[0]
	if _alive_enemy_count() == 0:
		player.identify_scrolls += 1
		_complete_current_room()
	elif reveal_messages.is_empty() and echo_messages.is_empty():
		message.text = "%d enemies remain." % _alive_enemy_count()
	_save_game()

func _alive_enemy_count() -> int:
	var count := 0
	for arena_enemy in enemies:
		if is_instance_valid(arena_enemy) and arena_enemy.alive:
			count += 1
	return count

func _drop_loot_near_enemy(enemy_position: Vector2) -> void:
	var item: Dictionary = item_database.random_loot_item(active_loot_table)
	if item.is_empty():
		return
	var drop := LootDropScene.new()
	drop.item = item
	drop.global_position = enemy_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))
	drop.picked_up.connect(func(picked_item: Dictionary) -> void:
		message.text = "Picked up %s. Press I, then 1-4 to equip." % picked_item.get("name", "item")
		_update_inventory_panel()
	)
	add_child(drop)

func _spawn_reward_chest() -> void:
	if reward_chest_spawned:
		return
	reward_chest_spawned = true
	var chest := RewardChestScene.new()
	chest.global_position = Vector2(640, 360)
	chest.opened.connect(func(at_position: Vector2) -> void:
		var reward_items := _reward_items_for_current_room()
		if reward_items.is_empty():
			reward_items = [item_database.random_loot_item(active_loot_table), item_database.random_loot_item(active_loot_table)]
		for index in range(reward_items.size()):
			_drop_item_dict(reward_items[index], at_position + Vector2(-30 + (index * 30), 0), "Picked up %s. Press I, then 1-4 to equip.")
		message.text = "Reward chest opened."
	)
	add_child(chest)

func _complete_current_room() -> void:
	var room: Dictionary = dungeon_rooms[current_room_index]
	room_cleared = true
	if room["type"] == "boss":
		var reward_item_ids := _reward_item_ids_for_room(room)
		for index in range(reward_item_ids.size()):
			var item_id: String = str(reward_item_ids[index])
			_drop_specific_item(str(item_id), Vector2(610 + (index * 45), 360))
		_spawn_reward_chest()
		_complete_dungeon(true)
	elif room["type"] == "elite":
		message.text = "Elite room cleared. Press N to continue."
	else:
		message.text = "%s cleared. Press N to continue." % room["name"]

func _drop_specific_item(item_id: String, drop_position: Vector2) -> void:
	var item: Dictionary = item_database.get_item(item_id)
	if item.is_empty():
		return
	_drop_item_dict(item, drop_position, "Picked up %s.")

func _drop_item_dict(item: Dictionary, drop_position: Vector2, pickup_message: String) -> void:
	if item.is_empty():
		return
	var drop := LootDropScene.new()
	drop.item = item
	drop.global_position = drop_position
	drop.picked_up.connect(func(picked_item: Dictionary) -> void:
		message.text = pickup_message % picked_item.get("name", "item")
		_update_inventory_panel()
	)
	add_child(drop)

func _reward_item_ids_for_room(room: Dictionary) -> Array:
	return room.get("rewardDrops", [])

func _reward_items_for_current_room() -> Array[Dictionary]:
	var room: Dictionary = dungeon_rooms[current_room_index]
	var reward_items: Array[Dictionary] = []
	for item_id in _reward_item_ids_for_room(room):
		var item: Dictionary = item_database.get_item(str(item_id))
		if not item.is_empty():
			reward_items.append(item)
	return reward_items

func _complete_dungeon(grant_rewards := false) -> void:
	dungeon_complete = true
	room_cleared = true
	if grant_rewards:
		player.grave_marks += 50
		player.identify_scrolls += 1
	var portal := ExitPortalScene.new()
	portal.global_position = Vector2(1120, 360)
	portal.entered.connect(func() -> void:
		message.text = "Dungeon complete. Rewards secured."
		_save_game()
	)
	add_child(portal)
	message.text = "The Bell-Ringer Below is defeated. Exit portal opened."
	_save_game()

func _apply_elite_modifier(arena_enemy: Node, modifier: String) -> void:
	var definition: Dictionary = elite_modifier_definitions.get(modifier, {})
	var damage_multiplier := float(definition.get("damageMultiplier", 1.25))
	var speed_multiplier := float(definition.get("speedMultiplier", 1.08))
	var health_multiplier := float(definition.get("healthMultiplier", 1.5))
	if arena_enemy.has_method("apply_haunted_modifier"):
		arena_enemy.apply_haunted_modifier(damage_multiplier, speed_multiplier)
	if arena_enemy.get("max_health") != null:
		arena_enemy.set("max_health", int(roundi(float(arena_enemy.get("max_health")) * health_multiplier)))
		arena_enemy.set("current_health", arena_enemy.get("max_health"))
	arena_enemy.modulate = _elite_color(modifier, definition)
	elite_entries.append({ "enemy": arena_enemy, "modifier": modifier, "definition": definition, "timer": 0.0 })

func _elite_color(modifier: String, definition: Dictionary = {}) -> Color:
	var color_values: Array = definition.get("color", [])
	if color_values.size() >= 3:
		return Color(float(color_values[0]), float(color_values[1]), float(color_values[2]))
	match modifier:
		"burning":
			return Color(1.0, 0.55, 0.25)
		"vampiric":
			return Color(1.0, 0.25, 0.35)
		"echoing":
			return Color(0.55, 0.75, 1.0)
		_:
			return Color(1.0, 1.0, 1.0)

func _update_elite_modifiers(delta: float) -> void:
	for entry in elite_entries:
		var arena_enemy: Node = entry["enemy"]
		if not is_instance_valid(arena_enemy) or not arena_enemy.alive:
			continue
		var definition: Dictionary = entry.get("definition", {})
		var ground_effect: Dictionary = definition.get("groundEffect", {})
		if not ground_effect.get("enabled", false):
			continue
		entry["timer"] = float(entry["timer"]) - delta
		if entry["timer"] <= 0.0:
			entry["timer"] = float(ground_effect.get("intervalSeconds", 2.0))
			var ground := BurningGroundScene.new()
			ground.global_position = arena_enemy.global_position
			ground.player = player
			ground.damage = int(ground_effect.get("damage", 4))
			ground.radius = float(ground_effect.get("radius", 34.0))
			ground.damage_dealt.connect(_show_damage)
			add_child(ground)

func _on_enemy_damage(source_enemy: Node, amount: int, at_position: Vector2) -> void:
	var modifier := _elite_modifier_for(source_enemy)
	var definition := _elite_definition_for(source_enemy)
	if modifier == "vampiric" and source_enemy.get("current_health") != null:
		var life_steal := float(definition.get("lifeStealPercent", 35)) / 100.0
		source_enemy.set("current_health", mini(source_enemy.get("max_health"), source_enemy.get("current_health") + int(roundi(float(amount) * life_steal))))
	elif modifier == "echoing":
		var echo_percent := float(definition.get("echoDamagePercent", 50)) / 100.0
		var echo_delay := float(definition.get("echoDelaySeconds", 0.35))
		_repeat_echo_damage(source_enemy, maxi(1, int(roundi(float(amount) * echo_percent))), at_position, echo_delay)

func _elite_modifier_for(source_enemy: Node) -> String:
	for entry in elite_entries:
		if entry["enemy"] == source_enemy:
			return str(entry["modifier"])
	return ""

func _elite_definition_for(source_enemy: Node) -> Dictionary:
	for entry in elite_entries:
		if entry["enemy"] == source_enemy:
			return entry.get("definition", {})
	return {}

func _repeat_echo_damage(source_enemy: Node, amount: int, at_position: Vector2, delay_seconds := 0.35) -> void:
	await get_tree().create_timer(delay_seconds).timeout
	if is_instance_valid(source_enemy) and source_enemy.alive and is_instance_valid(player) and player.alive:
		player.take_damage(amount)
		_show_damage(amount, at_position + Vector2(16, -12), Color(0.55, 0.85, 1.0))

func _save_game() -> String:
	if not is_instance_valid(player):
		return "No player state to save."
	var save_data := {
		"version": 1,
		"currentRoomIndex": current_room_index,
		"roomCleared": room_cleared,
		"dungeonComplete": dungeon_complete,
		"hauntedRoom": haunted_room,
		"deathEchoReclaimed": death_echo_reclaimed,
		"deathEchoPosition": _death_echo_position_for_save(),
		"player": player.serialize_state(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return "Save failed: %s" % FileAccess.get_open_error()
	file.store_string(JSON.stringify(save_data, "\t"))
	return "Game saved."

func _load_game() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return "No save file found."
	var payload := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Save file is invalid."
	var room_index := clampi(int(parsed.get("currentRoomIndex", 0)), 0, dungeon_rooms.size() - 1)
	_start_room(room_index, false)
	player.restore_state(parsed.get("player", {}))
	room_cleared = bool(parsed.get("roomCleared", room_cleared))
	dungeon_complete = bool(parsed.get("dungeonComplete", false))
	haunted_room = bool(parsed.get("hauntedRoom", false))
	death_echo_reclaimed = bool(parsed.get("deathEchoReclaimed", true))
	if haunted_room and not death_echo_reclaimed:
		var position_data: Array = parsed.get("deathEchoPosition", [player.global_position.x, player.global_position.y])
		if position_data.size() < 2:
			position_data = [player.global_position.x, player.global_position.y]
		_create_death_echo(Vector2(float(position_data[0]), float(position_data[1])))
	if dungeon_complete:
		_complete_dungeon(false)
	_update_inventory_panel()
	return "Game loaded."

func _unequip_slot(slot: String) -> void:
	player.unequip(slot)
	_update_inventory_panel()
	_save_game()

func _death_echo_position_for_save() -> Array:
	if is_instance_valid(death_echo):
		return [death_echo.global_position.x, death_echo.global_position.y]
	return []

func _trigger_item_echoes(enemy_position: Vector2) -> Array[String]:
	var messages: Array[String] = []
	for slot in player.equipped.keys():
		var item: Dictionary = player.equipped[slot]
		if item.is_empty():
			continue
		for echo_id in item.get("revealedEchoes", []):
			if str(echo_id) == "echo_last_duel":
				continue
			if randf() > 0.65:
				continue
			var effect := ItemEchoEffectScene.new()
			effect.global_position = enemy_position
			effect.configure(str(echo_id), player, enemies, item_echo_definitions.get(str(echo_id), {}))
			effect.damage_dealt.connect(_show_damage)
			add_child(effect)
			effect.apply_instant()
			messages.append("%s triggers %s." % [item.get("name", "An item"), echo_id])
	return messages

func _on_player_basic_attack_hit(target: Node2D, amount: int, at_position: Vector2) -> void:
	for slot in player.equipped.keys():
		var item: Dictionary = player.equipped[slot]
		if item.is_empty():
			continue
		if not item.get("revealedEchoes", []).has("echo_last_duel"):
			continue
		_apply_last_duel(target, amount, at_position, item_echo_definitions.get("echo_last_duel", {}))
		message.text = "%s triggers Last Duel." % item.get("name", "An item")
		return

func _apply_last_duel(target: Node2D, amount: int, at_position: Vector2, definition: Dictionary) -> void:
	var effect_data: Dictionary = definition.get("effect", {})
	var delay_seconds := float(effect_data.get("delaySeconds", 0.25))
	var damage_multiplier := float(effect_data.get("damageMultiplier", 0.45))
	await get_tree().create_timer(delay_seconds).timeout
	if not is_instance_valid(target) or not target.alive:
		return
	var echo_damage := maxi(1, int(roundi(float(amount) * damage_multiplier)))
	target.take_damage(echo_damage)
	_show_damage(echo_damage, at_position + Vector2(18, -42), Color(0.72, 0.86, 1.0))
	var effect := ItemEchoEffectScene.new()
	effect.global_position = at_position
	effect.configure("echo_last_duel", player, enemies, definition)
	add_child(effect)

func _create_death_echo(death_position: Vector2) -> void:
	if is_instance_valid(death_echo):
		death_echo.queue_free()
	haunted_room = true
	death_echo_reclaimed = false
	death_echo = DeathEchoScene.new()
	death_echo.global_position = death_position
	death_echo.reclaimed.connect(_on_death_echo_reclaimed)
	add_child(death_echo)
	for arena_enemy in enemies:
		if is_instance_valid(arena_enemy) and arena_enemy.alive:
			_apply_haunted_modifier(arena_enemy)

func _apply_haunted_modifier(arena_enemy: Node) -> void:
	if arena_enemy.has_method("apply_haunted_modifier"):
		var damage_multiplier := 1.0
		var speed_multiplier := 1.0
		for effect in death_echo_definition.get("effectsUntilReclaimed", []):
			match str(effect.get("stat", "")):
				"damage_percent":
					damage_multiplier += float(effect.get("value", 0)) / 100.0
				"movement_speed_percent":
					speed_multiplier += float(effect.get("value", 0)) / 100.0
		arena_enemy.apply_haunted_modifier(damage_multiplier, speed_multiplier)

func _on_death_echo_reclaimed() -> void:
	if death_echo_reclaimed:
		return
	death_echo_reclaimed = true
	haunted_room = false
	var reward: Dictionary = death_echo_definition.get("reclaimReward", {})
	var messages: Array[String] = player.award_attunement_xp(int(reward.get("attunementXp", 25)))
	message.text = "Death Echo reclaimed. Attunement surges."
	if not messages.is_empty():
		message.text = messages[0]
	_save_game()

func _update_inventory_panel() -> void:
	inventory_panel.visible = inventory_visible
	if not inventory_visible:
		return
	var lines: Array[String] = []
	lines.append("[b]Equipment[/b]")
	lines.append(_equipment_line("Weapon", "weapon"))
	lines.append(_equipment_line("Armor", "armor"))
	lines.append(_equipment_line("Ring 1", "ring1"))
	lines.append(_equipment_line("Ring 2", "ring2"))
	lines.append("")
	lines.append("Equip inventory: 1-4   Unequip slots: 5 Weapon, 6 Armor, 7 Ring 1, 8 Ring 2   Use consumable: C")
	lines.append("Identify Scrolls: %d  (press Z to reveal first unknown property)" % player.identify_scrolls)
	lines.append("")
	lines.append("[b]Inventory[/b]")
	if player.inventory.is_empty():
		lines.append("No items. Kill enemies for drops.")
	else:
		for index in range(player.inventory.size()):
			var item: Dictionary = player.inventory[index]
			lines.append("%d. %s" % [index + 1, _tooltip(item)])
	inventory_label.text = "\n".join(lines)

func _equipment_line(label: String, slot: String) -> String:
	var item: Dictionary = player.equipped[slot]
	if item.is_empty():
		return "%s: empty" % label
	return "%s: %s" % [label, _tooltip(item)]

func _tooltip(item: Dictionary) -> String:
	var stats: Array[String] = []
	for stat in item.get("visibleStats", []):
		stats.append("%s %+d" % [str(stat.get("stat", "")), int(stat.get("value", 0))])
	for stat in item.get("revealedHiddenStats", []):
		stats.append("%s %+d" % [str(stat.get("stat", "")), int(stat.get("value", 0))])
	var hidden_slots: int = item.get("hiddenStats", []).size() - item.get("revealedHiddenStats", []).size()
	for _index in range(hidden_slots):
		stats.append("????")
	var soul_text := _soul_text(item)
	var curse_text := _curse_text(item)
	var echo_text := _echo_text(item)
	var attunement_text := _attunement_text(item)
	return "[color=%s]%s[/color] (%s %s) — %s%s%s%s%s" % [
		_rarity_hex(str(item.get("rarity", "worn"))),
		item.get("name", "Unknown Item"),
		item.get("rarity", "worn"),
		item.get("type", "item"),
		", ".join(stats),
		attunement_text,
		soul_text,
		curse_text,
		echo_text,
	]

func _attunement_text(item: Dictionary) -> String:
	var attunement: Dictionary = item.get("attunement", {})
	if not attunement.get("enabled", false):
		return ""
	return " | Attune %d/%d XP %d" % [
		int(attunement.get("level", 0)),
		int(attunement.get("maxLevel", 5)),
		int(attunement.get("xp", 0)),
	]

func _soul_text(item: Dictionary) -> String:
	if not item.has("soul"):
		return ""
	if not item.get("soulRevealed", false):
		return " | Soul: ????"
	var soul: Dictionary = item["soul"]
	var whispers: Array = soul.get("whispers", [])
	var whisper := ""
	if not whispers.is_empty():
		whisper = " \"%s\"" % whispers[0]
	return " | Soul: %s/%s%s" % [soul.get("name", "unknown"), soul.get("school", "unknown"), whisper]

func _curse_text(item: Dictionary) -> String:
	if item.get("curse", null) == null:
		return ""
	if not item.get("curseRevealed", false):
		return " | Curse: ????"
	var curse: Dictionary = item["curse"]
	return " | Curse: %s" % curse.get("id", "unknown")

func _echo_text(item: Dictionary) -> String:
	var echoes: Array = item.get("echoes", [])
	if echoes.is_empty():
		return ""
	var revealed: Array = item.get("revealedEchoes", [])
	if revealed.is_empty():
		return " | Echo: ????"
	return " | Echo: %s" % ", ".join(revealed)

func _rarity_hex(rarity: String) -> String:
	match rarity:
		"forged":
			return "#59bff2"
		"relic":
			return "#b373ff"
		"accursed":
			return "#f23359"
		_:
			return "#c7bea0"
