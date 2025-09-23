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
	INITIATING = 1,
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

# ========================================
# SEGNALI PUBBLICI
# ========================================

signal combat_started(enemy_data: Dictionary)
signal combat_ended(result: CombatResult, rewards: Dictionary)
signal turn_changed(is_player_turn: bool)
signal damage_dealt(target: String, amount: int, is_critical: bool)
signal combat_action_performed(action: String, success: bool)

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
var available_actions: Array[String] = ["attack", "defend", "flee"]

## Log del combattimento
var combat_log: Array[String] = []

## Statistiche combattimento
var combat_stats: Dictionary = {
	"rounds": 0,
	"player_damage_dealt": 0,
	"enemy_damage_dealt": 0,
	"player_hits": 0,
	"enemy_hits": 0
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
	current_combat_state = CombatState.INITIATING
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
	turn_changed.emit(true)

	print("⚔️ CombatManager: Combattimento iniziato contro %s" % enemy_id)
	return true

## Esegue un'azione del giocatore
func perform_player_action(action: String, _target: String = "") -> bool:
	if current_combat_state != CombatState.PLAYER_TURN:
		print("⚔️ CombatManager: Non è il turno del giocatore")
		return false

	if not action in available_actions:
		print("⚔️ CombatManager: Azione non disponibile: %s" % action)
		combat_action_performed.emit(action, false)
		return false

	var success = false

	match action:
		"attack":
			success = _perform_attack()
		"defend":
			success = _perform_defend()
		"flee":
			success = _perform_flee()

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

		_log_combat_event("Colpisci %s per %d danni!" % [current_enemy.name, damage])
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
	_log_combat_event("Ti prepari a difenderti, aumentando la tua difesa per il prossimo turno.")

	# Aumenta temporaneamente la difesa (implementazione futura)
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

## Esegue il turno del nemico
func _perform_enemy_turn() -> void:
	current_combat_state = CombatState.ENEMY_TURN

	# Logica semplice nemico: sempre attacca
	var enemy_damage = current_enemy.get("damage", 5)
	var hit_chance = current_enemy.get("accuracy", 12)

	# Skill check nemico (usando fortuna del giocatore come difesa)
	var enemy_hit_check = SkillCheckManager.perform_check("fortuna", hit_chance)

	if enemy_hit_check.success:
		# Calcola danno con difesa armatura
		var armor_defense = _calculate_armor_defense()
		var actual_damage = max(1, enemy_damage - armor_defense)

		# Applica danno al giocatore
		PlayerManager.modify_hp(-actual_damage)

		_log_combat_event("%s ti colpisce per %d danni!" % [current_enemy.name, actual_damage])
		damage_dealt.emit("player", actual_damage, enemy_hit_check.roll == 20)

		combat_stats.enemy_damage_dealt += actual_damage
		combat_stats.enemy_hits += 1
	else:
		_log_combat_event("%s manca il colpo!" % current_enemy.name)

	_end_enemy_turn()

## Termina il turno del giocatore
func _end_player_turn() -> void:
	is_player_turn = false
	turn_changed.emit(false)

	# Piccola pausa prima del turno nemico
	await get_tree().create_timer(1.0).timeout

	_perform_enemy_turn()

## Termina il turno del nemico
func _end_enemy_turn() -> void:
	combat_stats.rounds += 1
	is_player_turn = true
	current_combat_state = CombatState.PLAYER_TURN
	turn_changed.emit(true)

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

## Ottiene i dati di un nemico
func _get_enemy_data(enemy_id: String) -> Dictionary:
	# Per ora, nemici hardcoded. In futuro da database JSON
	var enemies_db = {
		"wolf": {
			"id": "wolf",
			"name": "Lupo Affamato",
			"hp": 15,
			"max_hp": 15,
			"damage": 4,
			"defense": 1,
			"accuracy": 13,
			"xp_reward": 25,
			"loot_table": ["wolf_pelt", "raw_meat"]
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
			"loot_table": ["rusty_knife", "cloth_scraps", "ration_pack"]
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
			"loot_table": ["mutant_tooth", "strange_meat", "radioactive_material"]
		}
	}

	return enemies_db.get(enemy_id, {})

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

	_log_combat_event("Hai sconfitto %s! Guadagni %d XP." % [current_enemy.name, xp_reward])

## Genera loot casuale
func _generate_rewards() -> Dictionary:
	var loot_table = current_enemy.get("loot_table", [])
	var rewards = {}

	if loot_table.size() > 0:
		var selected_loot = loot_table[randi() % loot_table.size()]
		rewards[selected_loot] = 1

	return rewards

# ========================================
# LOGGING E DEBUG
# ========================================

## Aggiunge un evento al log combattimento
func _log_combat_event(message: String) -> void:
	combat_log.append(message)
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
		"stats": combat_stats.duplicate()
	}

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