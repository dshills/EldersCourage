extends RefCounted

signal state_changed

const MAX_MESSAGES := 8

var items_by_id := {}
var player := {}
var enemy := {}
var quest := {}
var messages: Array[Dictionary] = []
var chest_state := "closed"
var inventory_visible := false
var selected_enemy_id := ""
var selected_item_id := ""
var quest_completion_announced := false

func reset() -> void:
	items_by_id = _load_records_by_id("res://data/phase2/items.json")
	var enemies := _load_records("res://data/phase2/enemies.json")
	var quests := _load_records("res://data/phase2/quests.json")
	player = {
		"name": "The Wanderer",
		"health": 100,
		"maxHealth": 100,
		"mana": 40,
		"maxMana": 40,
		"gold": 0,
		"inventory": [],
	}
	enemy = enemies[0].duplicate(true) if not enemies.is_empty() else {
		"id": "ash_road_scout",
		"name": "Ash Road Scout",
		"health": 30,
		"maxHealth": 30,
		"defeated": false,
	}
	enemy["state"] = "idle"
	quest = quests[0].duplicate(true) if not quests.is_empty() else {}
	messages.clear()
	chest_state = "closed"
	inventory_visible = false
	selected_enemy_id = ""
	selected_item_id = ""
	quest_completion_announced = false
	add_message("The elder road is quiet. The abandoned chest waits.", "info")

func open_chest() -> void:
	if chest_state == "opened":
		add_message("The chest is already empty.", "warning")
		return
	chest_state = "opened"
	player["gold"] = int(player.get("gold", 0)) + 10
	_add_item_to_inventory("old_sword", 1)
	_add_item_to_inventory("blue_potion", 1)
	complete_quest_objective("open_chest")
	complete_quest_objective("recover_sword")
	add_message("You open the abandoned chest.", "loot")
	add_message("Recovered Old Sword, Blue Potion, and 10 gold.", "loot")
	state_changed.emit()

func select_enemy(enemy_id: String) -> void:
	if str(enemy.get("id", "")) != enemy_id:
		add_message("There is no such target.", "warning")
		return
	if bool(enemy.get("defeated", false)):
		add_message("%s is already defeated." % enemy.get("name", "The target"), "warning")
		return
	selected_enemy_id = enemy_id
	enemy["state"] = "targeted"
	add_message("%s targeted." % enemy.get("name", "Enemy"), "info")
	state_changed.emit()

func attack_selected_enemy() -> void:
	if selected_enemy_id == "":
		add_message("Select a target before attacking.", "warning")
		return
	if bool(enemy.get("defeated", false)):
		add_message("There is nothing left to attack.", "warning")
		return
	var damage := 15 if has_item("old_sword") else 10
	var old_health := int(enemy.get("health", 0))
	var new_health := maxi(0, old_health - damage)
	enemy["health"] = new_health
	enemy["state"] = "damaged" if new_health > 0 else "defeated"
	if has_item("old_sword"):
		add_message("The Old Sword bites deep for %d damage." % damage, "combat")
	else:
		add_message("You strike %s for %d damage." % [enemy.get("name", "the target"), damage], "combat")
	if new_health == 0:
		enemy["defeated"] = true
		add_message("%s is defeated." % enemy.get("name", "Enemy"), "combat")
		complete_quest_objective("defeat_scout")
	state_changed.emit()

func toggle_inventory() -> void:
	inventory_visible = not inventory_visible
	state_changed.emit()

func select_inventory_item(item_id: String) -> void:
	if not has_item(item_id):
		add_message("That item is not in your pack.", "warning")
		return
	selected_item_id = item_id
	state_changed.emit()

func add_message(text: String, type: String) -> void:
	messages.append({
		"id": "message_%d" % Time.get_ticks_msec(),
		"text": text,
		"type": type,
		"createdAt": Time.get_ticks_msec(),
	})
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()
	state_changed.emit()

func complete_quest_objective(objective_id: String) -> void:
	for objective in quest.get("objectives", []):
		if str(objective.get("id", "")) == objective_id:
			if not bool(objective.get("completed", false)):
				objective["completed"] = true
			break
	quest["completed"] = is_quest_complete()
	if bool(quest.get("completed", false)) and not quest_completion_announced:
		quest_completion_announced = true
		add_message("Quest complete: %s." % quest.get("title", "Quest"), "success")
	state_changed.emit()

func has_item(item_id: String) -> bool:
	for item in player.get("inventory", []):
		if str(item.get("id", "")) == item_id and int(item.get("quantity", 0)) > 0:
			return true
	return false

func selected_item() -> Dictionary:
	for item in player.get("inventory", []):
		if str(item.get("id", "")) == selected_item_id:
			return item
	return {}

func is_quest_complete() -> bool:
	var objectives: Array = quest.get("objectives", [])
	if objectives.is_empty():
		return false
	for objective in objectives:
		if not bool(objective.get("completed", false)):
			return false
	return true

func _add_item_to_inventory(item_id: String, quantity: int) -> void:
	var definition: Dictionary = items_by_id.get(item_id, {})
	if definition.is_empty():
		return
	var inventory: Array = player.get("inventory", [])
	if bool(definition.get("stackable", true)):
		for item in inventory:
			if str(item.get("id", "")) == item_id:
				item["quantity"] = int(item.get("quantity", 0)) + quantity
				return
	var item := definition.duplicate(true)
	item["quantity"] = quantity
	inventory.append(item)
	player["inventory"] = inventory

func _load_records_by_id(path: String) -> Dictionary:
	var by_id := {}
	for record in _load_records(path):
		var id := str(record.get("id", ""))
		if id != "":
			by_id[id] = record
	return by_id

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
