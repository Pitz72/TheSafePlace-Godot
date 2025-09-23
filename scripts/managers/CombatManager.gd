extends Node

## CombatManager Singleton - The Safe Place v0.4.1
##
## Gestisce il sistema di combattimento turn-based con armi, armature e skill check
## Implementa il sistema combattimento del GDD React adattato per Godot
##
## Architettura: Singleton (Autoload) per gestione globale combattimento

# ========================================
# ENUM E COSTANTI
# ========================================

enum CombatState {
	IDLE = 0,
	INITIALIZING = 1,
	PLAYER_TURN = 2,
	ENEMY_TURN = 3,
	RESOLVING = 4,
	COMPLETED = 5
}

enum CombatResult {
	ONGOING = 0,
	PLAYER_VICTORY = 1,
	ENEMY_VICTORY = 2,
	PLAYER_FLED = 3,
	TIMEOUT = 4
}

enum CombatAction {
	ATTACK = 0,
	DEFEND = 1,
	USE_ITEM = 2,
	FLEE = 3,
	SPECIAL = 4
}

# ========================================
# SEGNALI PUBBLICI
# ========================================

signal combat_started(enemy_data: Dictionary)
signal combat_ended(result: CombatResult, rewards: Dictionary)
signal turn_changed(new_state: CombatState)
signal damage_dealt(target: String, amount: int, is_critical: bool)
signal combat_action_performed(action: String, success: bool)
signal enemy_defeated(enemy_id: String)
signal player_defeated()
signal combat_log_updated(message: String)

# ========================================
# VARIABILI STATO COMBATTIMENTO
# ========================================

## Stato corrente del combattimento
var current_combat_state: CombatState = CombatState.IDLE

## Dati del nemico corrente
var current_enemy: Dictionary = {}

## Turno corrente
var is_player_turn: bool = true

## Azioni disponibili per il giocatore
var available_actions: Array[CombatAction] = [CombatAction.ATTACK, CombatAction.DEFEND, CombatAction.USE_ITEM, CombatAction.FLEE]

## Sistema difesa giocatore
var player_defense_bonus: int = 0
var player_defense_turns_remaining: int = 0

## Sistema difesa nemico
var enemy_defense_bonus: int = 0
var enemy_defense_turns_remaining: int = 0

## Log del combattimento
var combat_log: Array[String] = []

## Statistiche combattimento
var combat_stats: Dictionary = {
	"rounds": 0,
	"player_damage_dealt": 0,
	"enemy_damage_dealt": 0,
	"player_hits": 0,
	"enemy_hits": 0,
	"items_used": 0,
	"special_actions_used": 0
}

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("⚔️ CombatManager: Inizializzazione sistema combattimento...")
	print("✅ CombatManager: Sistema combattimento pronto")

# ========================================
# API COMBATTIMENTO PRINCIPALE
# ========================================

## Inizia un combattimento con un nemico
func start_combat(enemy_id: String) -> bool:
	if current_combat_state != CombatState.IDLE:
		print("⚔️ CombatManager: Impossibile iniziare combattimento - già in corso")
		return false

	# Ottieni dati nemico dal database
	current_enemy = _get_enemy_data(enemy_id)
	if current_enemy.is_empty():
		print("⚔️ CombatManager: Nemico non trovato: %s" % enemy_id)
		return false

	# Inizializza stato combattimento
	current_combat_state = CombatState.INITIALIZING
	is_player_turn = true
	combat_log.clear()
	combat_stats = {
		"rounds": 0,
		"player_damage_dealt": 0,
		"enemy_damage_dealt": 0,
		"player_hits": 0,
		"enemy_hits": 0
	}

	# Log inizio combattimento
	_log_combat_event("Combattimento iniziato contro %s!" % current_enemy.get("name", "Nemico Sconosciuto"))

	combat_started.emit(current_enemy)
	current_combat_state = CombatState.PLAYER_TURN
	turn_changed.emit(CombatState.PLAYER_TURN)

	print("⚔️ CombatManager: Combattimento iniziato contro %s" % enemy_id)
	return true

## Esegue un'azione del giocatore
func perform_player_action(action: CombatAction, target: String = "") -> bool:
	if current_combat_state != CombatState.PLAYER_TURN:
		print("⚔️ CombatManager: Non è il turno del giocatore")
		return false

	if not action in available_actions:
		print("⚔️ CombatManager: Azione non disponibile: %s" % action)
		combat_action_performed.emit(action, false)
		return false

	var success = false

	match action:
		CombatAction.ATTACK:
			success = _perform_attack()
		CombatAction.DEFEND:
			success = _perform_defend()
		CombatAction.USE_ITEM:
			success = _perform_use_item(target)
		CombatAction.FLEE:
			success = _perform_flee()
		CombatAction.SPECIAL:
			success = _perform_special_action()

	combat_action_performed.emit(action, success)

	if success:
		_check_combat_end()

	return success

## Termina il combattimento corrente
func end_combat(result: CombatResult, rewards: Dictionary = {}) -> void:
	if current_combat_state == CombatState.IDLE:
		return

	current_combat_state = CombatState.COMPLETED
	combat_ended.emit(result, rewards)

	# Reset stato
	current_enemy.clear()
	is_player_turn = true
	current_combat_state = CombatState.IDLE

	print("⚔️ CombatManager: Combattimento terminato con risultato: %d" % result)

# ========================================
# LOGICA AZIONI COMBATTIMENTO
# ========================================

## Esegue un attacco
func _perform_attack() -> bool:
	var weapon_damage = _calculate_weapon_damage()
	var hit_chance = _calculate_hit_chance()

	# Skill check per colpire
	var hit_check = SkillCheckManager.perform_check("agilita", hit_chance)

	if hit_check.success:
		# Calcola danno
		var damage = weapon_damage.base_damage + randi_range(weapon_damage.dice_min, weapon_damage.dice_max)

		# Applica modificatori
		damage += int(PlayerManager.get_stat("forza") / 2.0)  # Modificatore forza

		# Difesa nemico
		var enemy_defense = current_enemy.get("defense", 0)
		damage = max(1, damage - enemy_defense)

		# Applica danno
		current_enemy.hp = max(0, current_enemy.hp - damage)

		_log_combat_event("Colpisci %s per %d danni!" % [current_enemy["name"], damage])
		damage_dealt.emit("enemy", damage, hit_check.roll == 20)  # Critical se 20 naturale

		combat_stats.player_damage_dealt += damage
		combat_stats.player_hits += 1

		# Passa turno al nemico
		_end_player_turn()
		return true
	else:
		_log_combat_event("Mancato! Il colpo va a vuoto.")
		_end_player_turn()
		return true

## Esegue una difesa
func _perform_defend() -> bool:
	# Calcola bonus difesa basato su armatura
	var armor_defense = _calculate_armor_defense()
	var defense_bonus = max(2, int(armor_defense * 0.5))  # Almeno +2, o 50% armatura

	player_defense_bonus = defense_bonus
	player_defense_turns_remaining = 1  # Durata 1 turno

	_log_combat_event("Ti prepari a difenderti! (Difesa +%d per il prossimo turno nemico)" % defense_bonus)
	_end_player_turn()
	return true

## Tenta la fuga
func _perform_flee() -> bool:
	var flee_chance = 50  # Base 50% chance

	# Modificatori basati su agilità
	var agility_mod = PlayerManager.get_stat("agilita") - 10
	flee_chance += agility_mod * 5  # +5% per punto di agilità sopra 10

	flee_chance = clamp(flee_chance, 10, 90)  # Limiti 10%-90%

	if randi() % 100 < flee_chance:
		_log_combat_event("Riesci a fuggire dal combattimento!")
		end_combat(CombatResult.PLAYER_FLED)
		return true
	else:
		_log_combat_event("Tentativo di fuga fallito!")
		_end_player_turn()
		return true

## Usa un oggetto in combattimento
func _perform_use_item(item_id: String) -> bool:
	if not PlayerManager.has_item(item_id):
		_log_combat_event("Non possiedi questo oggetto!")
		return false

	var item_data = DataManager.get_item_data(item_id)
	if item_data.is_empty():
		_log_combat_event("Oggetto non valido!")
		return false

	# Verifica che sia un consumabile
	if item_data.get("category") != "CONSUMABLE":
		_log_combat_event("Puoi usare solo consumabili in combattimento!")
		return false

	# Applica effetti dell'oggetto
	var effects = item_data.get("properties", {}).get("effects", [])
	var success = false

	for effect in effects:
		var effect_type = effect.get("effect_type", "")
		var amount = effect.get("amount", 0)

		match effect_type:
			"heal":
				if PlayerManager.hp < PlayerManager.max_hp:
					PlayerManager.modify_hp(amount)
					_log_combat_event("Ti curi di %d HP!" % amount)
					success = true
			"nourish":
				PlayerManager.modify_food(amount)
				_log_combat_event("Ti senti più energico!")
				success = true
			"hydrate":
				PlayerManager.modify_water(amount)
				_log_combat_event("Ti senti idratato!")
				success = true

	if success:
		# Rimuovi l'oggetto dall'inventario
		PlayerManager.remove_item(item_id, 1)
		combat_stats.items_used += 1
		_end_player_turn()
		return true
	else:
		_log_combat_event("L'oggetto non ha effetto in combattimento!")
		return false

## Esegue un'azione speciale basata sull'equipaggiamento
func _perform_special_action() -> bool:
	var weapon = PlayerManager.equipped_weapon
	if weapon.is_empty():
		_log_combat_event("Hai bisogno di un'arma equipaggiata per azioni speciali!")
		return false

	# Controlla proprietà speciali dell'arma
	var properties = weapon.get("properties", {})
	var effects = properties.get("effects", [])

	for effect in effects:
		var effect_type = effect.get("effect_type", "")
		match effect_type:
			"bleeding_edge":
				return _perform_bleeding_attack()
			"armor_piercing":
				return _perform_armor_piercing_attack()
			"high_critical":
				return _perform_high_crit_attack()

	_log_combat_event("La tua arma non ha abilità speciali!")
	return false

## Attacco con effetto bleeding
func _perform_bleeding_attack() -> bool:
	var weapon_damage = _calculate_weapon_damage()
	var hit_chance = _calculate_hit_chance()

	var hit_check = SkillCheckManager.perform_check("agilita", hit_chance)

	if hit_check.success:
		var damage = weapon_damage.base_damage + randi_range(weapon_damage.dice_min, weapon_damage.dice_max)
		var stat_modifier = PlayerManager.get_stat("forza") / 2
		damage += int(stat_modifier)

		# Riduzione difesa nemico
		var enemy_defense = current_enemy.get("defense", 0) + enemy_defense_bonus
		damage = max(1, damage - enemy_defense)

		# Applica danno con possibilità di bleeding
		current_enemy.hp = max(0, current_enemy.hp - damage)

		_log_combat_event("Colpisci con taglio profondo per %d danni! Il nemico sanguina!" % damage)
		damage_dealt.emit("enemy", damage, hit_check.roll == 20)

		combat_stats.player_damage_dealt += damage
		combat_stats.player_hits += 1
		combat_stats.special_actions_used += 1

		_end_player_turn()
		return true
	else:
		_log_combat_event("Il colpo speciale manca il bersaglio!")
		_end_player_turn()
		return true

## Attacco perforante
func _perform_armor_piercing_attack() -> bool:
	var weapon_damage = _calculate_weapon_damage()
	var hit_chance = _calculate_hit_chance() + 2  # +2 per precisione

	var hit_check = SkillCheckManager.perform_check("agilita", hit_chance)

	if hit_check.success:
		var damage = weapon_damage.base_damage + randi_range(weapon_damage.dice_min, weapon_damage.dice_max)
		var stat_modifier = PlayerManager.get_stat("forza") / 2
		damage += int(stat_modifier)

		# Riduzione minima della difesa (ignora 50% armatura)
		var enemy_defense = current_enemy.get("defense", 0) + enemy_defense_bonus
		var piercing_damage = int(enemy_defense * 0.5)
		damage = max(1, damage - piercing_damage)

		current_enemy.hp = max(0, current_enemy.hp - damage)

		_log_combat_event("Perfori l'armatura nemica per %d danni!" % damage)
		damage_dealt.emit("enemy", damage, hit_check.roll == 20)

		combat_stats.player_damage_dealt += damage
		combat_stats.player_hits += 1
		combat_stats.special_actions_used += 1

		_end_player_turn()
		return true
	else:
		_log_combat_event("Il colpo perforante manca il bersaglio!")
		_end_player_turn()
		return true

## Attacco con alto critico
func _perform_high_crit_attack() -> bool:
	var weapon_damage = _calculate_weapon_damage()
	var hit_chance = _calculate_hit_chance() - 2  # -2 per rischio

	var hit_check = SkillCheckManager.perform_check("agilita", hit_chance)

	if hit_check.success:
		var damage = weapon_damage.base_damage + randi_range(weapon_damage.dice_min, weapon_damage.dice_max)
		var stat_modifier = PlayerManager.get_stat("forza") / 2
		damage += int(stat_modifier)

		# Riduzione difesa nemico
		var enemy_defense = current_enemy.get("defense", 0) + enemy_defense_bonus
		damage = max(1, damage - enemy_defense)

		# Se critico (20 naturale), triplica danno
		var is_crit = hit_check.roll == 20
		if is_crit:
			damage *= 3
			_log_combat_event("COLPO CRITICO! %d danni devastanti!" % damage)
		else:
			_log_combat_event("Colpisci con precisione per %d danni!" % damage)

		current_enemy.hp = max(0, current_enemy.hp - damage)
		damage_dealt.emit("enemy", damage, is_crit)

		combat_stats.player_damage_dealt += damage
		combat_stats.player_hits += 1
		combat_stats.special_actions_used += 1

		_end_player_turn()
		return true
	else:
		_log_combat_event("Il colpo di precisione manca il bersaglio!")
		_end_player_turn()
		return true

## Esegue il turno del nemico
func _perform_enemy_turn() -> void:
	current_combat_state = CombatState.ENEMY_TURN

	# Applica e decrementa bonus difesa giocatore
	var player_defense_reduction = 0
	if player_defense_turns_remaining > 0:
		player_defense_reduction = player_defense_bonus
		player_defense_turns_remaining -= 1
		if player_defense_turns_remaining <= 0:
			player_defense_bonus = 0

	# Logica semplice nemico: sempre attacca
	var enemy_damage = current_enemy.get("damage", 5)
	var hit_chance = current_enemy.get("accuracy", 12)

	# Skill check nemico (usando fortuna del giocatore come difesa)
	var enemy_hit_check = SkillCheckManager.perform_check("fortuna", hit_chance)

	if enemy_hit_check.success:
		# Calcola danno con difesa armatura + bonus difesa
		var armor_defense = _calculate_armor_defense()
		var total_defense = armor_defense + player_defense_reduction
		var actual_damage = max(1, enemy_damage - total_defense)

		# Applica danno al giocatore
		PlayerManager.modify_hp(-actual_damage)

		if player_defense_reduction > 0:
			_log_combat_event("%s ti colpisce per %d danni! (Ridotto da difesa: -%d)" % [current_enemy["name"], actual_damage, player_defense_reduction])
		else:
			_log_combat_event("%s ti colpisce per %d danni!" % [current_enemy["name"], actual_damage])

		damage_dealt.emit("player", actual_damage, enemy_hit_check.roll == 20)

		combat_stats.enemy_damage_dealt += actual_damage
		combat_stats.enemy_hits += 1
	else:
		_log_combat_event("%s manca il colpo!" % current_enemy["name"])

	_end_enemy_turn()

## Termina il turno del giocatore
func _end_player_turn() -> void:
	is_player_turn = false
	current_combat_state = CombatState.ENEMY_TURN
	turn_changed.emit(CombatState.ENEMY_TURN)

	# Piccola pausa prima del turno nemico
	await get_tree().create_timer(1.0).timeout

	_perform_enemy_turn()

## Termina il turno del nemico
func _end_enemy_turn() -> void:
	combat_stats.rounds += 1
	is_player_turn = true
	current_combat_state = CombatState.PLAYER_TURN
	turn_changed.emit(CombatState.PLAYER_TURN)

# ========================================
# CALCOLI COMBATTIMENTO
# ========================================

## Calcola il danno dell'arma equipaggiata
func _calculate_weapon_damage() -> Dictionary:
	var weapon = PlayerManager.equipped_weapon

	if weapon.is_empty():
		# Danno a mani nude
		return {
			"base_damage": 0,
			"dice_min": 1,
			"dice_max": 4
		}

	# Danno dall'arma (parsing stringa tipo "1d6" o valore fisso)
	var damage_str = weapon.get("damage", "1d4")
	return _parse_damage_string(damage_str)

## Calcola la probabilità di colpire
func _calculate_hit_chance() -> int:
	var base_chance = 12  # DC base
	var weapon_accuracy = 0

	if not PlayerManager.equipped_weapon.is_empty():
		weapon_accuracy = PlayerManager.equipped_weapon.get("accuracy", 0)

	var agility_mod = PlayerManager.get_stat("agilita") - 10
	base_chance -= agility_mod  # Migliore agilità = più facile colpire

	return max(5, base_chance - weapon_accuracy)  # Minimo DC 5

## Calcola la difesa dell'armatura
func _calculate_armor_defense() -> int:
	var armor = PlayerManager.equipped_armor

	if armor.is_empty():
		return 0

	return armor.get("defense", 0)

## Parsa una stringa danno (es. "1d6+2" -> {base_damage: 2, dice_min: 1, dice_max: 6})
func _parse_damage_string(damage_str: String) -> Dictionary:
	var result = {
		"base_damage": 0,
		"dice_min": 1,
		"dice_max": 4
	}

	# Parsing semplice: supporta formato "XdY" o "XdY+Z"
	var parts = damage_str.split("+")
	if parts.size() > 1:
		result.base_damage = parts[1].to_int()

	var dice_part = parts[0].to_lower()
	if "d" in dice_part:
		var dice_parts = dice_part.split("d")
		if dice_parts.size() == 2:
			var num_dice = max(1, dice_parts[0].to_int())
			var dice_size = max(1, dice_parts[1].to_int())

			result.dice_min = num_dice
			result.dice_max = num_dice * dice_size

	return result

# ========================================
# GESTIONE NEMICI
# ========================================

## Ottiene i dati di un nemico con scaling per livello giocatore
func _get_enemy_data(enemy_id: String) -> Dictionary:
	# Database base dei nemici
	var base_enemies_db = {
		"wolf": {
			"id": "wolf",
			"name": "Lupo Affamato",
			"hp": 15,
			"max_hp": 15,
			"damage": 4,
			"defense": 1,
			"accuracy": 13,
			"xp_reward": 25,
			"loot_table": [
				{"item_id": "wolf_pelt", "chance": 0.7, "quantity": {"min": 1, "max": 1}},
				{"item_id": "raw_meat", "chance": 0.5, "quantity": {"min": 1, "max": 2}}
			],
			"difficulty_modifier": 1.0
		},
		"bandit": {
			"id": "bandit",
			"name": "Bandito",
			"hp": 20,
			"max_hp": 20,
			"damage": 6,
			"defense": 2,
			"accuracy": 12,
			"xp_reward": 40,
			"loot_table": [
				{"item_id": "rusty_knife", "chance": 0.6, "quantity": {"min": 1, "max": 1}},
				{"item_id": "cloth_scraps", "chance": 0.4, "quantity": {"min": 1, "max": 3}},
				{"item_id": "ration_pack", "chance": 0.3, "quantity": {"min": 1, "max": 1}}
			],
			"difficulty_modifier": 1.2
		},
		"mutant": {
			"id": "mutant",
			"name": "Mutante",
			"hp": 25,
			"max_hp": 25,
			"damage": 8,
			"defense": 3,
			"accuracy": 11,
			"xp_reward": 60,
			"loot_table": [
				{"item_id": "mutant_tooth", "chance": 0.8, "quantity": {"min": 1, "max": 2}},
				{"item_id": "strange_meat", "chance": 0.6, "quantity": {"min": 1, "max": 1}},
				{"item_id": "radioactive_material", "chance": 0.2, "quantity": {"min": 1, "max": 1}}
			],
			"difficulty_modifier": 1.5
		}
	}

	var base_enemy = base_enemies_db.get(enemy_id, {})
	if base_enemy.is_empty():
		return {}

	# Applica scaling per livello giocatore
	return _scale_enemy_for_player_level(base_enemy)

## Applica scaling difficoltà basato sul livello del giocatore
func _scale_enemy_for_player_level(base_enemy: Dictionary) -> Dictionary:
	var scaled_enemy = base_enemy.duplicate(true)

	# Calcola livello giocatore approssimativo basato su statistiche
	var player_level = _calculate_player_level()

	# Scaling base: +15% per livello ogni 5 livelli giocatore
	var level_multiplier = 1.0 + (player_level - 1) * 0.03

	# Applica moltiplicatore difficoltà base del nemico
	level_multiplier *= base_enemy.get("difficulty_modifier", 1.0)

	# Applica scaling alle statistiche
	scaled_enemy.hp = int(base_enemy.hp * level_multiplier)
	scaled_enemy.max_hp = scaled_enemy.hp
	scaled_enemy.damage = int(base_enemy.damage * level_multiplier)
	scaled_enemy.defense = int(base_enemy.defense * level_multiplier)

	# Migliora accuracy leggermente
	scaled_enemy.accuracy = min(18, base_enemy.accuracy + int(player_level * 0.5))

	# Aumenta XP reward
	scaled_enemy.xp_reward = int(base_enemy.xp_reward * level_multiplier * 1.2)

	# Migliora loot chance per livelli alti
	if player_level >= 3:
		for loot_item in scaled_enemy.loot_table:
			loot_item.chance = min(0.9, loot_item.chance + 0.1)

	return scaled_enemy

## Calcola livello approssimativo del giocatore
func _calculate_player_level() -> int:
	var total_stats = PlayerManager.get_stat("forza") + PlayerManager.get_stat("agilita") + PlayerManager.get_stat("intelligenza") + PlayerManager.get_stat("carisma") + PlayerManager.get_stat("fortuna") + PlayerManager.get_stat("vigore")
	var average_stat = total_stats / 6.0

	# Formula approssimativa: livello basato su statistiche medie
	var level = int((average_stat - 10) / 2) + 1
	return max(1, min(10, level))  # Limita tra 1 e 10 per ora

## Verifica se il combattimento è finito
func _check_combat_end() -> void:
	# Controlla se nemico sconfitto
	if current_enemy.get("hp", 0) <= 0:
		_award_combat_rewards()
		end_combat(CombatResult.PLAYER_VICTORY, _generate_rewards())
		return

	# Controlla se giocatore sconfitto
	if PlayerManager.hp <= 0:
		end_combat(CombatResult.ENEMY_VICTORY, {})
		return

## Assegna ricompense del combattimento
func _award_combat_rewards() -> void:
	var xp_reward = current_enemy.get("xp_reward", 10)
	PlayerManager.add_experience(xp_reward, "combattimento")

	_log_combat_event("Hai sconfitto %s! Guadagni %d XP." % [current_enemy["name"], xp_reward])

## Genera loot casuale basato sulla tabella loot del nemico
func _generate_rewards() -> Dictionary:
	var loot_table = current_enemy.get("loot_table", [])
	var rewards = {}

	for loot_entry in loot_table:
		var chance = loot_entry.get("chance", 0.0)
		if randf() < chance:
			var item_id = loot_entry.get("item_id", "")
			var quantity_range = loot_entry.get("quantity", {"min": 1, "max": 1})

			var quantity = randi_range(quantity_range.min, quantity_range.max)
			rewards[item_id] = quantity

	return rewards

# ========================================
# LOGGING E DEBUG
# ========================================

## Aggiunge un evento al log combattimento
func _log_combat_event(message: String) -> void:
	combat_log.append(message)
	combat_log_updated.emit(message)
	print("⚔️ %s" % message)

## Ottiene il log del combattimento corrente
func get_combat_log() -> Array[String]:
	return combat_log.duplicate()

## Ottiene le statistiche del combattimento
func get_combat_stats() -> Dictionary:
	return combat_stats.duplicate()

## Ottiene lo stato del combattimento corrente
func get_combat_state() -> Dictionary:
	return {
		"state": current_combat_state,
		"enemy": current_enemy.duplicate(),
		"is_player_turn": is_player_turn,
		"available_actions": available_actions.duplicate(),
		"combat_log": combat_log.duplicate(),
		"stats": combat_stats.duplicate(),
		"player_defense_bonus": player_defense_bonus,
		"player_defense_turns": player_defense_turns_remaining
	}

# ========================================
# API PUBBLICA PER INTEGRAZIONE UI
# ========================================

## Restituisce le azioni disponibili per il giocatore
func get_available_actions() -> Array[CombatAction]:
	if current_combat_state != CombatState.PLAYER_TURN:
		return []

	var actions = available_actions.duplicate()

	# Verifica disponibilità USE_ITEM (deve avere consumabili)
	var has_consumables = false
	for item_id in PlayerManager.inventory:
		var item_data = DataManager.get_item_data(item_id.id)
		if item_data.get("category") == "CONSUMABLE":
			has_consumables = true
			break

	if not has_consumables:
		actions.erase(CombatAction.USE_ITEM)

	# Verifica disponibilità SPECIAL (deve avere arma con effetti speciali)
	var has_special_weapon = false
	if not PlayerManager.equipped_weapon.is_empty():
		var weapon_data = PlayerManager.equipped_weapon
		var properties = weapon_data.get("properties", {})
		var effects = properties.get("effects", [])
		for effect in effects:
			var effect_type = effect.get("effect_type", "")
			if effect_type in ["bleeding_edge", "armor_piercing", "high_critical"]:
				has_special_weapon = true
				break

	if not has_special_weapon:
		actions.erase(CombatAction.SPECIAL)

	return actions

## Verifica se è attivo un combattimento
func is_combat_active() -> bool:
	return current_combat_state != CombatState.IDLE

## Ottiene i dati di un nemico specifico
func get_enemy_data(enemy_id: String) -> Dictionary:
	return _get_enemy_data(enemy_id)

## Calcola il danno di un'attaccante con un'arma specifica
func calculate_damage(attacker_stats: Dictionary, weapon_data: Dictionary) -> int:
	var base_damage = weapon_data.get("damage", {}).get("min", 1) + randi_range(0, weapon_data.get("damage", {}).get("max", 1) - weapon_data.get("damage", {}).get("min", 1))
	var stat_modifier = attacker_stats.get("forza", 10) / 2
	var weapon_bonus = weapon_data.get("damage", {}).get("bonus", 0)

	return base_damage + stat_modifier + weapon_bonus

# ========================================
# SISTEMA SALVATAGGIO
# ========================================

## Ottiene lo stato del combattimento per il salvataggio
func get_save_data() -> Dictionary:
	if current_combat_state == CombatState.IDLE:
		return {}

	return {
		"enemy_id": current_enemy.get("id", ""),
		"enemy_hp": current_enemy.get("hp", 0),
		"combat_state": current_combat_state,
		"is_player_turn": is_player_turn,
		"combat_stats": combat_stats.duplicate(),
		"combat_log": combat_log.duplicate(),
		"player_defense_bonus": player_defense_bonus,
		"player_defense_turns": player_defense_turns_remaining,
		"rounds": combat_stats.rounds
	}

## Carica lo stato del combattimento dal salvataggio
func load_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	# Ricostruisci nemico
	var enemy_id = data.get("enemy_id", "")
	if enemy_id.is_empty():
		return false

	current_enemy = _get_enemy_data(enemy_id)
	if current_enemy.is_empty():
		return false

	# Ripristina stato
	current_enemy.hp = data.get("enemy_hp", current_enemy.hp)
	current_combat_state = data.get("combat_state", CombatState.IDLE)
	is_player_turn = data.get("is_player_turn", true)
	combat_stats = data.get("combat_stats", combat_stats.duplicate())
	combat_log = data.get("combat_log", [])
	player_defense_bonus = data.get("player_defense_bonus", 0)
	player_defense_turns_remaining = data.get("player_defense_turns", 0)

	print("⚔️ CombatManager: Stato combattimento ripristinato")
	return true

# ========================================
# API DEBUG E TESTING
# ========================================

## Forza inizio combattimento (per debug)
func debug_start_combat(enemy_id: String = "wolf") -> void:
	start_combat(enemy_id)
	print("🔧 DEBUG: Combattimento forzato iniziato contro: %s" % enemy_id)

## Forza vittoria immediata (per debug)
func debug_force_victory() -> void:
	if current_combat_state != CombatState.IDLE:
		current_enemy.hp = 0
		_check_combat_end()
		print("🔧 DEBUG: Vittoria forzata")

## Aggiunge HP al nemico (per testing prolungato)
func debug_heal_enemy(amount: int = 10) -> void:
	if current_combat_state != CombatState.IDLE:
		current_enemy.hp += amount
		print("🔧 DEBUG: HP nemico aumentati di %d" % amount)

## Reset sistema combattimento
func debug_reset_combat() -> void:
	if current_combat_state != CombatState.IDLE:
		end_combat(CombatResult.TIMEOUT, {})
	print("🔧 DEBUG: Sistema combattimento resettato")

# ========================================
# TESTING E VALIDATION
# ========================================

## Test attacco base
func test_basic_attack() -> void:
	print("🧪 TEST: Attacco base")
	var player_stats = {"forza": 14, "agilita": 12}
	var weapon = {"damage": {"min": 5, "max": 10, "bonus": 2}}
	var damage = calculate_damage(player_stats, weapon)

	assert(damage >= 7 && damage <= 16, "Danno fuori range: %d" % damage)
	print("✅ TEST: Attacco base superato - danno: %d" % damage)

## Test risoluzione combattimento
func test_combat_resolution() -> void:
	print("🧪 TEST: Risoluzione combattimento")
	var success = start_combat("wolf")
	assert(success, "Impossibile iniziare combattimento")

	var result = perform_player_action(CombatAction.ATTACK)
	assert(result, "Azione attacco fallita")

	print("✅ TEST: Risoluzione combattimento superata")

## Test sistema difesa
func test_defense_system() -> void:
	print("🧪 TEST: Sistema difesa")
	var success = start_combat("wolf")
	assert(success, "Impossibile iniziare combattimento")

	# Test difesa
	var defense_success = perform_player_action(CombatAction.DEFEND)
	assert(defense_success, "Azione difesa fallita")
	assert(player_defense_bonus > 0, "Bonus difesa non applicato")

	print("✅ TEST: Sistema difesa superato - bonus: %d" % player_defense_bonus)

## Test generazione loot
func test_loot_generation() -> void:
	print("🧪 TEST: Generazione loot")
	start_combat("bandit")

	# Forza vittoria
	current_enemy.hp = 0
	_check_combat_end()

	var rewards = _generate_rewards()
	assert(rewards is Dictionary, "Rewards non è un dizionario")

	print("✅ TEST: Generazione loot superata - items: %d" % rewards.size())

## Test scaling nemico
func test_enemy_scaling() -> void:
	print("🧪 TEST: Scaling nemico")
	var base_wolf = _get_enemy_data("wolf")
	var scaled_wolf = _scale_enemy_for_player_level(base_wolf)

	assert(scaled_wolf.hp >= base_wolf.hp, "HP non scalati correttamente")
	assert(scaled_wolf.damage >= base_wolf.damage, "Danno non scalato correttamente")

	print("✅ TEST: Scaling nemico superato - HP: %d→%d" % [base_wolf.hp, scaled_wolf.hp])

## Esegue tutti i test
func run_all_tests() -> void:
	print("🚀 AVVIO TEST SUITE COMBAT SYSTEM")
	print("==================================================")

	test_basic_attack()
	test_combat_resolution()
	test_defense_system()
	test_loot_generation()
	test_enemy_scaling()

	# Cleanup
	debug_reset_combat()

	print("==================================================")
	print("✅ TUTTI I TEST SUPERATI")