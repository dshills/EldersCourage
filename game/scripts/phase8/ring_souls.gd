extends RefCounted

const MIN_TRUST := -3
const MAX_TRUST := 3

static func create_state(soul_id: String) -> Dictionary:
	return {
		"soulId": soul_id,
		"soulRevealed": false,
		"nameRevealed": false,
		"motivationRevealed": false,
		"trust": 0,
		"memoryIdsRevealed": [],
		"whisperIdsSeen": [],
		"bargainIdsOffered": [],
		"bargainIdsAccepted": [],
		"bargainIdsRejected": [],
		"lastWhisperTurnsById": {},
	}

static func has_soul(item: Dictionary) -> bool:
	return item.has("soul") and typeof(item.get("soul")) == TYPE_DICTIONARY and str(item.get("soul", {}).get("soulId", "")) != ""

static func soul_id(item: Dictionary) -> String:
	if not has_soul(item):
		return ""
	return str(item.get("soul", {}).get("soulId", ""))

static func clamp_trust(value: int) -> int:
	return clampi(value, MIN_TRUST, MAX_TRUST)

static func adjust_trust(item: Dictionary, amount: int) -> bool:
	if not has_soul(item):
		return false
	var soul: Dictionary = item.get("soul", {})
	var old_trust := int(soul.get("trust", 0))
	soul["trust"] = clamp_trust(old_trust + amount)
	item["soul"] = soul
	return int(soul["trust"]) != old_trust

static func reveal_soul_presence(item: Dictionary) -> bool:
	if not has_soul(item):
		return false
	var soul: Dictionary = item.get("soul", {})
	if bool(soul.get("soulRevealed", false)):
		return false
	soul["soulRevealed"] = true
	item["soul"] = soul
	return true

static func reveal_soul_name(item: Dictionary) -> bool:
	if not has_soul(item):
		return false
	var changed := reveal_soul_presence(item)
	var soul: Dictionary = item.get("soul", {})
	if bool(soul.get("nameRevealed", false)):
		return changed
	soul["nameRevealed"] = true
	item["soul"] = soul
	return true

static func reveal_soul_motivation(item: Dictionary) -> bool:
	if not has_soul(item):
		return false
	var changed := reveal_soul_name(item)
	var soul: Dictionary = item.get("soul", {})
	if bool(soul.get("motivationRevealed", false)):
		return changed
	soul["motivationRevealed"] = true
	item["soul"] = soul
	return true

static func reveal_stage(item: Dictionary) -> int:
	if not has_soul(item):
		return 0
	var soul: Dictionary = item.get("soul", {})
	if bool(soul.get("motivationRevealed", false)):
		return 3
	if bool(soul.get("nameRevealed", false)):
		return 2
	if bool(soul.get("soulRevealed", false)):
		return 1
	return 0

static func mark_memory_revealed(item: Dictionary, memory_id: String) -> bool:
	if not has_soul(item) or memory_id == "":
		return false
	var soul: Dictionary = item.get("soul", {})
	var memories: Array = soul.get("memoryIdsRevealed", [])
	if memories.has(memory_id):
		return false
	memories.append(memory_id)
	soul["memoryIdsRevealed"] = memories
	item["soul"] = soul
	return true

static func mark_whisper_seen(item: Dictionary, whisper_id: String, turn: int = 0) -> bool:
	if not has_soul(item) or whisper_id == "":
		return false
	var soul: Dictionary = item.get("soul", {})
	var seen: Array = soul.get("whisperIdsSeen", [])
	var changed := false
	if not seen.has(whisper_id):
		seen.append(whisper_id)
		soul["whisperIdsSeen"] = seen
		changed = true
	var turns: Dictionary = soul.get("lastWhisperTurnsById", {})
	turns[whisper_id] = turn
	soul["lastWhisperTurnsById"] = turns
	item["soul"] = soul
	return changed

static func mark_bargain_offered(item: Dictionary, bargain_id: String) -> bool:
	return _mark_soul_list(item, "bargainIdsOffered", bargain_id)

static func mark_bargain_accepted(item: Dictionary, bargain_id: String) -> bool:
	return _mark_soul_list(item, "bargainIdsAccepted", bargain_id)

static func mark_bargain_rejected(item: Dictionary, bargain_id: String) -> bool:
	return _mark_soul_list(item, "bargainIdsRejected", bargain_id)

static func has_bargain_resolution(item: Dictionary, bargain_id: String) -> bool:
	if not has_soul(item):
		return false
	var soul: Dictionary = item.get("soul", {})
	return soul.get("bargainIdsAccepted", []).has(bargain_id) or soul.get("bargainIdsRejected", []).has(bargain_id)

static func _mark_soul_list(item: Dictionary, field: String, value: String) -> bool:
	if not has_soul(item) or value == "":
		return false
	var soul: Dictionary = item.get("soul", {})
	var values: Array = soul.get(field, [])
	if values.has(value):
		return false
	values.append(value)
	soul[field] = values
	item["soul"] = soul
	return true
