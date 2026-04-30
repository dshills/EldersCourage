extends CharacterBody2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)
signal died

const BellEffectScene := preload("res://scripts/bell_effect.gd")
const MOVE_SPEED := 260.0
const ATTACK_RANGE := 76.0
const CLEAVE_RANGE := 118.0
const ATTACK_DAMAGE := 18
const CLEAVE_DAMAGE := 25
const ATTACK_COOLDOWN := 0.45
const CLEAVE_COOLDOWN := 1.1
const GRAVE_STEP_COOLDOWN := 4.0
const BELL_COOLDOWN := 10.0
const CLEAVE_WILL_COST := 15
const GRAVE_STEP_WILL_COST := 10
const BELL_WILL_COST := 30

var max_health := 100
var current_health := 100
var max_will := 50
var current_will := 50
var armor := 0
var grave_marks := 0
var identify_scrolls := 0
var enemies: Array = []
var inventory: Array[Dictionary] = []
var equipped := {
	"weapon": {},
	"armor": {},
	"ring1": {},
	"ring2": {},
}
var attack_timer := 0.0
var cleave_timer := 0.0
var grave_step_timer := 0.0
var bell_timer := 0.0
var invulnerable_timer := 0.0
var alive := true
var facing := Vector2.RIGHT
var statuses := {}
var dot_timer := 0.0

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return

	_process_statuses(delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	cleave_timer = maxf(0.0, cleave_timer - delta)
	grave_step_timer = maxf(0.0, grave_step_timer - delta)
	bell_timer = maxf(0.0, bell_timer - delta)
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	_handle_movement()
	_handle_actions()
	move_and_slide()
	queue_redraw()

func _handle_movement() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 0.0:
		facing = input_vector.normalized()
	velocity = input_vector * MOVE_SPEED * _speed_multiplier()
	position.x = clampf(position.x, 70.0, 1210.0)
	position.y = clampf(position.y, 70.0, 650.0)

func _handle_actions() -> void:
	if Input.is_action_just_pressed("basic_attack") and attack_timer <= 0.0:
		_grave_strike()
	if Input.is_action_just_pressed("blood_cleave") and cleave_timer <= 0.0 and current_will >= CLEAVE_WILL_COST:
		_blood_cleave()
	if Input.is_action_just_pressed("grave_step") and grave_step_timer <= 0.0 and current_will >= GRAVE_STEP_WILL_COST:
		_grave_step()
	if Input.is_action_just_pressed("bell_of_the_dead") and bell_timer <= 0.0 and current_will >= BELL_WILL_COST:
		_bell_of_the_dead()

func _grave_strike() -> void:
	attack_timer = ATTACK_COOLDOWN
	var target := _nearest_enemy_in_range(ATTACK_RANGE, 0.75)
	if target == null:
		return
	var damage := ATTACK_DAMAGE + _stat_total("base_damage")
	if randf() < 0.05:
		damage = int(roundi(float(damage) * 1.5))
	target.take_damage(damage)
	current_will = mini(max_will, current_will + 5)
	damage_dealt.emit(damage, target.global_position + Vector2(0, -36), Color(0.95, 0.88, 0.65))

func _blood_cleave() -> void:
	cleave_timer = CLEAVE_COOLDOWN
	current_will -= CLEAVE_WILL_COST
	for target in enemies:
		if not is_instance_valid(target) or not target.alive:
			continue
		var to_target: Vector2 = target.global_position - global_position
		if to_target.length() <= CLEAVE_RANGE and facing.normalized().dot(to_target.normalized()) > 0.25:
			target.take_damage(CLEAVE_DAMAGE + _stat_total("base_damage"))
			target.apply_status("bleed", 3.0, 4.0)
			damage_dealt.emit(CLEAVE_DAMAGE, target.global_position + Vector2(0, -48), Color(0.95, 0.18, 0.16))

func _grave_step() -> void:
	grave_step_timer = GRAVE_STEP_COOLDOWN
	current_will -= GRAVE_STEP_WILL_COST
	invulnerable_timer = 0.35
	global_position += facing.normalized() * 155.0
	position.x = clampf(position.x, 70.0, 1210.0)
	position.y = clampf(position.y, 70.0, 650.0)

func _bell_of_the_dead() -> void:
	bell_timer = BELL_COOLDOWN
	current_will -= BELL_WILL_COST
	var bell := BellEffectScene.new()
	bell.global_position = global_position
	bell.enemies = enemies
	bell.damage_dealt.connect(func(amount: int, at_position: Vector2, color: Color) -> void:
		damage_dealt.emit(amount, at_position, color)
	)
	get_parent().add_child(bell)

func _nearest_enemy_in_range(max_range: float, min_facing_dot: float) -> Node2D:
	var best: Node2D = null
	var best_distance := max_range
	for target in enemies:
		if not is_instance_valid(target) or not target.alive:
			continue
		var offset: Vector2 = target.global_position - global_position
		var distance: float = offset.length()
		if distance <= best_distance and facing.normalized().dot(offset.normalized()) >= min_facing_dot:
			best = target
			best_distance = distance
	return best

func take_damage(amount: int) -> void:
	if not alive:
		return
	if invulnerable_timer > 0.0:
		return
	if statuses.has("vulnerable"):
		amount = int(roundi(float(amount) * (1.0 + statuses["vulnerable"]["value"])))
	amount = maxi(1, amount - armor)
	current_health = maxi(0, current_health - amount)
	damage_dealt.emit(amount, global_position + Vector2(0, -42), Color(0.92, 0.12, 0.12))
	if current_health <= 0:
		alive = false
		died.emit()

func respawn_at(respawn_position: Vector2) -> void:
	global_position = respawn_position
	current_health = max_health
	current_will = max_will
	statuses.clear()
	alive = true

func serialize_state() -> Dictionary:
	return {
		"currentHealth": current_health,
		"currentWill": current_will,
		"graveMarks": grave_marks,
		"identifyScrolls": identify_scrolls,
		"inventory": inventory,
		"equipped": equipped,
	}

func restore_state(state: Dictionary) -> void:
	inventory = []
	for item in state.get("inventory", []):
		if typeof(item) == TYPE_DICTIONARY:
			inventory.append(item.duplicate(true))
	equipped = {
		"weapon": state.get("equipped", {}).get("weapon", {}).duplicate(true),
		"armor": state.get("equipped", {}).get("armor", {}).duplicate(true),
		"ring1": state.get("equipped", {}).get("ring1", {}).duplicate(true),
		"ring2": state.get("equipped", {}).get("ring2", {}).duplicate(true),
	}
	grave_marks = int(state.get("graveMarks", grave_marks))
	identify_scrolls = int(state.get("identifyScrolls", identify_scrolls))
	_recalculate_stats()
	current_health = mini(max_health, int(state.get("currentHealth", max_health)))
	current_will = mini(max_will, int(state.get("currentWill", max_will)))

func apply_status(status_name: String, duration: float, value: float) -> void:
	statuses[status_name] = {
		"duration": duration,
		"value": value,
	}

func add_item(item: Dictionary) -> void:
	inventory.append(_prepare_item_instance(item))

func equip_inventory_index(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item := inventory[index]
	var slot := _slot_for_item(item)
	if slot == "":
		return
	if not equipped[slot].is_empty():
		inventory.append(equipped[slot])
	equipped[slot] = item
	inventory.remove_at(index)
	_recalculate_stats()

func unequip(slot: String) -> void:
	if not equipped.has(slot) or equipped[slot].is_empty():
		return
	inventory.append(equipped[slot])
	equipped[slot] = {}
	_recalculate_stats()

func _slot_for_item(item: Dictionary) -> String:
	match str(item.get("type", "")):
		"weapon":
			return "weapon"
		"armor":
			return "armor"
		"ring":
			if equipped["ring1"].is_empty():
				return "ring1"
			if equipped["ring2"].is_empty():
				return "ring2"
			return "ring1"
		_:
			return ""

func _recalculate_stats() -> void:
	var previous_max_health := max_health
	var previous_max_will := max_will
	max_health = 100 + _stat_total("max_health")
	max_will = 50 + _stat_total("max_will")
	armor = _stat_total("armor")
	current_health = mini(max_health, current_health + max_health - previous_max_health)
	current_will = mini(max_will, current_will + max_will - previous_max_will)

func _stat_total(stat_name: String) -> int:
	var total := 0
	for slot in equipped.keys():
		var item: Dictionary = equipped[slot]
		if item.is_empty():
			continue
		for stat in item.get("visibleStats", []):
			if str(stat.get("stat", "")) == stat_name:
				total += int(stat.get("value", 0))
		for stat in item.get("revealedHiddenStats", []):
			if str(stat.get("stat", "")) == stat_name:
				total += int(stat.get("value", 0))
	return total

func award_attunement_xp(amount: int) -> Array[String]:
	var messages: Array[String] = []
	for slot in equipped.keys():
		var item: Dictionary = equipped[slot]
		if item.is_empty():
			continue
		if not item.get("attunement", {}).get("enabled", false):
			continue
		var attunement: Dictionary = item["attunement"]
		attunement["xp"] = int(attunement.get("xp", 0)) + amount
		var previous_level := int(attunement.get("level", 0))
		var new_level := _attunement_level_for_xp(int(attunement["xp"]), int(attunement.get("maxLevel", 5)))
		if new_level > previous_level:
			attunement["level"] = new_level
			messages.append_array(_reveal_for_attunement(item, previous_level, new_level))
		item["attunement"] = attunement
		equipped[slot] = item
	if not messages.is_empty():
		_recalculate_stats()
	return messages

func use_identify_scroll() -> String:
	if identify_scrolls <= 0:
		return "No Identify Scrolls."
	for collection_name in ["equipped", "inventory"]:
		var result := _identify_first_unknown(collection_name)
		if result != "":
			identify_scrolls -= 1
			_recalculate_stats()
			return result
	return "No hidden item information remains unrevealed."

func _identify_first_unknown(collection_name: String) -> String:
	if collection_name == "equipped":
		for slot in equipped.keys():
			var item: Dictionary = equipped[slot]
			if item.is_empty():
				continue
			var result := _identify_item(item)
			if result != "":
				equipped[slot] = item
				return result
	else:
		for index in range(inventory.size()):
			var item: Dictionary = inventory[index]
			var result := _identify_item(item)
			if result != "":
				inventory[index] = item
				return result
	return ""

func _identify_item(item: Dictionary) -> String:
	if item.get("type", "") == "ring" and item.has("soul") and not item.get("soulRevealed", false):
		item["soulRevealed"] = true
		return "Identify revealed the soul in %s." % item.get("name", "an item")
	for stat in item.get("hiddenStats", []):
		if not _stat_revealed(item, stat):
			item["revealedHiddenStats"].append(stat)
			return "Identify revealed a hidden stat on %s." % item.get("name", "an item")
	if item.get("curse", null) != null and not item.get("curseRevealed", false):
		item["curseRevealed"] = true
		return "Identify revealed a curse on %s." % item.get("name", "an item")
	for echo in item.get("echoes", []):
		if not item["revealedEchoes"].has(echo.get("id", "")):
			item["revealedEchoes"].append(echo.get("id", ""))
			return "Identify revealed an echo on %s." % item.get("name", "an item")
	return ""

func _prepare_item_instance(item: Dictionary) -> Dictionary:
	var instance := item.duplicate(true)
	if not instance.has("revealedHiddenStats"):
		instance["revealedHiddenStats"] = []
	if not instance.has("revealedEchoes"):
		instance["revealedEchoes"] = []
	if not instance.has("curseRevealed"):
		instance["curseRevealed"] = false
	if not instance.has("soulRevealed"):
		instance["soulRevealed"] = false
	if instance.has("attunement"):
		instance["attunement"] = instance["attunement"].duplicate(true)
	return instance

func _attunement_level_for_xp(xp: int, max_level: int) -> int:
	var thresholds := [100, 250, 500, 900, 1400]
	var level := 0
	for index in range(mini(max_level, thresholds.size())):
		if xp >= thresholds[index]:
			level = index + 1
	return level

func _reveal_for_attunement(item: Dictionary, previous_level: int, new_level: int) -> Array[String]:
	var messages: Array[String] = []
	if item.has("soul") and not item.get("soulRevealed", false) and new_level >= 1:
		item["soulRevealed"] = true
		messages.append("%s reveals its bound soul." % item.get("name", "An item"))
	for stat in item.get("hiddenStats", []):
		var reveal_level := int(stat.get("attunementLevel", 999))
		if reveal_level > previous_level and reveal_level <= new_level and not _stat_revealed(item, stat):
			item["revealedHiddenStats"].append(stat)
			messages.append("%s reveals a hidden stat." % item.get("name", "An item"))
	var curse = item.get("curse", null)
	if curse != null and not item.get("curseRevealed", false):
		var curse_level := int(curse.get("revealAttunementLevel", 999))
		if curse_level > previous_level and curse_level <= new_level:
			item["curseRevealed"] = true
			messages.append("%s reveals its curse." % item.get("name", "An item"))
	for echo in item.get("echoes", []):
		var echo_level := int(echo.get("unlockAttunementLevel", 999))
		if echo_level > previous_level and echo_level <= new_level and not item["revealedEchoes"].has(echo.get("id", "")):
			item["revealedEchoes"].append(echo.get("id", ""))
			messages.append("%s reveals an echo." % item.get("name", "An item"))
	return messages

func _stat_revealed(item: Dictionary, stat: Dictionary) -> bool:
	for revealed in item.get("revealedHiddenStats", []):
		if revealed.get("stat", "") == stat.get("stat", "") and int(revealed.get("value", 0)) == int(stat.get("value", 0)):
			return true
	return false

func _process_statuses(delta: float) -> void:
	var expired: Array[String] = []
	for status_name in statuses.keys():
		statuses[status_name]["duration"] -= delta
		if statuses[status_name]["duration"] <= 0.0:
			expired.append(status_name)
	for status_name in expired:
		statuses.erase(status_name)
	dot_timer -= delta
	if dot_timer <= 0.0:
		dot_timer = 1.0
		if statuses.has("burn"):
			var burn_damage := int(statuses["burn"]["value"])
			current_health = maxi(0, current_health - burn_damage)
			damage_dealt.emit(burn_damage, global_position + Vector2(0, -50), Color(1.0, 0.45, 0.05))
			if current_health <= 0:
				alive = false
				died.emit()
		if statuses.has("bleed"):
			var bleed_damage := int(statuses["bleed"]["value"])
			current_health = maxi(0, current_health - bleed_damage)
			damage_dealt.emit(bleed_damage, global_position + Vector2(0, -50), Color(0.90, 0.05, 0.05))
			if current_health <= 0:
				alive = false
				died.emit()

func _speed_multiplier() -> float:
	if statuses.has("chill"):
		return 1.0 - statuses["chill"]["value"]
	return 1.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 22, Color(0.25, 0.42, 0.78))
	draw_line(Vector2.ZERO, facing.normalized() * 34.0, Color(0.75, 0.85, 1.0), 4.0)
	if invulnerable_timer > 0.0:
		draw_arc(Vector2.ZERO, 30, 0.0, TAU, 32, Color(0.45, 0.75, 1.0), 3.0)
	if statuses.has("burn"):
		draw_arc(Vector2.ZERO, 34, 0.0, TAU, 24, Color(1.0, 0.45, 0.05), 2.0)
	if statuses.has("chill"):
		draw_arc(Vector2.ZERO, 38, 0.0, TAU, 24, Color(0.45, 0.85, 1.0), 2.0)
	if cleave_timer > 0.85:
		draw_arc(Vector2.ZERO, CLEAVE_RANGE, -0.7, 0.7, 24, Color(0.9, 0.12, 0.12), 3.0)
