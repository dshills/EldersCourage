extends RefCounted

var items_by_id := {}
var curses_by_id := {}
var loot_tables := {}
var loot_drops: Array[Dictionary] = []
var total_loot_weight := 0

func load_data() -> void:
	_load_curse_file("res://data/curses/curses.json")
	_load_item_file("res://data/items/starter_items.json")
	_load_item_file("res://data/items/accursed_rings.json")
	_load_item_file("res://data/items/phase7_items.json")
	_load_item_file("res://data/items/phase1_required_items.json")
	_load_loot_file("res://data/loot/arena_loot.json")

func get_item(item_id: String) -> Dictionary:
	return items_by_id.get(item_id, {}).duplicate(true)

func random_loot_item(loot_table_id := "") -> Dictionary:
	var drops := loot_drops
	var weight := total_loot_weight
	if loot_table_id != "" and loot_tables.has(loot_table_id):
		var table: Dictionary = loot_tables[loot_table_id]
		drops = table.get("drops", [])
		weight = int(table.get("totalWeight", 0))
	if drops.is_empty() or weight <= 0:
		return {}
	var roll := randi_range(1, weight)
	var cursor := 0
	for drop in drops:
		cursor += int(drop.get("weight", 1))
		if roll <= cursor:
			return get_item(str(drop.get("itemId", "")))
	return get_item(str(drops.back().get("itemId", "")))

func _load_item_file(path: String) -> void:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Item file must contain an array: %s" % path)
		return
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			_hydrate_item_curse(item)
			items_by_id[item["id"]] = item

func _load_curse_file(path: String) -> void:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Curse file must contain an array: %s" % path)
		return
	for curse in parsed:
		if typeof(curse) == TYPE_DICTIONARY and curse.has("id"):
			curses_by_id[str(curse["id"])] = curse

func _hydrate_item_curse(item: Dictionary) -> void:
	var item_curse = item.get("curse", null)
	if item_curse == null or typeof(item_curse) != TYPE_DICTIONARY:
		return
	var curse_id := str(item_curse.get("id", ""))
	if curse_id == "" or not curses_by_id.has(curse_id):
		return
	var definition: Dictionary = curses_by_id[curse_id]
	var reveal_level := int(item_curse.get("revealAttunementLevel", definition.get("revealAttunementLevel", 3)))
	var description := str(item_curse.get("description", definition.get("description", "")))
	item["curse"] = definition.duplicate(true)
	item["curse"]["revealAttunementLevel"] = reveal_level
	if description != "":
		item["curse"]["description"] = description

func _load_loot_file(path: String) -> void:
	var payload := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("drops"):
		push_error("Loot file must contain drops: %s" % path)
		return
	var table_id := str(parsed.get("id", ""))
	var table_drops: Array[Dictionary] = []
	var table_weight := 0
	for raw_drop in parsed["drops"]:
		var item_id := ""
		var weight := 1
		if typeof(raw_drop) == TYPE_DICTIONARY:
			item_id = str(raw_drop.get("itemId", ""))
			weight = maxi(1, int(raw_drop.get("weight", 1)))
		else:
			item_id = str(raw_drop)
		if items_by_id.has(item_id):
			var drop := { "itemId": item_id, "weight": weight }
			loot_drops.append(drop)
			total_loot_weight += weight
			table_drops.append(drop)
			table_weight += weight
	if table_id != "":
		loot_tables[table_id] = { "drops": table_drops, "totalWeight": table_weight }
