extends Node

## CombatManager Singleton - The Safe Place v0.9.5
## Gestisce il sistema di combattimento turn-based.

extends Node

# ========================================
# ENUM E COSTANTI
# ========================================

enum CombatState { IDLE, INITIALIZING, PLAYER_TURN, ENEMY_TURN, ENDED }
enum CombatAction { ATTACK, DEFEND, USE_ITEM, FLEE, SPECIAL }
enum CombatResult { ONGOING, PLAYER_VICTORY, ENEMY_VICTORY, PLAYER_FLED }

# ========================================
# SEGNALI PUBBLICI
# ========================================

signal combat_started(enemy_data: Dictionary)
signal combat_ended(result: CombatResult, rewards: Dictionary)
signal turn_changed(new_state: CombatState)
signal damage_dealt(target: String, amount: int)

# ========================================
# VARIABILI DI STATO
# ========================================

var current_combat_state: CombatState = CombatState.IDLE
var current_enemy: Dictionary = {}
var turn_count: int = 0

# Database nemici (per ora hardcoded, in futuro da DataManager)
var _enemies_db: Dictionary = {
	"rat_giant": {
		"id": "rat_giant",
		"name": "Ratto Gigante",
		"hp": 20,
		"damage": {"min": 2, "max": 5},
		"xp_reward": 15,
		"loot_table": [{"id": "raw_meat", "chance": 0.5, "quantity": 1}]
	}
}

func _ready():
	print("⚔️ CombatManager pronto.")

# ========================================
# API PRINCIPALE
# ========================================

func start_combat(enemy_id: String) -> bool:
	if current_combat_state != CombatState.IDLE:
		print("⚔️ Errore: Combattimento già in corso.")
		return false

	current_combat_state = CombatState.INITIALIZING
	
	var enemy_data = _enemies_db.get(enemy_id)
	if enemy_data == null:
		print("⚔️ Errore: Nemico non trovato: %s" % enemy_id)
		current_combat_state = CombatState.IDLE
		return false

	current_enemy = enemy_data.duplicate(true) # Copia per non modificare il DB
	turn_count = 0
	
	print("========================================")
	print("⚔️ Combattimento iniziato contro: %s (HP: %d)" % [current_enemy.name, current_enemy.hp])
	print("========================================")
	
	combat_started.emit(current_enemy)
	_start_player_turn()
	return true

func end_combat(result: CombatResult):
	var rewards = {}
	if result == CombatResult.PLAYER_VICTORY:
		rewards = _calculate_rewards()
		print("🏆 VITTORIA! Hai sconfitto %s." % current_enemy.name)
		print("   Ricompense: %s" % rewards)
	else:
		print("☠️ SCONFITTA. Sei stato sopraffatto da %s." % current_enemy.name)

	combat_ended.emit(result, rewards)
	
	# Reset stato
	current_combat_state = CombatState.IDLE
	current_enemy.clear()
	turn_count = 0
	print("========================================")

func process_player_action(action: CombatAction):
	if current_combat_state != CombatState.PLAYER_TURN:
		print("⚔️ Non è il tuo turno!")
		return

	match action:
		CombatAction.ATTACK:
			var damage = _calculate_player_damage()
			current_enemy.hp -= damage
			print("   > Tu attacchi %s per %d danni. (HP nemico: %d)" % [current_enemy.name, damage, current_enemy.hp])
			damage_dealt.emit("enemy", damage)
			
			if current_enemy.hp <= 0:
				end_combat(CombatResult.PLAYER_VICTORY)
			else:
				_start_enemy_turn()
		_:
			print("⚔️ Azione non ancora implementata.")

# ========================================
# GESTIONE TURNI
# ========================================

func _start_player_turn():
	turn_count += 1
	current_combat_state = CombatState.PLAYER_TURN
	print("\n--- Turno %d: È il tuo turno! (HP: %d) ---" % [turn_count, PlayerManager.hp])
	turn_changed.emit(current_combat_state)

func _start_enemy_turn():
	current_combat_state = CombatState.ENEMY_TURN
	print("\n--- Turno %d: Turno di %s ---" % [turn_count, current_enemy.name])
	turn_changed.emit(current_combat_state)
	
	# L'IA nemica agisce dopo un breve delay per leggibilità
	await get_tree().create_timer(1.0).timeout
	_process_enemy_turn()

func _process_enemy_turn():
	# IA Semplice: attacca sempre
	var damage = _calculate_enemy_damage()
	PlayerManager.modify_hp(-damage)
	print("   < %s ti attacca per %d danni. (HP giocatore: %d)" % [current_enemy.name, damage, PlayerManager.hp])
	damage_dealt.emit("player", damage)
	
	if PlayerManager.hp <= 0:
		end_combat(CombatResult.ENEMY_VICTORY)
	else:
		_start_player_turn()

# ========================================
# CALCOLO DANNO E RICOMPENSE
# ========================================

func _calculate_player_damage() -> int:
	var base_damage = 1 # Danno a mani nude
	var stat_modifier = 0
	
	# Controlla arma equipaggiata
	if not PlayerManager.equipped_weapon.is_empty():
		var weapon_props = PlayerManager.equipped_weapon.get("properties", {})
		var weapon_damage = weapon_props.get("damage", {})
		base_damage = randi_range(weapon_damage.get("min", 1), weapon_damage.get("max", 2))
	
	# Aggiungi modificatore statistica (Forza per melee)
	stat_modifier = PlayerManager.get_stat_modifier(PlayerManager.get_stat("forza"))
	
	return max(1, base_damage + stat_modifier)

func _calculate_enemy_damage() -> int:
	var damage_range = current_enemy.get("damage", {"min": 1, "max": 2})
	return randi_range(damage_range.get("min", 1), damage_range.get("max", 2))

func _calculate_rewards() -> Dictionary:
	var rewards = {
		"xp": current_enemy.get("xp_reward", 0),
		"items": []
	}
	
	# Calcola loot
	var loot_table = current_enemy.get("loot_table", [])
	for item_entry in loot_table:
		if randf() < item_entry.get("chance", 0.0):
			rewards.items.append({
				"id": item_entry.id,
				"quantity": item_entry.quantity
			})
			
	return rewards
