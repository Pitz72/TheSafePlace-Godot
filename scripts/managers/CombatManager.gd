# CombatManager.gd
#
# Singleton (Autoload) per la gestione completa del sistema di combattimento a turni.
#
# Responsabilità:
# - Gestire lo stato del combattimento (attivo/inattivo, turno corrente).
# - Contenere la logica di combattimento (attacchi, danni, effetti).
# - Mantenere i dati delle entità coinvolte nel combattimento (giocatore, nemici).
# - Emettere segnali per notificare l'UI e altri sistemi degli eventi di combattimento.

extends Node

# Segnali per la comunicazione con l'UI e altri sistemi
signal combat_started(player_data, enemy_data)
signal combat_ended(result) # "win", "lose", "flee"
signal turn_changed(current_turn) # "player", "enemy"
signal combat_log_updated(message)
signal player_health_changed(new_health)
signal enemy_health_changed(new_health)

# Enum per lo stato del combattimento e i turni
enum CombatState { INACTIVE, ACTIVE }
enum CombatTurn { PLAYER, ENEMY }

var current_state = CombatState.INACTIVE
var current_turn = CombatTurn.PLAYER

# Dati delle entità in combattimento
var player_data = {}
var enemy_data = {}

func _ready():
    # Il CombatManager è sempre attivo in ascolto, ma il combattimento
    # non è ancora iniziato.
    print("[CombatManager] Ready.")

# Funzione per avviare il combattimento
func start_combat(enemy_id: String):
    if current_state == CombatState.ACTIVE:
        print("⚠️ CombatManager: Tentativo di avviare un combattimento mentre uno è già attivo.")
        return

    var fetched_enemy_data = DataManager.get_enemy_data(enemy_id)
    if fetched_enemy_data == null:
        print("❌ CombatManager: Impossibile avviare il combattimento, nemico non trovato: %s" % enemy_id)
        return

    var fetched_player_data = PlayerManager.get_combat_snapshot()
    if fetched_player_data.is_empty():
        print("❌ CombatManager: Impossibile avviare il combattimento, dati giocatore non disponibili.")
        return

    print("⚔️ [CombatManager] Avvio combattimento con '%s'..." % fetched_enemy_data.name)

    # Inizializza lo stato del combattimento
    self.enemy_data = fetched_enemy_data
    # Aggiungi un campo 'hp' corrente, dato che i dati del DB hanno solo 'max_hp'
    self.enemy_data.stats["hp"] = self.enemy_data.stats.max_hp

    self.player_data = fetched_player_data
    self.current_state = CombatState.ACTIVE
    self.current_turn = CombatTurn.PLAYER

    emit_signal("combat_started", player_data, enemy_data)
    emit_signal("combat_log_updated", "Inizia il combattimento contro %s!" % enemy_data.name)
    emit_signal("turn_changed", "player")

# ========================================
# GESTIONE AZIONI E TURNO
# ========================================

## Punto di ingresso per le azioni del giocatore. Chiamato dalla UI.
func player_perform_attack():
	if current_state != CombatState.ACTIVE or current_turn != CombatTurn.PLAYER:
		print("⚠️ CombatManager: Attacco giocatore fuori turno.")
		return

	emit_signal("combat_log_updated", "> Tu attacchi!")

	var attack_result = _calculate_attack(player_data, enemy_data)

	if attack_result.hit:
		emit_signal("combat_log_updated", "   Colpito! Infliggi %d danni." % attack_result.damage)
		enemy_data.stats.hp -= attack_result.damage
		emit_signal("enemy_health_changed", enemy_data.stats.hp)
	else:
		emit_signal("combat_log_updated", "   Mancato!")

	if enemy_data.stats.hp <= 0:
		emit_signal("combat_log_updated", "Hai sconfitto %s!" % enemy_data.name)
		end_combat("win")
		return

	current_turn = CombatTurn.ENEMY
	emit_signal("turn_changed", "enemy")

	get_tree().create_timer(1.0).timeout.connect(_execute_enemy_turn)

func _execute_enemy_turn():
	if current_state != CombatState.ACTIVE or current_turn != CombatTurn.ENEMY:
		return

	emit_signal("combat_log_updated", "> %s attacca!" % enemy_data.name)

	var enemy_snapshot_as_attacker = { "stats": enemy_data.stats, "equipped_weapon": {}, "equipped_armor": {} }
	var attack_result = _calculate_attack(enemy_snapshot_as_attacker, player_data)

	if attack_result.hit:
		emit_signal("combat_log_updated", "   Sei stato colpito! Subisci %d danni." % attack_result.damage)
		player_data.hp -= attack_result.damage
		emit_signal("player_health_changed", player_data.hp)
	else:
		emit_signal("combat_log_updated", "   %s ti ha mancato!" % enemy_data.name)

	if player_data.hp <= 0:
		emit_signal("combat_log_updated", "Sei stato sconfitto!")
		end_combat("lose")
		return

	current_turn = CombatTurn.PLAYER
	emit_signal("turn_changed", "player")

# ========================================
# LOGICA DI COMBATTIMENTO (HELPERS)
# ========================================

func _calculate_attack(attacker: Dictionary, defender: Dictionary) -> Dictionary:
	var attacker_stat_mod = _get_stat_modifier(attacker.stats.get("forza", 10))
	var to_hit_roll = randi_range(1, 20)
	var total_to_hit = to_hit_roll + attacker_stat_mod

	var defender_ac = defender.stats.get("armor_class", 10)
	if not defender.equipped_armor.is_empty():
		defender_ac = defender.equipped_armor.get("armor_class", defender_ac)

	var result = { "hit": false, "damage": 0 }

	if total_to_hit >= defender_ac:
		result.hit = true
		var damage_dice = attacker.stats.get("damage_dice", "1d4")
		if not attacker.equipped_weapon.is_empty():
			damage_dice = attacker.equipped_weapon.get("damage_dice", damage_dice)
		result.damage = _roll_dice(damage_dice)

	return result

func _roll_dice(dice_string: String) -> int:
	var parts = dice_string.split("d")
	if parts.size() != 2: return 1
	var num_dice = int(parts[0])
	var num_sides = int(parts[1])
	var total = 0
	for i in range(num_dice):
		total += randi_range(1, num_sides)
	return total

func _get_stat_modifier(stat_value: int) -> int:
	return (stat_value - 10) / 2

# Funzione per terminare il combattimento
func end_combat(result):
    if current_state == CombatState.INACTIVE:
        return

    print("[CombatManager] Ending combat. Result: " + result)
    current_state = CombatState.INACTIVE
    player_data = {}
    enemy_data = {}
    emit_signal("combat_ended", result)
