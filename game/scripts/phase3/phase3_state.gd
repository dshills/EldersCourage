extends RefCounted

signal state_changed

const RingSouls := preload("res://scripts/phase8/ring_souls.gd")
const ItemResonance := preload("res://scripts/phase9/item_resonance.gd")
const MAX_MESSAGES := 10

var items_by_id := {}
var ring_souls_by_id := {}
var item_resonances_by_id := {}
var enemies_by_id := {}
var loot_tables_by_id := {}
var containers_by_id := {}
var shrines_by_id := {}
var classes_by_id := {}
var skills_by_id := {}
var talent_trees_by_id := {}
var zone := {}
var quest_chain := {}
var player := {}
var messages: Array[Dictionary] = []
var active_enemy := {}
var selected_item_id := ""
var selected_skill_id := ""
var inventory_visible := false
var talent_panel_visible := false
var ui := { "activePanel": "", "debugMode": false, "selectedTileId": "", "lastAnimation": {} }
var completed_encounters := {}
var completion_reward_claimed := false
var defeated := false
var class_selected := false
var selected_class_id := ""
var temporary_modifiers: Array[Dictionary] = []
var next_item_instance_number := 1
var inventory_interaction := { "mode": "normal", "sourceItemInstanceId": "" }
var turn_number := 0
var resonance := {}

func reset() -> void:
	items_by_id = _load_records_by_id("res://data/phase3/items.json")
	var starter_items := _load_records_by_id("res://data/phase4/starter_items.json")
	for item_id in starter_items.keys():
		items_by_id[item_id] = starter_items[item_id]
	var phase5_items := _load_records_by_id("res://data/phase5/items.json")
	for item_id in phase5_items.keys():
		items_by_id[item_id] = phase5_items[item_id]
	ring_souls_by_id = _load_records_by_id("res://data/phase8/ring_souls.json")
	item_resonances_by_id = _load_records_by_id("res://data/phase9/item_resonances.json")
	enemies_by_id = _load_records_by_id("res://data/phase3/enemies.json")
	loot_tables_by_id = _load_records_by_id("res://data/phase3/loot_tables.json")
	containers_by_id = _load_records_by_id("res://data/phase3/containers.json")
	shrines_by_id = _load_records_by_id("res://data/phase3/shrines.json")
	classes_by_id = _load_records_by_id("res://data/phase4/classes.json")
	skills_by_id = _load_records_by_id("res://data/phase4/skills.json")
	talent_trees_by_id = _load_records_by_id("res://data/phase4/talents.json")
	_reset_world()
	class_selected = false
	selected_class_id = ""
	player["classId"] = ""
	messages.clear()
	add_message("Choose a class to begin the Elder Road.", "info")

func start_class(class_id: String) -> void:
	if not classes_by_id.has(class_id):
		add_message("Unknown class.", "warning")
		return
	_reset_world()
	var class_definition: Dictionary = classes_by_id[class_id]
	class_selected = true
	selected_class_id = class_id
	player["classId"] = class_id
	player["name"] = class_definition.get("name", "The Wanderer")
	player["level"] = 1
	player["xp"] = 0
	player["xpToNextLevel"] = 50
	player["maxHealth"] = int(class_definition.get("startingHealth", 100))
	player["maxMana"] = int(class_definition.get("startingMana", 40))
	player["health"] = int(player["maxHealth"])
	player["mana"] = int(player["maxMana"])
	player["gold"] = int(class_definition.get("startingGold", 0))
	player["baseStats"] = class_definition.get("baseStats", {}).duplicate(true)
	player["skills"] = { "knownSkillIds": class_definition.get("startingSkillIds", []).duplicate(true), "cooldowns": {} }
	player["talents"] = { "availablePoints": 0, "spentPoints": 0, "ranks": {} }
	player["talentTreeId"] = str(class_definition.get("talentTreeId", ""))
	for item_id in class_definition.get("startingItemIds", []):
		_grant_starting_item(str(item_id))
	player["health"] = effective_max_health()
	player["mana"] = effective_max_mana()
	messages.clear()
	add_message(str(class_definition.get("startMessage", "Your journey begins.")), "success")
	add_message("Elder Road Outskirts opens before you.", "info")
	state_changed.emit()

func _reset_world() -> void:
	zone = _load_record("res://data/phase3/zone_elder_road_outskirts.json")
	quest_chain = _load_record("res://data/phase3/quest_chain.json")
	player = {
		"name": "The Wanderer",
		"level": 1,
		"xp": 0,
		"xpToNextLevel": 50,
		"health": 100,
		"maxHealth": 100,
		"mana": 40,
		"maxMana": 40,
		"gold": 0,
		"baseStats": { "strength": 1, "defense": 1, "spellPower": 0, "maxHealthBonus": 0, "maxManaBonus": 0 },
		"inventory": [],
		"equipment": { "weapon": "", "armor": "", "trinket": "" },
		"skills": { "knownSkillIds": [], "cooldowns": {} },
		"talents": { "availablePoints": 0, "spentPoints": 0, "ranks": {} },
		"talentTreeId": "",
		"position": _position_from_array(zone.get("startPosition", [0, 0])),
	}
	active_enemy = {}
	selected_item_id = ""
	selected_skill_id = ""
	next_item_instance_number = 1
	turn_number = 0
	inventory_visible = false
	talent_panel_visible = false
	ui = { "activePanel": "", "debugMode": false, "selectedTileId": "", "lastAnimation": {} }
	completed_encounters = {}
	completion_reward_claimed = false
	defeated = false
	temporary_modifiers = []
	inventory_interaction = { "mode": "normal", "sourceItemInstanceId": "" }
	resonance = ItemResonance.create_state()
	_mark_current_tile_visited()

func move_player(direction: String) -> void:
	if not class_selected:
		add_message("Choose a class first.", "warning")
		return
	if defeated:
		add_message("You cannot move while defeated.", "warning")
		return
	var current: Dictionary = player.get("position", { "x": 0, "y": 0 })
	var target := current.duplicate()
	match direction:
		"north":
			target["y"] = int(target["y"]) - 1
		"south":
			target["y"] = int(target["y"]) + 1
		"east":
			target["x"] = int(target["x"]) + 1
		"west":
			target["x"] = int(target["x"]) - 1
		_:
			_set_ui_animation("invalid", "messages")
			add_message("You cannot travel that way.", "warning")
			return
	var tile := tile_at(target)
	if tile.is_empty() or bool(tile.get("blocksMovement", false)):
		_set_ui_animation("invalid", "messages")
		add_message("You cannot travel that way.", "warning")
		return
	player["position"] = target
	_mark_current_tile_visited()
	_set_ui_animation("movement", "map")
	add_message("You travel %s to %s." % [direction, tile.get("name", "the road")], "info")
	if tile.has("encounterId") and not completed_encounters.has(str(tile["encounterId"])):
		start_encounter(str(tile["encounterId"]))
	if str(tile.get("kind", "")) == "elder_stone":
		complete_objective("phase3_reach_elder_stone")
	_check_zone_completion()
	state_changed.emit()

func open_current_container() -> void:
	var tile := current_tile()
	var container_id := str(tile.get("containerId", ""))
	if container_id == "":
		add_message("There is no container here.", "warning")
		return
	open_container(container_id)

func open_container(container_id: String) -> void:
	var container: Dictionary = containers_by_id.get(container_id, {})
	if container.is_empty():
		add_message("There is no such container.", "warning")
		return
	if bool(container.get("opened", false)):
		add_message("%s is already open." % container.get("name", "The container"), "warning")
		return
	container["opened"] = true
	containers_by_id[container_id] = container
	add_message("You open %s." % container.get("name", "the container"), "loot")
	grant_loot(str(container.get("lootTableId", "")))
	if container_id == "phase3_abandoned_chest":
		complete_objective("phase3_open_abandoned_chest")
		if has_item("phase3_old_sword"):
			complete_objective("phase3_find_old_sword")
	state_changed.emit()

func activate_current_shrine() -> void:
	var tile := current_tile()
	var shrine_id := str(tile.get("shrineId", ""))
	if shrine_id == "":
		add_message("There is no shrine here.", "warning")
		return
	activate_shrine(shrine_id)

func activate_shrine(shrine_id: String) -> void:
	var shrine: Dictionary = shrines_by_id.get(shrine_id, {})
	if shrine.is_empty():
		add_message("There is no such shrine.", "warning")
		return
	if bool(shrine.get("activated", false)):
		add_message("%s is already quiet." % shrine.get("name", "The shrine"), "warning")
		return
	shrine["activated"] = true
	shrines_by_id[shrine_id] = shrine
	player["health"] = mini(effective_max_health(), int(player["health"]) + int(shrine.get("restoreHealth", 0)))
	player["mana"] = mini(effective_max_mana(), int(player["mana"]) + int(shrine.get("restoreMana", 0)))
	if shrine.has("grantItemId"):
		add_item(str(shrine["grantItemId"]), 1)
	if shrine_id == "phase3_weathered_shrine":
		add_item("phase5_ashen_ring", 1)
		if not has_item("phase5_identify_scroll"):
			add_item("phase5_identify_scroll", 1)
		add_message("At the shrine's base, ash gathers around a blackened ring.", "discovery")
	add_message("%s restores your strength." % shrine.get("name", "The shrine"), "success")
	state_changed.emit()

func start_encounter(enemy_id: String) -> void:
	if completed_encounters.has(enemy_id):
		add_message("This threat has already been ended.", "info")
		return
	var definition: Dictionary = enemies_by_id.get(enemy_id, {})
	if definition.is_empty():
		add_message("No enemy waits here.", "warning")
		return
	active_enemy = definition.duplicate(true)
	active_enemy["defeated"] = false
	add_message("%s blocks the road." % active_enemy.get("name", "An enemy"), "combat")
	state_changed.emit()

func attack_enemy() -> void:
	if not class_selected:
		add_message("Choose a class first.", "warning")
		return
	if defeated:
		add_message("You need to restart before fighting again.", "warning")
		return
	if active_enemy.is_empty():
		var tile := current_tile()
		if tile.has("encounterId"):
			start_encounter(str(tile["encounterId"]))
		else:
			add_message("There is no enemy to attack.", "warning")
		return
	if bool(active_enemy.get("defeated", false)):
		add_message("There is nothing left to attack.", "warning")
		return
	var damage := player_damage(active_enemy)
	active_enemy["health"] = maxi(0, int(active_enemy.get("health", 0)) - damage)
	_set_ui_animation("hit", "enemy")
	add_message("You strike %s for %d damage." % [active_enemy.get("name", "the enemy"), damage], "combat")
	_process_curses_for_equipped("attack")
	_add_attunement_for_slot("weapon", 1)
	if int(active_enemy.get("health", 0)) <= 0:
		_defeat_active_enemy()
	else:
		_enemy_retaliates()
	_advance_turn()
	state_changed.emit()

func use_skill(skill_id: String) -> void:
	if defeated:
		add_message("You need to restart before fighting again.", "warning")
		return
	var skill: Dictionary = skills_by_id.get(skill_id, {})
	if skill.is_empty() or not player.get("skills", {}).get("knownSkillIds", []).has(skill_id):
		add_message("You do not know that skill.", "warning")
		return
	if str(skill.get("targetType", "")) == "enemy" and active_enemy.is_empty():
		var tile := current_tile()
		if tile.has("encounterId"):
			start_encounter(str(tile["encounterId"]))
		if active_enemy.is_empty():
			add_message("%s needs an enemy target." % skill.get("name", "That skill"), "warning")
			return
	var cooldowns: Dictionary = player.get("skills", {}).get("cooldowns", {})
	if int(cooldowns.get(skill_id, 0)) > 0:
		add_message("%s is on cooldown." % skill.get("name", "That skill"), "warning")
		return
	var cost := effective_skill_cost(skill)
	if str(skill.get("resource", "none")) == "mana" and int(player.get("mana", 0)) < cost:
		add_message("Not enough mana for %s." % skill.get("name", "that skill"), "warning")
		return
	if str(skill.get("resource", "none")) == "mana":
		player["mana"] = int(player["mana"]) - cost
	_process_curses_for_equipped("combat_use")
	_process_ring_whisper_for_equipped("on_skill_use", { "skillId": skill_id })
	process_resonance_trigger("skill_use", { "skillId": skill_id })
	_process_resonance_health_costs(skill_id)
	_add_attunement_for_slot("trinket", 1)
	var damage_total := 0
	var healing_total := 0
	var mana_total := 0
	for raw_effect in skill.get("effects", []):
		var effect: Dictionary = raw_effect
		var amount := skill_effect_amount(skill, effect)
		match str(effect.get("type", "")):
			"damage":
				var defense := 0 if bool(skill.get("ignoreDefense", false)) else maxi(0, int(active_enemy.get("defense", 0)) - int(skill.get("defensePierce", 0)))
				var damage := maxi(1, amount - defense)
				active_enemy["health"] = maxi(0, int(active_enemy.get("health", 0)) - damage)
				damage_total += damage
			"heal":
				player["health"] = mini(effective_max_health(), int(player["health"]) + amount)
				healing_total += amount
			"restore_mana":
				player["mana"] = mini(effective_max_mana(), int(player["mana"]) + amount)
				mana_total += amount
			"buff":
				temporary_modifiers.append({ "sourceSkillId": skill_id, "target": "player", "stat": str(effect.get("stat", "")), "amount": int(effect.get("amount", 0)), "remainingTurns": int(effect.get("durationTurns", 1)) })
			"debuff":
				temporary_modifiers.append({ "sourceSkillId": skill_id, "target": "enemy", "stat": str(effect.get("stat", "")), "amount": int(effect.get("amount", 0)), "remainingTurns": int(effect.get("durationTurns", 1)) })
	var message := str(skill.get("messageTemplate", "%s used." % skill.get("name", "Skill")))
	message = message.replace("{damage}", str(damage_total)).replace("{healing}", str(healing_total)).replace("{amount}", str(mana_total))
	add_message(message, "combat")
	cooldowns[skill_id] = effective_skill_cooldown(skill)
	player["skills"]["cooldowns"] = cooldowns
	if not active_enemy.is_empty() and int(active_enemy.get("health", 0)) <= 0:
		_defeat_active_enemy()
	elif not active_enemy.is_empty() and not bool(active_enemy.get("defeated", false)):
		_enemy_retaliates()
	_advance_turn()
	state_changed.emit()

func equip_item(instance_id: String) -> void:
	var item := inventory_item(instance_id)
	if item.is_empty():
		add_message("That item is not in your pack.", "warning")
		return
	var definition := item_definition(item)
	if not bool(definition.get("equippable", false)):
		add_message("%s cannot be equipped." % display_name(item), "warning")
		return
	var slot := str(definition.get("equipmentSlot", ""))
	var equipment: Dictionary = player["equipment"]
	equipment[slot] = instance_id
	player["equipment"] = equipment
	player["health"] = mini(int(player["health"]), effective_max_health())
	player["mana"] = mini(int(player["mana"]), effective_max_mana())
	_reveal_ring_soul_presence(instance_id, "%s is not empty. Something inside it listens." % display_name(item))
	_process_ring_whisper_for_instance(instance_id, "on_equip")
	_process_curses_for_instance(instance_id, "equip")
	process_resonance_trigger("equip_together", { "itemInstanceId": instance_id })
	selected_item_id = ""
	add_message("Equipped %s." % display_name(item), "loot")
	state_changed.emit()

func use_item(instance_id: String) -> void:
	var item := inventory_item(instance_id)
	if item.is_empty():
		add_message("That item is not in your pack.", "warning")
		return
	var definition := item_definition(item)
	if str(definition.get("id", "")) == "phase5_identify_scroll":
		enter_identify_mode(instance_id)
		return
	var effect: Dictionary = definition.get("effect", {})
	if str(effect.get("type", "")) != "heal":
		add_message("%s has no use right now." % display_name(item), "warning")
		return
	if int(player["health"]) >= effective_max_health():
		add_message("You are already at full health.", "warning")
		return
	player["health"] = mini(effective_max_health(), int(player["health"]) + int(effect.get("amount", 0)))
	_decrement_inventory_item(instance_id)
	add_message("Used %s." % display_name(item), "success")
	state_changed.emit()

func select_item(instance_id: String) -> void:
	if str(inventory_interaction.get("mode", "normal")) == "identify_target":
		identify_target_item(instance_id)
		return
	selected_item_id = instance_id
	state_changed.emit()

func enter_identify_mode(scroll_instance_id: String) -> void:
	var scroll := inventory_item(scroll_instance_id)
	if scroll.is_empty() or str(scroll.get("itemId", "")) != "phase5_identify_scroll":
		add_message("Choose a valid Identify Scroll first.", "warning")
		return
	inventory_visible = true
	inventory_interaction = { "mode": "identify_target", "sourceItemInstanceId": scroll_instance_id }
	add_message("Choose an item to identify.", "discovery")
	state_changed.emit()

func cancel_item_target_mode() -> void:
	inventory_interaction = { "mode": "normal", "sourceItemInstanceId": "" }
	add_message("Identification cancelled.", "info")
	state_changed.emit()

func identify_target_item(target_instance_id: String) -> void:
	var scroll_instance_id := str(inventory_interaction.get("sourceItemInstanceId", ""))
	var scroll := inventory_item(scroll_instance_id)
	var target := inventory_item(target_instance_id)
	if scroll.is_empty() or str(scroll.get("itemId", "")) != "phase5_identify_scroll":
		inventory_interaction = { "mode": "normal", "sourceItemInstanceId": "" }
		add_message("No Identify Scroll is ready.", "warning")
		state_changed.emit()
		return
	if target.is_empty() or target_instance_id == scroll_instance_id:
		add_message("The scroll refuses. Choose a hidden item.", "warning")
		state_changed.emit()
		return
	if not can_identify_item(target):
		add_message("The scroll refuses. There is nothing hidden here it can reveal.", "warning")
		state_changed.emit()
		return
	var definition := item_definition(target)
	var revealed: Array[String] = []
	for property in definition.get("properties", []):
		if _property_has_requirement(property, "identify") and not _instance_has_revealed_property(target, str(property.get("id", ""))):
			_reveal_property(target, str(property.get("id", "")))
			target["identifiedPropertyIds"].append(str(property.get("id", "")))
			revealed.append(str(property.get("name", "Unknown Property")))
	var has_more_identify := false
	for property in definition.get("properties", []):
		if _property_has_requirement(property, "identify") and not _instance_has_revealed_property(target, str(property.get("id", ""))):
			has_more_identify = true
	target["knowledgeState"] = "partially_identified" if has_more_identify else "identified"
	if RingSouls.reveal_soul_presence(target):
		add_message("%s is not empty. A will stirs beneath the ash." % display_name(target), "discovery")
	_replace_inventory_item(target)
	_decrement_inventory_item(scroll_instance_id)
	inventory_interaction = { "mode": "normal", "sourceItemInstanceId": "" }
	selected_item_id = target_instance_id
	add_message("The scroll burns to ash. %s reveals: %s." % [display_name(target), ", ".join(revealed)], "discovery")
	process_resonance_trigger("identify_item", { "itemInstanceId": target_instance_id })
	process_resonance_trigger("equip_together", { "itemInstanceId": target_instance_id })
	_clamp_resources()
	state_changed.emit()

func toggle_inventory() -> void:
	toggle_panel("inventory")

func toggle_talent_panel() -> void:
	toggle_panel("talents")

func open_panel(panel_id: String) -> void:
	ui["activePanel"] = panel_id
	inventory_visible = panel_id == "inventory"
	talent_panel_visible = panel_id == "talents"
	state_changed.emit()

func close_panel() -> void:
	ui["activePanel"] = ""
	inventory_visible = false
	talent_panel_visible = false
	state_changed.emit()

func toggle_panel(panel_id: String) -> void:
	if str(ui.get("activePanel", "")) == panel_id:
		close_panel()
		return
	open_panel(panel_id)

func toggle_debug_mode() -> void:
	ui["debugMode"] = not bool(ui.get("debugMode", false))
	state_changed.emit()

func select_tile(tile_id: String) -> void:
	ui["selectedTileId"] = tile_id
	state_changed.emit()

func push_ui_animation(event_type: String, target_id: String = "") -> void:
	_set_ui_animation(event_type, target_id)
	state_changed.emit()

func _set_ui_animation(event_type: String, target_id: String = "") -> void:
	ui["lastAnimation"] = { "id": "ui_%d" % Time.get_ticks_msec(), "type": event_type, "targetId": target_id, "createdAt": Time.get_ticks_msec() }

func handle_escape() -> void:
	if not ui.get("pendingBargain", {}).is_empty():
		add_message("Answer the ring's bargain first.", "warning")
		return
	if str(inventory_interaction.get("mode", "normal")) == "identify_target":
		cancel_item_target_mode()
		return
	if str(ui.get("activePanel", "")) != "":
		close_panel()

func restart_game() -> void:
	reset()

func restart_same_class() -> void:
	var class_id := selected_class_id
	reset()
	if class_id != "":
		start_class(class_id)

func grant_loot(loot_table_id: String) -> void:
	var table: Dictionary = loot_tables_by_id.get(loot_table_id, {})
	for raw_entry in table.get("entries", []):
		var entry: Dictionary = raw_entry
		add_item(str(entry.get("itemId", "")), int(entry.get("quantity", 1)))
	var gold: Dictionary = table.get("gold", {})
	var amount := int(gold.get("min", 0))
	if amount > 0:
		player["gold"] = int(player["gold"]) + amount
		add_message("Found %d gold." % amount, "loot")

func add_item(item_id: String, quantity: int) -> void:
	var definition: Dictionary = items_by_id.get(item_id, {})
	if definition.is_empty() or quantity <= 0:
		return
	var inventory: Array = player.get("inventory", [])
	if bool(definition.get("stackable", true)):
		for item in inventory:
			if str(item.get("itemId", "")) == item_id:
				item["quantity"] = int(item.get("quantity", 0)) + quantity
				add_message("Found %s x%d." % [display_name(item), quantity], "loot")
				return
	if bool(definition.get("stackable", true)):
		var item := _make_item_instance(item_id, quantity)
		inventory.append(item)
		add_message("Found %s." % display_name(item), "loot")
	else:
		for index in range(quantity):
			var item := _make_item_instance(item_id, 1)
			inventory.append(item)
			add_message("Found %s." % display_name(item), "loot")
	player["inventory"] = inventory

func complete_objective(objective_id: String) -> void:
	var changed_stage := ""
	for stage in quest_chain.get("stages", []):
		for objective in stage.get("objectives", []):
			if str(objective.get("id", "")) == objective_id and not bool(objective.get("completed", false)):
				objective["completed"] = true
		var stage_complete := _objectives_complete(stage.get("objectives", []))
		if stage_complete and not bool(stage.get("completed", false)):
			stage["completed"] = true
			changed_stage = str(stage.get("title", "Stage"))
	if changed_stage != "":
		_set_ui_animation("quest", "quest")
		add_message("Quest stage complete: %s." % changed_stage, "success")
	_check_zone_completion()

func current_tile() -> Dictionary:
	return tile_at(player.get("position", { "x": 0, "y": 0 }))

func tile_at(position: Dictionary) -> Dictionary:
	for raw_tile in zone.get("tiles", []):
		var tile: Dictionary = raw_tile
		var tile_position := _position_from_array(tile.get("position", [0, 0]))
		if int(tile_position["x"]) == int(position["x"]) and int(tile_position["y"]) == int(position["y"]):
			return tile
	return {}

func inventory_item(instance_id: String) -> Dictionary:
	for item in player.get("inventory", []):
		if str(item.get("instanceId", "")) == instance_id:
			return item
	return {}

func selected_item() -> Dictionary:
	return inventory_item(selected_item_id)

func has_item(item_id: String) -> bool:
	for item in player.get("inventory", []):
		if str(item.get("itemId", "")) == item_id:
			return true
	return false

func first_inventory_item_by_item_id(item_id: String) -> Dictionary:
	for item in player.get("inventory", []):
		if str(item.get("itemId", "")) == item_id:
			return item
	return {}

func item_has_revealed_property(item_id: String, property_id: String) -> bool:
	for item in player.get("inventory", []):
		if str(item.get("itemId", "")) == item_id and _instance_has_revealed_property(item, property_id):
			return true
	return false

func has_accepted_ring_bargain(bargain_id: String) -> bool:
	for item in player.get("inventory", []):
		if not RingSouls.has_soul(item):
			continue
		var soul: Dictionary = item.get("soul", {})
		if soul.get("bargainIdsAccepted", []).has(bargain_id):
			return true
	return false

func item_definition(item: Dictionary) -> Dictionary:
	return items_by_id.get(str(item.get("itemId", item.get("id", ""))), {})

func ring_soul_definition(item: Dictionary) -> Dictionary:
	return ring_souls_by_id.get(RingSouls.soul_id(item), {})

func ring_soul_reveal_stage(item: Dictionary) -> int:
	return RingSouls.reveal_stage(item)

func active_resonances() -> Array[Dictionary]:
	return ItemResonance.get_active_resonances(self)

func discovered_active_resonances() -> Array[Dictionary]:
	return ItemResonance.get_discovered_active_resonances(self)

func hinted_resonances() -> Array[Dictionary]:
	return ItemResonance.get_hinted_resonances(self)

func is_resonance_discovered(resonance_id: String) -> bool:
	return ItemResonance.is_discovered(self, resonance_id)

func resonance_stats() -> Dictionary:
	return ItemResonance.stat_bonuses(self)

func resonance_skill_damage_bonus(skill_id: String) -> int:
	return ItemResonance.skill_damage_bonus(self, skill_id)

func resonance_skill_heal_bonus(skill_id: String) -> int:
	return ItemResonance.skill_heal_bonus(self, skill_id)

func resonance_skill_cost_modifier(skill_id: String) -> int:
	return ItemResonance.skill_cost_modifier(self, skill_id)

func process_resonance_trigger(trigger: String, context: Dictionary = {}) -> void:
	var discovered := ItemResonance.process_trigger(self, trigger, context)
	for resonance_def in discovered:
		add_message(str(resonance_def.get("discoveryMessage", "Resonance discovered.")), "resonance")
		_add_resonance_whisper(resonance_def)

func display_name(item: Dictionary) -> String:
	var definition := item_definition(item)
	if str(item.get("knowledgeState", "known")) == "unidentified":
		return str(definition.get("unidentifiedName", "Unidentified %s" % str(definition.get("type", "Item")).capitalize()))
	return str(definition.get("name", item.get("itemId", "item")))

func display_description(item: Dictionary) -> String:
	var definition := item_definition(item)
	if str(item.get("knowledgeState", "known")) == "unidentified":
		return str(definition.get("unidentifiedDescription", definition.get("description", "")))
	return str(definition.get("description", ""))

func display_icon(item: Dictionary) -> String:
	var definition := item_definition(item)
	if str(item.get("knowledgeState", "known")) == "unidentified":
		return str(definition.get("unidentifiedIcon", definition.get("icon", "")))
	return str(definition.get("icon", ""))

func equipped_item(slot: String) -> Dictionary:
	return inventory_item(str(player.get("equipment", {}).get(slot, "")))

func equipment_stats() -> Dictionary:
	var result := { "strength": 0, "defense": 0, "spellPower": 0, "maxHealthBonus": 0, "maxManaBonus": 0 }
	for instance_id in player.get("equipment", {}).values():
		var item := inventory_item(str(instance_id))
		if item.is_empty():
			continue
		var definition := item_definition(item)
		for stat in result.keys():
			result[stat] = int(result[stat]) + int(definition.get("stats", {}).get(stat, 0))
	return result

func revealed_item_stats() -> Dictionary:
	var result := { "strength": 0, "defense": 0, "spellPower": 0, "maxHealthBonus": 0, "maxManaBonus": 0 }
	for item in equipped_items():
		var definition := item_definition(item)
		for property in definition.get("properties", []):
			if not _instance_has_revealed_property(item, str(property.get("id", ""))):
				continue
			for effect in property.get("effects", []):
				if str(effect.get("type", "")) == "stat_bonus" or str(effect.get("type", "")) == "stat_penalty":
					var stat := str(effect.get("stat", ""))
					if result.has(stat):
						result[stat] = int(result[stat]) + int(effect.get("amount", 0))
	return result

func talent_stats() -> Dictionary:
	var result := { "strength": 0, "defense": 0, "spellPower": 0, "maxHealthBonus": 0, "maxManaBonus": 0 }
	var ranks: Dictionary = player.get("talents", {}).get("ranks", {})
	for talent in current_talent_tree().get("nodes", []):
		var rank := int(ranks.get(str(talent.get("id", "")), 0))
		for effect in talent.get("effects", []):
			if str(effect.get("type", "")) == "stat_bonus":
				var stat := str(effect.get("stat", ""))
				if result.has(stat):
					result[stat] = int(result[stat]) + int(effect.get("amount", 0)) * rank
	return result

func effective_stats() -> Dictionary:
	var result: Dictionary = player.get("baseStats", {}).duplicate(true)
	var equipment := equipment_stats()
	for stat in equipment.keys():
		result[stat] = int(result.get(stat, 0)) + int(equipment[stat])
	var talents := talent_stats()
	for stat in talents.keys():
		result[stat] = int(result.get(stat, 0)) + int(talents[stat])
	var item_stats := revealed_item_stats()
	for stat in item_stats.keys():
		result[stat] = int(result.get(stat, 0)) + int(item_stats[stat])
	var resonance_bonus := resonance_stats()
	for stat in resonance_bonus.keys():
		result[stat] = int(result.get(stat, 0)) + int(resonance_bonus[stat])
	return result

func effective_max_health() -> int:
	return int(player["maxHealth"]) + int(equipment_stats().get("maxHealthBonus", 0)) + int(talent_stats().get("maxHealthBonus", 0)) + int(revealed_item_stats().get("maxHealthBonus", 0)) + int(resonance_stats().get("maxHealthBonus", 0))

func effective_max_mana() -> int:
	return int(player["maxMana"]) + int(equipment_stats().get("maxManaBonus", 0)) + int(talent_stats().get("maxManaBonus", 0)) + int(revealed_item_stats().get("maxManaBonus", 0)) + int(resonance_stats().get("maxManaBonus", 0))

func player_damage(enemy: Dictionary) -> int:
	return maxi(1, 8 + int(effective_stats().get("strength", 0)) + revealed_basic_damage_bonus() - int(enemy.get("defense", 0)))

func enemy_damage(enemy: Dictionary) -> int:
	var attack := int(enemy.get("attack", 0))
	var defense := int(effective_stats().get("defense", 0))
	for modifier in temporary_modifiers:
		if str(modifier.get("target", "")) == "enemy" and str(modifier.get("stat", "")) == "attack":
			attack += int(modifier.get("amount", 0))
		elif str(modifier.get("target", "")) == "player" and str(modifier.get("stat", "")) == "defense":
			defense += int(modifier.get("amount", 0))
	return maxi(1, attack - defense)

func current_class() -> Dictionary:
	return classes_by_id.get(selected_class_id, {})

func current_talent_tree() -> Dictionary:
	return talent_trees_by_id.get(str(player.get("talentTreeId", "")), {})

func skill_effect_amount(skill: Dictionary, effect: Dictionary) -> int:
	var amount := int(effect.get("amount", 0))
	var stats := effective_stats()
	var scaling_stat := str(effect.get("scalingStat", ""))
	if scaling_stat != "":
		amount += int(roundi(float(stats.get(scaling_stat, 0)) * float(effect.get("scalingMultiplier", 0.0))))
	if str(effect.get("type", "")) == "damage":
		amount += talent_skill_amount(str(skill.get("id", "")), "skill_damage_bonus")
		amount += revealed_skill_damage_bonus(str(skill.get("id", "")))
		amount += resonance_skill_damage_bonus(str(skill.get("id", "")))
	elif str(effect.get("type", "")) == "heal":
		amount += resonance_skill_heal_bonus(str(skill.get("id", "")))
	return maxi(1, amount) if str(effect.get("type", "")) == "damage" else amount

func effective_skill_cost(skill: Dictionary) -> int:
	return maxi(0, int(skill.get("resourceCost", 0)) - talent_skill_amount(str(skill.get("id", "")), "resource_cost_reduction") + revealed_mana_cost_modifier(str(skill.get("id", ""))) + resonance_skill_cost_modifier(str(skill.get("id", ""))))

func effective_skill_cooldown(skill: Dictionary) -> int:
	return maxi(0, int(skill.get("cooldownTurns", 0)) - talent_skill_amount(str(skill.get("id", "")), "cooldown_reduction"))

func talent_skill_amount(skill_id: String, effect_type: String) -> int:
	var total := 0
	var ranks: Dictionary = player.get("talents", {}).get("ranks", {})
	for talent in current_talent_tree().get("nodes", []):
		var rank := int(ranks.get(str(talent.get("id", "")), 0))
		for effect in talent.get("effects", []):
			if str(effect.get("type", "")) == effect_type and str(effect.get("skillId", "")) == skill_id:
				total += int(effect.get("amount", 0)) * rank
	return total

func revealed_skill_damage_bonus(skill_id: String) -> int:
	var total := 0
	for item in equipped_items():
		var definition := item_definition(item)
		for property in definition.get("properties", []):
			if not _instance_has_revealed_property(item, str(property.get("id", ""))):
				continue
			for effect in property.get("effects", []):
				if str(effect.get("type", "")) == "damage_bonus" and str(effect.get("skillId", "")) == skill_id:
					total += int(effect.get("amount", 0))
		total += accepted_ring_bargain_damage_bonus(item, skill_id)
	return total

func accepted_ring_bargain_damage_bonus(item: Dictionary, skill_id: String) -> int:
	if not RingSouls.has_soul(item):
		return 0
	var total := 0
	var soul: Dictionary = item.get("soul", {})
	for bargain_id in soul.get("bargainIdsAccepted", []):
		var bargain := _ring_bargain_definition(item, str(bargain_id))
		for effect in bargain.get("effects", []):
			if str(effect.get("type", "")) == "damage_bonus" and str(effect.get("skillId", "")) == skill_id:
				total += int(effect.get("amount", 0))
	return total

func revealed_basic_damage_bonus() -> int:
	var total := 0
	for item in equipped_items():
		var definition := item_definition(item)
		for property in definition.get("properties", []):
			if not _instance_has_revealed_property(item, str(property.get("id", ""))):
				continue
			for effect in property.get("effects", []):
				if str(effect.get("type", "")) == "damage_bonus" and str(effect.get("skillId", "")) == "":
					total += int(effect.get("amount", 0))
	return total

func revealed_mana_cost_modifier(skill_id: String) -> int:
	var total := 0
	for item in equipped_items():
		var definition := item_definition(item)
		for property in definition.get("properties", []):
			if not _instance_has_revealed_property(item, str(property.get("id", ""))):
				continue
			for effect in property.get("effects", []):
				if str(effect.get("type", "")) == "mana_cost_modifier" and str(effect.get("skillId", "")) == skill_id:
					total += int(effect.get("amount", 0))
	return total

func equipped_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance_id in player.get("equipment", {}).values():
		var item := inventory_item(str(instance_id))
		if not item.is_empty():
			result.append(item)
	return result

func can_identify_item(item: Dictionary) -> bool:
	var definition := item_definition(item)
	for property in definition.get("properties", []):
		if _property_has_requirement(property, "identify") and not _instance_has_revealed_property(item, str(property.get("id", ""))):
			return true
	return false

func can_spend_talent(talent: Dictionary) -> bool:
	var talents: Dictionary = player.get("talents", {})
	if int(talents.get("availablePoints", 0)) <= 0 or int(player.get("level", 1)) < int(talent.get("requiredLevel", 1)):
		return false
	var ranks: Dictionary = talents.get("ranks", {})
	if int(ranks.get(str(talent.get("id", "")), 0)) >= int(talent.get("maxRank", 1)):
		return false
	for prereq in talent.get("prerequisiteTalentIds", []):
		if int(ranks.get(str(prereq), 0)) <= 0:
			return false
	return true

func spend_talent_point(talent_id: String) -> void:
	for talent in current_talent_tree().get("nodes", []):
		if str(talent.get("id", "")) != talent_id:
			continue
		if not can_spend_talent(talent):
			add_message("You cannot learn %s yet." % talent.get("name", "that talent"), "warning")
			return
		var talents: Dictionary = player["talents"]
		var ranks: Dictionary = talents.get("ranks", {})
		ranks[talent_id] = int(ranks.get(talent_id, 0)) + 1
		talents["ranks"] = ranks
		talents["availablePoints"] = int(talents.get("availablePoints", 0)) - 1
		talents["spentPoints"] = int(talents.get("spentPoints", 0)) + 1
		player["talents"] = talents
		add_message("Learned %s." % talent.get("name", "talent"), "success")
		player["health"] = mini(int(player["health"]), effective_max_health())
		player["mana"] = mini(int(player["mana"]), effective_max_mana())
		state_changed.emit()
		return
	add_message("Unknown talent.", "warning")

func active_stage_index() -> int:
	var stages: Array = quest_chain.get("stages", [])
	for index in range(stages.size()):
		if not bool(stages[index].get("completed", false)):
			return index
	return maxi(0, stages.size() - 1)

func add_message(text: String, type: String) -> void:
	if type == "warning":
		_set_ui_animation("invalid", "messages")
	messages.append({ "id": "message_%d" % Time.get_ticks_msec(), "text": text, "type": type })
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()
	state_changed.emit()

func _defeat_active_enemy() -> void:
	active_enemy["defeated"] = true
	var enemy_id := str(active_enemy.get("id", ""))
	completed_encounters[enemy_id] = true
	add_message("%s is defeated." % active_enemy.get("name", "Enemy"), "combat")
	_process_ring_whisper_for_equipped("on_enemy_defeated", { "enemyId": enemy_id })
	process_resonance_trigger("enemy_defeated", { "enemyId": enemy_id })
	_process_attunement_after_victory()
	var xp := int(active_enemy.get("xpReward", 0))
	if xp > 0:
		_award_xp(xp)
	grant_loot(str(active_enemy.get("lootTable", "")))
	match enemy_id:
		"phase3_goblin_scout":
			complete_objective("phase3_defeat_goblin_scout")
		"phase3_starved_wolf":
			complete_objective("phase3_defeat_starved_wolf")
		"phase3_road_bandit":
			complete_objective("phase3_defeat_road_bandit")

func _award_xp(amount: int) -> void:
	player["xp"] = int(player["xp"]) + amount
	add_message("You gain %d XP." % amount, "success")
	while int(player["xp"]) >= int(player["xpToNextLevel"]):
		player["xp"] = int(player["xp"]) - int(player["xpToNextLevel"])
		player["level"] = int(player["level"]) + 1
		player["talents"]["availablePoints"] = int(player["talents"].get("availablePoints", 0)) + 1
		player["maxHealth"] = int(player["maxHealth"]) + 10
		player["maxMana"] = int(player["maxMana"]) + 5
		player["health"] = effective_max_health()
		player["mana"] = effective_max_mana()
		player["xpToNextLevel"] = 100 if int(player["level"]) == 2 else int(player["xpToNextLevel"]) + 50
		var template := str(current_class().get("levelUpMessage", "You reached level {level}."))
		_set_ui_animation("level", "header")
		add_message(template.replace("{level}", str(int(player["level"]))), "success")
		_process_level_gated_item_reveals()

func _check_zone_completion() -> void:
	var complete := true
	for stage in quest_chain.get("stages", []):
		if not bool(stage.get("completed", false)):
			complete = false
	if complete and not bool(quest_chain.get("completed", false)):
		quest_chain["completed"] = true
		zone["completed"] = true
		if not completion_reward_claimed:
			completion_reward_claimed = true
			var reward: Dictionary = quest_chain.get("completionReward", {})
			_award_xp(int(reward.get("xp", 0)))
			player["gold"] = int(player["gold"]) + int(reward.get("gold", 0))
			match selected_class_id:
				"roadwarden":
					add_item("phase5_roadwardens_notched_blade", 1)
				"ember_sage":
					add_item("phase5_ashen_ring", 1)
				"gravebound_scout":
					add_item("phase5_whisperthread_cloak", 1)
				_:
					add_item("phase5_ashen_ring", 1)
			add_message("The Elder Road is secure.", "success")

func _objectives_complete(objectives: Array) -> bool:
	if objectives.is_empty():
		return false
	for objective in objectives:
		if not bool(objective.get("completed", false)):
			return false
	return true

func _mark_current_tile_visited() -> void:
	var position: Dictionary = player.get("position", { "x": 0, "y": 0 })
	for tile in zone.get("tiles", []):
		var tile_position := _position_from_array(tile.get("position", [0, 0]))
		if int(tile_position["x"]) == int(position["x"]) and int(tile_position["y"]) == int(position["y"]):
			tile["state"] = "visited"

func _decrement_inventory_item(instance_id: String) -> void:
	var inventory: Array = player.get("inventory", [])
	for index in range(inventory.size()):
		var item: Dictionary = inventory[index]
		if str(item.get("instanceId", "")) == instance_id:
			item["quantity"] = int(item.get("quantity", 0)) - 1
			if int(item["quantity"]) <= 0:
				_clear_equipment_reference(instance_id)
				inventory.remove_at(index)
			player["inventory"] = inventory
			return

func _grant_starting_item(item_id: String) -> void:
	var definition: Dictionary = items_by_id.get(item_id, {})
	if definition.is_empty():
		return
	var item := _make_item_instance(item_id, int(definition.get("quantity", 1)))
	var inventory: Array = player.get("inventory", [])
	inventory.append(item)
	player["inventory"] = inventory
	if bool(definition.get("equippable", false)) and str(definition.get("equipmentSlot", "")) != "":
		player["equipment"][str(definition["equipmentSlot"])] = str(item["instanceId"])

func _make_item_instance(item_id: String, quantity: int) -> Dictionary:
	var definition: Dictionary = items_by_id.get(item_id, {})
	var instance_id := "%s_%04d" % [item_id, next_item_instance_number]
	next_item_instance_number += 1
	var item := {
		"instanceId": instance_id,
		"itemId": item_id,
		"quantity": quantity,
		"knowledgeState": str(definition.get("defaultKnowledgeState", "known")),
		"identifiedPropertyIds": [],
		"revealedPropertyIds": [],
	}
	if bool(definition.get("attunable", false)):
		item["attunement"] = { "points": 0, "level": 0, "revealedThresholds": [] }
	var soul_id := str(definition.get("soulId", ""))
	if soul_id != "":
		item["soul"] = RingSouls.create_state(soul_id)
	for property in definition.get("properties", []):
		if str(property.get("visibility", "")) == "visible":
			item["revealedPropertyIds"].append(str(property.get("id", "")))
	return item

func _clear_equipment_reference(instance_id: String) -> void:
	var equipment: Dictionary = player.get("equipment", {})
	for slot in equipment.keys():
		if str(equipment[slot]) == instance_id:
			equipment[slot] = ""
	player["equipment"] = equipment

func _replace_inventory_item(updated_item: Dictionary) -> void:
	var inventory: Array = player.get("inventory", [])
	for index in range(inventory.size()):
		var item: Dictionary = inventory[index]
		if str(item.get("instanceId", "")) == str(updated_item.get("instanceId", "")):
			inventory[index] = updated_item
			player["inventory"] = inventory
			return

func _instance_has_revealed_property(item: Dictionary, property_id: String) -> bool:
	for revealed_id in item.get("revealedPropertyIds", []):
		if str(revealed_id) == property_id:
			return true
	return false

func _reveal_property(item: Dictionary, property_id: String) -> void:
	if property_id == "" or _instance_has_revealed_property(item, property_id):
		return
	var revealed: Array = item.get("revealedPropertyIds", [])
	revealed.append(property_id)
	item["revealedPropertyIds"] = revealed

func _property_has_requirement(property, requirement_type: String) -> bool:
	if typeof(property) != TYPE_DICTIONARY:
		return false
	for requirement in property.get("requirements", []):
		if str(requirement.get("type", "")) == requirement_type:
			return true
	return false

func _property_requirement_value(property: Dictionary, requirement_type: String) -> int:
	for requirement in property.get("requirements", []):
		if str(requirement.get("type", "")) == requirement_type:
			return int(requirement.get("value", 0))
	return 0

func _process_curses_for_equipped(trigger: String) -> void:
	for item in equipped_items():
		_process_curses_for_instance(str(item.get("instanceId", "")), trigger)
	_clamp_resources()

func _process_curses_for_instance(instance_id: String, trigger: String) -> void:
	var item := inventory_item(instance_id)
	if item.is_empty():
		return
	var definition := item_definition(item)
	var changed := false
	var health_cost := 0
	for property in definition.get("properties", []):
		if not bool(property.get("cursed", false)) or not _property_has_requirement(property, trigger):
			continue
		var property_id := str(property.get("id", ""))
		if not _instance_has_revealed_property(item, property_id):
			_reveal_property(item, property_id)
			add_message("Curse revealed: %s." % property.get("name", "Unknown Curse"), "curse")
			if RingSouls.reveal_soul_presence(item):
				add_message("%s wakes with the curse." % display_name(item), "discovery")
			changed = true
		_process_ring_whisper_for_instance(instance_id, "on_curse_trigger", { "curseId": property_id })
		process_resonance_trigger("curse_trigger", { "itemInstanceId": instance_id, "curseId": property_id })
		for effect in property.get("effects", []):
			if str(effect.get("type", "")) == "health_cost":
				health_cost += int(effect.get("amount", 0))
	if health_cost > 0:
		var current_health := int(player.get("health", 0))
		var minimum_health := _minimum_health_after_curse(item)
		player["health"] = maxi(minimum_health, current_health - health_cost)
		var paid_health := current_health - int(player["health"])
		if paid_health > 0:
			add_message("%s exacts a blood price for %d health." % [display_name(item), paid_health], "curse")
		else:
			add_message("%s hungers for blood, but cannot take your last breath." % display_name(item), "curse")
		if minimum_health == 0 and int(player["health"]) <= 0:
			defeated = true
			add_message("You are defeated. Restart to try again.", "warning")
	if changed:
		_replace_inventory_item(item)
		_clamp_resources()

func _minimum_health_after_curse(item: Dictionary) -> int:
	if str(item.get("itemId", "")) == "phase5_ashen_ring":
		return 1
	return 0

func _process_resonance_health_costs(skill_id: String) -> void:
	var health_cost := ItemResonance.health_cost(self, skill_id)
	if health_cost <= 0:
		return
	var current_health := int(player.get("health", 0))
	player["health"] = maxi(1, current_health - health_cost)
	var paid_health := current_health - int(player["health"])
	if paid_health > 0:
		add_message("Resonance exacts an additional blood price for %d health." % paid_health, "curse")
	else:
		add_message("The resonance hungers, but cannot take your last breath.", "curse")

func _process_attunement_after_victory() -> void:
	for item in equipped_items():
		var definition := item_definition(item)
		if bool(definition.get("attunable", false)):
			_add_attunement_to_instance(str(item.get("instanceId", "")), 1)

func _add_attunement_for_slot(slot: String, points: int) -> void:
	var instance_id := str(player.get("equipment", {}).get(slot, ""))
	if instance_id != "":
		_add_attunement_to_instance(instance_id, points)

func _add_attunement_to_instance(instance_id: String, points: int) -> void:
	if points <= 0:
		return
	var item := inventory_item(instance_id)
	if item.is_empty():
		return
	var definition := item_definition(item)
	if not bool(definition.get("attunable", false)):
		return
	var attunement: Dictionary = item.get("attunement", { "points": 0, "level": 0, "revealedThresholds": [] })
	var old_level := int(attunement.get("level", 0))
	attunement["points"] = int(attunement.get("points", 0)) + points
	var new_level := _attunement_level(int(attunement["points"]))
	attunement["level"] = new_level
	item["attunement"] = attunement
	if new_level > old_level:
		add_message("%s grows familiar. Attunement reached Level %d." % [display_name(item), new_level], "discovery")
		for property in definition.get("properties", []):
			var required_level := _property_requirement_value(property, "attunement")
			if required_level > 0 and new_level >= required_level and not _instance_has_revealed_property(item, str(property.get("id", ""))):
				_reveal_property(item, str(property.get("id", "")))
				add_message("New property revealed: %s." % property.get("name", "Unknown Property"), "discovery")
		_process_ring_soul_attunement(item, new_level)
		_process_ring_whisper_for_item(item, "on_attunement_level_up", { "attunementLevel": new_level })
		process_resonance_trigger("attunement_level", { "itemInstanceId": instance_id, "attunementLevel": new_level })
	_replace_inventory_item(item)
	_clamp_resources()

func _reveal_ring_soul_presence(instance_id: String, message: String) -> bool:
	var item := inventory_item(instance_id)
	if item.is_empty():
		return false
	if not RingSouls.reveal_soul_presence(item):
		return false
	_replace_inventory_item(item)
	add_message(message, "discovery")
	return true

func _process_ring_soul_attunement(item: Dictionary, new_level: int) -> void:
	if not RingSouls.has_soul(item):
		return
	var soul_definition := ring_soul_definition(item)
	if soul_definition.is_empty():
		return
	if new_level >= 1:
		if RingSouls.reveal_soul_name(item):
			add_message("The soul in %s names itself: %s, %s." % [display_name(item), soul_definition.get("name", "Unknown"), soul_definition.get("epithet", "the bound")], "discovery")
		_reveal_ring_memories_for_attunement(item, 1)
	if new_level >= 2:
		if RingSouls.reveal_soul_motivation(item):
			add_message("%s's hunger clarifies: %s" % [soul_definition.get("name", "The soul"), soul_definition.get("motivation", "")], "discovery")
		_reveal_ring_memories_for_attunement(item, 2)
		_offer_ring_bargains_for_attunement(item, new_level)
	if new_level >= 3:
		_reveal_ring_memories_for_attunement(item, 3)

func _reveal_ring_memories_for_attunement(item: Dictionary, level: int) -> void:
	var soul_definition := ring_soul_definition(item)
	for memory in soul_definition.get("memories", []):
		var reveal: Dictionary = memory.get("reveal", {})
		var reveal_level := int(reveal.get("level", 0))
		if reveal_level == level and (str(reveal.get("type", "")) == "attunement" or str(reveal.get("type", "")) == "attunement_or_bargain"):
			_reveal_ring_memory(item, str(memory.get("id", "")))

func _reveal_ring_memory(item: Dictionary, memory_id: String) -> bool:
	if not RingSouls.mark_memory_revealed(item, memory_id):
		return false
	var memory := _ring_memory_definition(item, memory_id)
	if memory.is_empty():
		add_message("A ring memory surfaces.", "memory")
	else:
		add_message("Memory revealed: %s. %s" % [memory.get("title", "Untitled Memory"), memory.get("text", "")], "memory")
	return true

func _ring_memory_definition(item: Dictionary, memory_id: String) -> Dictionary:
	for memory in ring_soul_definition(item).get("memories", []):
		if str(memory.get("id", "")) == memory_id:
			return memory
	return {}

func _offer_ring_bargains_for_attunement(item: Dictionary, level: int) -> void:
	if not RingSouls.has_soul(item):
		return
	for bargain in ring_soul_definition(item).get("bargains", []):
		var bargain_id := str(bargain.get("id", ""))
		var trigger: Dictionary = bargain.get("trigger", {})
		if str(trigger.get("type", "")) != "attunement" or int(trigger.get("level", 0)) > level:
			continue
		if RingSouls.has_bargain_resolution(item, bargain_id):
			continue
		var soul: Dictionary = item.get("soul", {})
		if soul.get("bargainIdsOffered", []).has(bargain_id):
			continue
		RingSouls.mark_bargain_offered(item, bargain_id)
		ui["pendingBargain"] = { "itemInstanceId": str(item.get("instanceId", "")), "bargainId": bargain_id }
		add_message("%s offers a bargain: %s" % [_ring_soul_speaker(item), bargain.get("offerLine", "")], "bargain")
		_process_ring_whisper_for_item(item, "on_bargain_offered", { "bargainId": bargain_id })
		return

func accept_pending_bargain() -> void:
	var pending: Dictionary = ui.get("pendingBargain", {})
	if pending.is_empty():
		add_message("No ring bargain is waiting.", "warning")
		return
	var item := inventory_item(str(pending.get("itemInstanceId", "")))
	if item.is_empty():
		ui.erase("pendingBargain")
		add_message("The bargain slips away with the missing ring.", "warning")
		state_changed.emit()
		return
	var bargain := _ring_bargain_definition(item, str(pending.get("bargainId", "")))
	if bargain.is_empty():
		ui.erase("pendingBargain")
		add_message("The bargain has no shape.", "warning")
		state_changed.emit()
		return
	var cost: Dictionary = bargain.get("healthCost", {})
	var current_health := int(player.get("health", 0))
	player["health"] = maxi(1, current_health - int(cost.get("amount", 0)))
	RingSouls.adjust_trust(item, int(bargain.get("trustOnAccept", 0)))
	RingSouls.mark_bargain_accepted(item, str(bargain.get("id", "")))
	for memory_id in bargain.get("revealMemoryIds", []):
		_reveal_ring_memory(item, str(memory_id))
	add_message(str(bargain.get("acceptMessage", "The bargain is accepted.")), "bargain")
	_process_ring_whisper_for_item(item, "on_bargain_accepted", { "bargainId": str(bargain.get("id", "")) })
	_replace_inventory_item(item)
	ui.erase("pendingBargain")
	_clamp_resources()
	state_changed.emit()

func reject_pending_bargain() -> void:
	var pending: Dictionary = ui.get("pendingBargain", {})
	if pending.is_empty():
		add_message("No ring bargain is waiting.", "warning")
		return
	var item := inventory_item(str(pending.get("itemInstanceId", "")))
	if item.is_empty():
		ui.erase("pendingBargain")
		add_message("The bargain slips away with the missing ring.", "warning")
		state_changed.emit()
		return
	var bargain := _ring_bargain_definition(item, str(pending.get("bargainId", "")))
	if bargain.is_empty():
		ui.erase("pendingBargain")
		add_message("The bargain has no shape.", "warning")
		state_changed.emit()
		return
	RingSouls.adjust_trust(item, int(bargain.get("trustOnReject", 0)))
	RingSouls.mark_bargain_rejected(item, str(bargain.get("id", "")))
	add_message(str(bargain.get("rejectMessage", "The bargain is rejected.")), "bargain")
	_process_ring_whisper_for_item(item, "on_bargain_rejected", { "bargainId": str(bargain.get("id", "")) })
	_replace_inventory_item(item)
	ui.erase("pendingBargain")
	state_changed.emit()

func _ring_bargain_definition(item: Dictionary, bargain_id: String) -> Dictionary:
	for bargain in ring_soul_definition(item).get("bargains", []):
		if str(bargain.get("id", "")) == bargain_id:
			return bargain
	return {}

func _process_ring_whisper_for_equipped(trigger: String, context: Dictionary = {}) -> bool:
	for item in equipped_items():
		if _process_ring_whisper_for_instance(str(item.get("instanceId", "")), trigger, context):
			return true
	return false

func _process_ring_whisper_for_instance(instance_id: String, trigger: String, context: Dictionary = {}) -> bool:
	var item := inventory_item(instance_id)
	if item.is_empty():
		return false
	return _process_ring_whisper_for_item(item, trigger, context)

func _process_ring_whisper_for_item(item: Dictionary, trigger: String, context: Dictionary = {}) -> bool:
	if not RingSouls.has_soul(item):
		return false
	var soul_definition := ring_soul_definition(item)
	var whisper := RingSouls.select_whisper(item, soul_definition, trigger, context, turn_number)
	if whisper.is_empty():
		return false
	RingSouls.mark_whisper_seen(item, str(whisper.get("id", "")), turn_number)
	_replace_inventory_item(item)
	add_message("%s whispers: \"%s\"" % [_ring_soul_speaker(item), whisper.get("line", "")], "ring_whisper")
	return true

func _ring_soul_speaker(item: Dictionary) -> String:
	var soul_definition := ring_soul_definition(item)
	var soul: Dictionary = item.get("soul", {})
	if bool(soul.get("nameRevealed", false)):
		return str(soul_definition.get("name", "The ring"))
	return "The ring"

func _add_resonance_whisper(resonance_def: Dictionary) -> void:
	var whisper := str(resonance_def.get("whisper", ""))
	if whisper == "":
		return
	var speaker := "Varn" if _resonance_involves_item(resonance_def, "phase5_ashen_ring") else "The resonance"
	add_message("%s whispers: \"%s\"" % [speaker, whisper], "ring_whisper")

func _resonance_involves_item(resonance_def: Dictionary, item_id: String) -> bool:
	for required_item_id in resonance_def.get("requiredItemIds", []):
		if str(required_item_id) == item_id:
			return true
	return false

func _attunement_level(points: int) -> int:
	if points >= 9:
		return 3
	if points >= 5:
		return 2
	if points >= 2:
		return 1
	return 0

func _process_level_gated_item_reveals() -> void:
	for item in player.get("inventory", []):
		var changed := false
		var definition := item_definition(item)
		for property in definition.get("properties", []):
			var required_level := _property_requirement_value(property, "player_level")
			if required_level > 0 and int(player.get("level", 1)) >= required_level and not _instance_has_revealed_property(item, str(property.get("id", ""))):
				_reveal_property(item, str(property.get("id", "")))
				add_message("%s awakens: %s." % [display_name(item), property.get("name", "Unknown Property")], "discovery")
				changed = true
		if changed:
			_replace_inventory_item(item)
	_clamp_resources()

func _clamp_resources() -> void:
	player["health"] = mini(int(player.get("health", 0)), effective_max_health())
	player["mana"] = mini(int(player.get("mana", 0)), effective_max_mana())

func _enemy_retaliates() -> void:
	var retaliation := enemy_damage(active_enemy)
	player["health"] = maxi(0, int(player["health"]) - retaliation)
	add_message("%s hits you for %d damage." % [active_enemy.get("name", "The enemy"), retaliation], "combat")
	if int(player["health"]) <= 0:
		defeated = true
		add_message("You are defeated. Restart to try again.", "warning")

func _advance_turn() -> void:
	turn_number += 1
	var cooldowns: Dictionary = player.get("skills", {}).get("cooldowns", {})
	for skill_id in cooldowns.keys():
		cooldowns[skill_id] = maxi(0, int(cooldowns[skill_id]) - 1)
	player["skills"]["cooldowns"] = cooldowns
	var remaining: Array[Dictionary] = []
	for modifier in temporary_modifiers:
		modifier["remainingTurns"] = int(modifier.get("remainingTurns", 0)) - 1
		if int(modifier["remainingTurns"]) > 0:
			remaining.append(modifier)
	temporary_modifiers = remaining

func _position_from_array(value) -> Dictionary:
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return { "x": 0, "y": 0 }
	return { "x": int(value[0]), "y": int(value[1]) }

func _load_records_by_id(path: String) -> Dictionary:
	var by_id := {}
	for record in _load_records(path):
		var id := str(record.get("id", ""))
		if id != "":
			by_id[id] = record
	return by_id

func _load_record(path: String) -> Dictionary:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed.duplicate(true)
	return {}

func _load_records(path: String) -> Array[Dictionary]:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	var result: Array[Dictionary] = []
	if typeof(parsed) != TYPE_ARRAY:
		return result
	for raw_record in parsed:
		if typeof(raw_record) == TYPE_DICTIONARY:
			result.append(raw_record.duplicate(true))
	return result
