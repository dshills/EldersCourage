extends RefCounted

static func get_available_recipes(game_state) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe in game_state.item_merges_by_id.values():
		if can_merge(game_state, recipe):
			result.append(recipe)
	return result

static func get_hinted_recipes(game_state) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe in game_state.item_merges_by_id.values():
		if can_merge(game_state, recipe) or _has_required_items(game_state, recipe):
			if str(recipe.get("visibility", "")) == "hinted" or str(recipe.get("visibility", "")) == "visible":
				result.append(recipe)
	return result

static func can_merge(game_state, recipe: Dictionary) -> bool:
	if recipe.is_empty() or not _has_required_items(game_state, recipe):
		return false
	for condition in recipe.get("requiredConditions", []):
		match str(condition.get("type", "")):
			"resonance_discovered":
				if not game_state.is_resonance_discovered(str(condition.get("resonanceId", ""))):
					return false
			"attunement_level":
				var item: Dictionary = game_state.first_inventory_item_by_item_id(str(condition.get("itemId", "")))
				if item.is_empty() or int(item.get("attunement", {}).get("level", 0)) < int(condition.get("value", 0)):
					return false
			"soul_name_revealed":
				if not _soul_name_revealed(game_state, str(condition.get("soulId", ""))):
					return false
	return true

static func _has_required_items(game_state, recipe: Dictionary) -> bool:
	for item_id in recipe.get("requiredItemIds", []):
		if not game_state.has_item(str(item_id)):
			return false
	return true

static func _soul_name_revealed(game_state, soul_id: String) -> bool:
	for item in game_state.player.get("inventory", []):
		var soul: Dictionary = item.get("soul", {})
		if str(soul.get("soulId", "")) == soul_id and bool(soul.get("nameRevealed", false)):
			return true
	return false
