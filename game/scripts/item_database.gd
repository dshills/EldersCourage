extends RefCounted

var items_by_id := {}
var loot_ids: Array[String] = []

func load_data() -> void:
	_load_item_file("res://data/items/starter_items.json")
	_load_item_file("res://data/items/accursed_rings.json")
	_load_loot_file("res://data/loot/arena_loot.json")

func get_item(item_id: String) -> Dictionary:
	return items_by_id.get(item_id, {}).duplicate(true)

func random_loot_item() -> Dictionary:
	if loot_ids.is_empty():
		return {}
	return get_item(loot_ids.pick_random())

func _load_item_file(path: String) -> void:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Item file must contain an array: %s" % path)
		return
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			items_by_id[item["id"]] = item

func _load_loot_file(path: String) -> void:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("drops"):
		push_error("Loot file must contain drops: %s" % path)
		return
	for item_id in parsed["drops"]:
		if items_by_id.has(item_id):
			loot_ids.append(item_id)
