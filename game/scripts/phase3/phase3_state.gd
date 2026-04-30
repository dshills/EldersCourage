extends RefCounted

signal state_changed

const MAX_MESSAGES := 10

var items_by_id := {}
var enemies_by_id := {}
var loot_tables_by_id := {}
var containers_by_id := {}
var shrines_by_id := {}
var zone := {}
var quest_chain := {}
var player := {}
var messages: Array[Dictionary] = []
var active_enemy := {}
var selected_item_id := ""
var inventory_visible := false
var completed_encounters := {}
var completion_reward_claimed := false
var defeated := false

func reset() -> void:
	items_by_id = _load_records_by_id("res://data/phase3/items.json")
	enemies_by_id = _load_records_by_id("res://data/phase3/enemies.json")
	loot_tables_by_id = _load_records_by_id("res://data/phase3/loot_tables.json")
	containers_by_id = _load_records_by_id("res://data/phase3/containers.json")
	shrines_by_id = _load_records_by_id("res://data/phase3/shrines.json")
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
		"equipment": { "weapon": {}, "armor": {}, "trinket": {} },
		"position": _position_from_array(zone.get("startPosition", [0, 0])),
	}
	active_enemy = {}
	selected_item_id = ""
	inventory_visible = false
	completed_encounters = {}
	completion_reward_claimed = false
	defeated = false
	messages.clear()
	_mark_current_tile_visited()
	add_message("Elder Road Outskirts opens before you.", "info")

func move_player(direction: String) -> void:
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
			add_message("You cannot travel that way.", "warning")
			return
	var tile := tile_at(target)
	if tile.is_empty() or bool(tile.get("blocksMovement", false)):
		add_message("You cannot travel that way.", "warning")
		return
	player["position"] = target
	_mark_current_tile_visited()
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
	add_message("You strike %s for %d damage." % [active_enemy.get("name", "the enemy"), damage], "combat")
	if int(active_enemy.get("health", 0)) <= 0:
		_defeat_active_enemy()
	else:
		var retaliation := enemy_damage(active_enemy)
		player["health"] = maxi(0, int(player["health"]) - retaliation)
		add_message("%s hits you for %d damage." % [active_enemy.get("name", "The enemy"), retaliation], "combat")
		if int(player["health"]) <= 0:
			defeated = true
			add_message("You are defeated. Restart to try again.", "warning")
	state_changed.emit()

func equip_item(item_id: String) -> void:
	var item := _remove_inventory_item(item_id)
	if item.is_empty():
		add_message("That item is not in your pack.", "warning")
		return
	if not bool(item.get("equippable", false)):
		add_message("%s cannot be equipped." % item.get("name", "That item"), "warning")
		add_item(item_id, int(item.get("quantity", 1)))
		return
	var slot := str(item.get("equipmentSlot", ""))
	var equipment: Dictionary = player["equipment"]
	var replaced: Dictionary = equipment.get(slot, {})
	if not replaced.is_empty():
		add_item(str(replaced["id"]), int(replaced.get("quantity", 1)))
	equipment[slot] = item
	player["equipment"] = equipment
	player["health"] = mini(int(player["health"]), effective_max_health())
	player["mana"] = mini(int(player["mana"]), effective_max_mana())
	selected_item_id = ""
	add_message("Equipped %s." % item.get("name", "item"), "loot")
	state_changed.emit()

func use_item(item_id: String) -> void:
	var item := inventory_item(item_id)
	if item.is_empty():
		add_message("That item is not in your pack.", "warning")
		return
	var effect: Dictionary = item.get("effect", {})
	if str(effect.get("type", "")) != "heal":
		add_message("%s has no use right now." % item.get("name", "That item"), "warning")
		return
	if int(player["health"]) >= effective_max_health():
		add_message("You are already at full health.", "warning")
		return
	player["health"] = mini(effective_max_health(), int(player["health"]) + int(effect.get("amount", 0)))
	_decrement_inventory_item(item_id)
	add_message("Used %s." % item.get("name", "item"), "success")
	state_changed.emit()

func select_item(item_id: String) -> void:
	selected_item_id = item_id
	state_changed.emit()

func toggle_inventory() -> void:
	inventory_visible = not inventory_visible
	state_changed.emit()

func restart_game() -> void:
	reset()

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
			if str(item.get("id", "")) == item_id:
				item["quantity"] = int(item.get("quantity", 0)) + quantity
				add_message("Found %s x%d." % [item.get("name", item_id), quantity], "loot")
				return
	var item := definition.duplicate(true)
	item["quantity"] = quantity
	inventory.append(item)
	player["inventory"] = inventory
	add_message("Found %s." % item.get("name", item_id), "loot")

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

func inventory_item(item_id: String) -> Dictionary:
	for item in player.get("inventory", []):
		if str(item.get("id", "")) == item_id:
			return item
	return {}

func selected_item() -> Dictionary:
	return inventory_item(selected_item_id)

func has_item(item_id: String) -> bool:
	return not inventory_item(item_id).is_empty()

func equipment_stats() -> Dictionary:
	var result := { "strength": 0, "defense": 0, "spellPower": 0, "maxHealthBonus": 0, "maxManaBonus": 0 }
	for item in player.get("equipment", {}).values():
		if typeof(item) != TYPE_DICTIONARY:
			continue
		for stat in result.keys():
			result[stat] = int(result[stat]) + int(item.get("stats", {}).get(stat, 0))
	return result

func effective_stats() -> Dictionary:
	var result: Dictionary = player.get("baseStats", {}).duplicate(true)
	var equipment := equipment_stats()
	for stat in equipment.keys():
		result[stat] = int(result.get(stat, 0)) + int(equipment[stat])
	return result

func effective_max_health() -> int:
	return int(player["maxHealth"]) + int(equipment_stats().get("maxHealthBonus", 0))

func effective_max_mana() -> int:
	return int(player["maxMana"]) + int(equipment_stats().get("maxManaBonus", 0))

func player_damage(enemy: Dictionary) -> int:
	return maxi(1, 8 + int(effective_stats().get("strength", 0)) - int(enemy.get("defense", 0)))

func enemy_damage(enemy: Dictionary) -> int:
	return maxi(1, int(enemy.get("attack", 0)) - int(effective_stats().get("defense", 0)))

func active_stage_index() -> int:
	var stages: Array = quest_chain.get("stages", [])
	for index in range(stages.size()):
		if not bool(stages[index].get("completed", false)):
			return index
	return maxi(0, stages.size() - 1)

func add_message(text: String, type: String) -> void:
	messages.append({ "id": "message_%d" % Time.get_ticks_msec(), "text": text, "type": type })
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()
	state_changed.emit()

func _defeat_active_enemy() -> void:
	active_enemy["defeated"] = true
	var enemy_id := str(active_enemy.get("id", ""))
	completed_encounters[enemy_id] = true
	add_message("%s is defeated." % active_enemy.get("name", "Enemy"), "combat")
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
		player["maxHealth"] = int(player["maxHealth"]) + 10
		player["maxMana"] = int(player["maxMana"]) + 5
		player["health"] = effective_max_health()
		player["mana"] = effective_max_mana()
		player["xpToNextLevel"] = 100 if int(player["level"]) == 2 else int(player["xpToNextLevel"]) + 50
		add_message("You reached level %d." % int(player["level"]), "success")

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

func _remove_inventory_item(item_id: String) -> Dictionary:
	var inventory: Array = player.get("inventory", [])
	for index in range(inventory.size()):
		var item: Dictionary = inventory[index]
		if str(item.get("id", "")) == item_id:
			inventory.remove_at(index)
			player["inventory"] = inventory
			return item
	return {}

func _decrement_inventory_item(item_id: String) -> void:
	var inventory: Array = player.get("inventory", [])
	for index in range(inventory.size()):
		var item: Dictionary = inventory[index]
		if str(item.get("id", "")) == item_id:
			item["quantity"] = int(item.get("quantity", 0)) - 1
			if int(item["quantity"]) <= 0:
				inventory.remove_at(index)
			player["inventory"] = inventory
			return

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
