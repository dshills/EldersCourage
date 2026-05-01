extends RefCounted

static func create_state() -> Dictionary:
	return {
		"discoveredResonanceIds": [],
		"triggeredResonanceIds": [],
		"rejectedResonanceIds": [],
		"mergeRecipeIdsDiscovered": [],
		"triggerCounts": {},
	}

static func get_active_resonances(game_state) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for resonance in game_state.item_resonances_by_id.values():
		if required_items_available(game_state, resonance):
			result.append(resonance)
	return result

static func get_discovered_active_resonances(game_state) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for resonance in get_active_resonances(game_state):
		if is_discovered(game_state, str(resonance.get("id", ""))):
			result.append(resonance)
	return result

static func get_hinted_resonances(game_state) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for resonance in get_active_resonances(game_state):
		if is_discovered(game_state, str(resonance.get("id", ""))):
			continue
		if str(resonance.get("visibility", "")) == "hinted" or str(resonance.get("visibility", "")) == "visible":
			result.append(resonance)
	return result

static func is_discovered(game_state, resonance_id: String) -> bool:
	return game_state.resonance.get("discoveredResonanceIds", []).has(resonance_id)

static func mark_discovered(game_state, resonance_id: String) -> bool:
	if resonance_id == "" or is_discovered(game_state, resonance_id):
		return false
	var discovered: Array = game_state.resonance.get("discoveredResonanceIds", [])
	discovered.append(resonance_id)
	game_state.resonance["discoveredResonanceIds"] = discovered
	return true

static func mark_triggered(game_state, resonance_id: String) -> bool:
	if resonance_id == "":
		return false
	var triggered: Array = game_state.resonance.get("triggeredResonanceIds", [])
	if triggered.has(resonance_id):
		return false
	triggered.append(resonance_id)
	game_state.resonance["triggeredResonanceIds"] = triggered
	return true

static func required_items_available(game_state, resonance: Dictionary) -> bool:
	var required: Array = resonance.get("requiredItemIds", [])
	if required.is_empty():
		return false
	for item_id in required:
		if not game_state.has_item(str(item_id)):
			return false
	var equipped_required := 0
	for item in game_state.equipped_items():
		if required.has(str(item.get("itemId", ""))):
			equipped_required += 1
	return equipped_required > 0 and _equipped_slots_match(game_state, resonance)

static func _equipped_slots_match(game_state, resonance: Dictionary) -> bool:
	var slots: Array = resonance.get("requiredEquippedSlots", [])
	if slots.is_empty():
		return true
	var slot_counts := {}
	for slot in slots:
		slot_counts[str(slot)] = int(slot_counts.get(str(slot), 0)) + 1
	for slot in slot_counts.keys():
		var equipped: Dictionary = game_state.equipped_item(str(slot))
		if equipped.is_empty():
			return false
		var required: Array = resonance.get("requiredItemIds", [])
		if not required.has(str(equipped.get("itemId", ""))):
			return false
		# The current game has one trinket slot. Duplicate trinket requirements mean
		# one required trinket must be equipped and the other may be carried.
		if int(slot_counts[slot]) > 1 and slot != "trinket":
			return false
	return true
