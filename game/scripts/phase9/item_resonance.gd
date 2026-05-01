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

static func process_trigger(game_state, trigger: String, context: Dictionary = {}) -> Array[Dictionary]:
	var discovered: Array[Dictionary] = []
	for resonance in get_active_resonances(game_state):
		var resonance_id := str(resonance.get("id", ""))
		if is_discovered(game_state, resonance_id):
			continue
		if not _trigger_matches(resonance, trigger, context):
			continue
		_increment_trigger_count(game_state, resonance_id, trigger)
		if not _all_requirements_met(game_state, resonance, trigger, context):
			continue
		if mark_discovered(game_state, resonance_id):
			mark_triggered(game_state, resonance_id)
			discovered.append(resonance)
	return discovered

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

static func _trigger_matches(resonance: Dictionary, trigger: String, context: Dictionary) -> bool:
	for requirement in resonance.get("discoveryRequirements", []):
		if str(requirement.get("type", "")) != trigger:
			continue
		if requirement.has("skillId") and str(requirement.get("skillId", "")) != str(context.get("skillId", "")):
			continue
		if requirement.has("curseId") and str(requirement.get("curseId", "")) != str(context.get("curseId", "")):
			continue
		return true
	return false

static func _all_requirements_met(game_state, resonance: Dictionary, trigger: String, context: Dictionary) -> bool:
	for requirement in resonance.get("discoveryRequirements", []):
		var requirement_type := str(requirement.get("type", ""))
		match requirement_type:
			"equip_together":
				if not required_items_available(game_state, resonance):
					return false
			"items_identified":
				if not _all_required_items_identified(game_state, resonance):
					return false
			"skill_use":
				if trigger == "skill_use" and requirement.has("skillId") and str(requirement.get("skillId", "")) != str(context.get("skillId", "")):
					return false
			"enemy_defeated":
				var required_class := str(requirement.get("classId", ""))
				if required_class != "" and required_class != str(game_state.player.get("classId", "")):
					continue
				var required_count := int(requirement.get("count", 1))
				if _trigger_count(game_state, str(resonance.get("id", "")), "enemy_defeated") < required_count:
					return false
				return true
			"curse_trigger":
				if trigger == "curse_trigger" and requirement.has("curseId") and str(requirement.get("curseId", "")) != str(context.get("curseId", "")):
					return false
			"blood_price_revealed":
				if not game_state.item_has_revealed_property("phase5_ashen_ring", "phase5_ashen_ring_blood_price"):
					return false
	return true

static func _all_required_items_identified(game_state, resonance: Dictionary) -> bool:
	for item_id in resonance.get("requiredItemIds", []):
		var item: Dictionary = game_state.first_inventory_item_by_item_id(str(item_id))
		if item.is_empty():
			return false
		if str(item.get("knowledgeState", "known")) == "unidentified":
			return false
	return true

static func _increment_trigger_count(game_state, resonance_id: String, trigger: String) -> void:
	var counts: Dictionary = game_state.resonance.get("triggerCounts", {})
	var key := "%s:%s" % [resonance_id, trigger]
	counts[key] = int(counts.get(key, 0)) + 1
	game_state.resonance["triggerCounts"] = counts

static func _trigger_count(game_state, resonance_id: String, trigger: String) -> int:
	return int(game_state.resonance.get("triggerCounts", {}).get("%s:%s" % [resonance_id, trigger], 0))
