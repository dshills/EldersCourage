extends RefCounted

static func get_header_view_model(game_state) -> Dictionary:
	var player: Dictionary = game_state.player
	return {
		"zone": str(game_state.zone.get("name", "Elder Road Outskirts")),
		"className": str(game_state.current_class().get("name", "Choose Class")),
		"level": int(player.get("level", 1)),
		"xp": int(player.get("xp", 0)),
		"xpToNextLevel": int(player.get("xpToNextLevel", 50)),
		"talentPoints": int(player.get("talents", {}).get("availablePoints", 0)),
		"gold": int(player.get("gold", 0)),
		"debugVisible": bool(game_state.ui.get("debugMode", false)),
		"debugText": _debug_text(game_state),
	}

static func get_visible_messages(game_state, limit := 5) -> Array:
	var visible: Array = game_state.messages.duplicate()
	visible.reverse()
	return visible.slice(0, mini(limit, visible.size()))

static func get_action_availability_view_model(game_state) -> Dictionary:
	var tile: Dictionary = game_state.current_tile()
	var class_selected: bool = bool(game_state.class_selected)
	var container_available: bool = class_selected and tile.has("containerId") and not bool(game_state.containers_by_id.get(str(tile.get("containerId", "")), {}).get("opened", false))
	var shrine_available: bool = class_selected and tile.has("shrineId") and not bool(game_state.shrines_by_id.get(str(tile.get("shrineId", "")), {}).get("activated", false))
	var enemy_available: bool = class_selected and not bool(game_state.defeated) and (not game_state.active_enemy.is_empty() or tile.has("encounterId"))
	var transition: Dictionary = game_state.can_transition_from_current_tile()
	var primary_label := "Open Container"
	var primary_enabled := container_available
	var primary_reason := "" if container_available else "No location action here."
	if bool(transition.get("available", false)):
		primary_label = str(transition.get("label", "Travel"))
		primary_enabled = bool(transition.get("enabled", false))
		primary_reason = str(transition.get("reason", "The path is blocked."))
	elif container_available:
		primary_label = "Open Container"
	elif tile.has("hazardId"):
		primary_label = "Inspect Hazard"
		primary_enabled = true
		primary_reason = ""
	elif str(tile.get("kind", "")) == "cairn":
		primary_label = "Investigate Cairn"
		primary_enabled = true
		primary_reason = ""
	return {
		"container": { "enabled": primary_enabled, "reason": primary_reason, "label": primary_label },
		"shrine": { "enabled": shrine_available, "reason": "" if shrine_available else "No unused shrine here." },
		"attack": { "enabled": enemy_available, "reason": "" if enemy_available else "No active enemy target." },
		"restartVisible": bool(game_state.defeated) or bool(game_state.zone.get("completed", false)),
	}

static func get_skill_button_view_models(game_state) -> Array:
	var models: Array = []
	for skill_id in game_state.player.get("skills", {}).get("knownSkillIds", []):
		var id := str(skill_id)
		var skill: Dictionary = game_state.skills_by_id.get(id, {})
		if skill.is_empty():
			continue
		var cooldown: int = int(game_state.player.get("skills", {}).get("cooldowns", {}).get(id, 0))
		var cost: int = game_state.effective_skill_cost(skill)
		var disabled_reason := _skill_disabled_reason(game_state, skill, cooldown, cost)
		var secondary := "CD %d" % cooldown if cooldown > 0 else ("%d Mana" % cost if str(skill.get("resource", "")) == "mana" and cost > 0 else "Ready")
		if disabled_reason != "":
			secondary = disabled_reason
		models.append({
			"id": id,
			"name": str(skill.get("name", id)),
			"sublabel": secondary,
			"disabled": disabled_reason != "",
			"disabledReason": disabled_reason,
			"tooltip": _skill_tooltip(skill, cooldown, cost, disabled_reason),
		})
	return models

static func get_location_details_view_model(game_state) -> Dictionary:
	var tile: Dictionary = game_state.current_tile()
	var actions := _current_location_actions(game_state, tile)
	return {
		"name": str(tile.get("name", "Unknown Road")),
		"description": _location_description(game_state, tile),
		"exits": _current_exits(game_state),
		"actions": actions,
		"available": ", ".join(actions) if not actions.is_empty() else "None",
		"status": _tile_status(game_state, tile),
	}

static func get_tile_view_model(game_state, tile: Dictionary) -> Dictionary:
	var position := _tile_position(tile)
	var player_position: Dictionary = game_state.player.get("position", {})
	var is_current := position.x == int(player_position.get("x", 0)) and position.y == int(player_position.get("y", 0))
	var marker := _tile_marker(game_state, tile)
	return {
		"name": str(tile.get("name", "Tile")),
		"marker": marker,
		"current": is_current,
		"label": "%s%s\n%s" % ["YOU\n" if is_current else "", tile.get("name", "Tile"), marker],
		"tooltip": "%s\n%s" % [tile.get("name", "Tile"), _location_description(game_state, tile)],
	}

static func _debug_text(game_state) -> String:
	var position: Dictionary = game_state.player.get("position", {})
	var tile: Dictionary = game_state.current_tile()
	return "Position %d,%d | Tile %s | Encounter %s" % [
		int(position.get("x", 0)),
		int(position.get("y", 0)),
		tile.get("id", "unknown"),
		tile.get("encounterId", "none"),
	]

static func _skill_disabled_reason(game_state, skill: Dictionary, cooldown: int, cost: int) -> String:
	if game_state.active_enemy.is_empty() and str(skill.get("targetType", "")) == "enemy" and not game_state.current_tile().has("encounterId"):
		return "Need target"
	if cooldown > 0:
		return "CD %d" % cooldown
	if str(skill.get("resource", "")) == "mana" and int(game_state.player.get("mana", 0)) < cost:
		return "Need %d Mana" % cost
	return ""

static func _skill_tooltip(skill: Dictionary, cooldown: int, cost: int, disabled_reason: String) -> String:
	var lines: Array[String] = [
		str(skill.get("description", "")),
		"Cost: %d Mana" % cost if str(skill.get("resource", "")) == "mana" else "Cost: None",
		"Cooldown: %s" % ("None" if int(skill.get("cooldownTurns", 0)) == 0 else "%d turns" % int(skill.get("cooldownTurns", 0))),
	]
	if cooldown > 0:
		lines.append("Current cooldown: %d" % cooldown)
	if disabled_reason != "":
		lines.append("Unavailable: %s" % disabled_reason)
	return "\n".join(lines)

static func _current_exits(game_state) -> Array[String]:
	var exits: Array[String] = []
	var position: Dictionary = game_state.player.get("position", {})
	for direction in ["north", "south", "east", "west"]:
		var target := position.duplicate()
		match direction:
			"north":
				target["y"] = int(target["y"]) - 1
			"south":
				target["y"] = int(target["y"]) + 1
			"east":
				target["x"] = int(target["x"]) + 1
			"west":
				target["x"] = int(target["x"]) - 1
		var tile: Dictionary = game_state.tile_at(target)
		if not tile.is_empty() and not bool(tile.get("blocksMovement", false)):
			exits.append(direction.capitalize())
	return exits

static func _current_location_actions(game_state, tile: Dictionary) -> Array[String]:
	var actions: Array[String] = []
	if tile.has("containerId"):
		var container: Dictionary = game_state.containers_by_id.get(str(tile["containerId"]), {})
		actions.append("Container opened" if bool(container.get("opened", false)) else "Open Container")
	if tile.has("shrineId"):
		var shrine: Dictionary = game_state.shrines_by_id.get(str(tile["shrineId"]), {})
		actions.append("Shrine spent" if bool(shrine.get("activated", false)) else "Activate Shrine")
	if tile.has("encounterId") and not game_state.completed_encounters.has(str(tile["encounterId"])):
		actions.append("Enemy nearby")
	if bool(game_state.can_transition_from_current_tile().get("available", false)):
		actions.append(str(game_state.can_transition_from_current_tile().get("label", "Travel")))
	if tile.has("hazardId"):
		actions.append("Hazard")
	if str(tile.get("kind", "")) == "cairn":
		actions.append("Investigate Cairn")
	if str(tile.get("kind", "")) == "elder_stone":
		actions.append("Quest objective")
	return actions

static func _location_description(game_state, tile: Dictionary) -> String:
	if tile.has("containerId"):
		var container: Dictionary = game_state.containers_by_id.get(str(tile["containerId"]), {})
		if bool(container.get("opened", false)):
			return "The cache hangs open. Whatever courage it held is now yours."
	if tile.has("shrineId"):
		var shrine: Dictionary = game_state.shrines_by_id.get(str(tile["shrineId"]), {})
		if bool(shrine.get("activated", false)):
			return "The shrine is quiet now, its old light spent."
	if tile.has("encounterId") and game_state.completed_encounters.has(str(tile["encounterId"])):
		return "The road is still scarred by combat, but the threat has ended."
	if tile.has("hazardId") and game_state.completed_hazards.has(str(tile["hazardId"])):
		return "The danger here has already spent itself."
	return str(tile.get("description", "The Elder Road waits in ash and old stone."))

static func _tile_marker(game_state, tile: Dictionary) -> String:
	if tile.has("encounterId") and not game_state.completed_encounters.has(str(tile["encounterId"])):
		return "Enemy"
	if tile.has("hazardId"):
		return "Cleared Hazard" if game_state.completed_hazards.has(str(tile["hazardId"])) else "Hazard"
	if tile.has("transition"):
		return "Travel"
	if str(tile.get("kind", "")) == "cairn":
		return "Lore"
	if tile.has("containerId"):
		var container: Dictionary = game_state.containers_by_id.get(str(tile["containerId"]), {})
		return "Opened Cache" if bool(container.get("opened", false)) else "Cache"
	if tile.has("shrineId"):
		var shrine: Dictionary = game_state.shrines_by_id.get(str(tile["shrineId"]), {})
		return "Spent Shrine" if bool(shrine.get("activated", false)) else "Shrine"
	if str(tile.get("kind", "")) == "elder_stone":
		return "Objective"
	return "Road"

static func _tile_status(game_state, tile: Dictionary) -> String:
	if tile.has("encounterId") and game_state.completed_encounters.has(str(tile["encounterId"])):
		return "Cleared"
	if tile.has("hazardId"):
		return "Cleared" if game_state.completed_hazards.has(str(tile["hazardId"])) else "Danger"
	if tile.has("containerId"):
		var container: Dictionary = game_state.containers_by_id.get(str(tile["containerId"]), {})
		return "Opened" if bool(container.get("opened", false)) else "Unopened"
	if tile.has("shrineId"):
		var shrine: Dictionary = game_state.shrines_by_id.get(str(tile["shrineId"]), {})
		return "Spent" if bool(shrine.get("activated", false)) else "Ready"
	return "Visited" if str(tile.get("state", "")) == "visited" else "Unvisited"

static func _tile_position(tile: Dictionary) -> Vector2i:
	var raw: Array = tile.get("position", [0, 0])
	return Vector2i(int(raw[0]), int(raw[1]))
