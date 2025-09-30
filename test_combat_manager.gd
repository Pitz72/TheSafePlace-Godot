# test_combat_manager.gd
# Test per verificare il funzionamento del CombatManager dopo il refactoring.
# Testa l'integrazione con DataManager e il flusso di combattimento base.

extends Node

# --- ESECUZIONE TEST ---

func _ready():
	print("\n" + "=".repeat(50))
	print("🚀 AVVIO TEST SUITE COMBAT MANAGER (FASE 2)")
	print("=".repeat(50))

	# Attendi che tutti i manager singleton siano pronti
	await get_tree().process_frame
	await get_tree().process_frame

	# Esegui la suite di test
	test_initialization_and_data_loading()
	test_start_combat()
	test_player_attack_action()
	test_enemy_scaling()

	print("\n" + "=".repeat(50))
	print("✅ FINE TEST SUITE COMBAT MANAGER")
	print("=".repeat(50))

	# Opzionale: chiudi il gioco dopo i test
	# get_tree().quit()

# --- SUITE DI TEST ---

## Test 1: Verifica l'inizializzazione del CombatManager e il caricamento dei dati dal DataManager.
func test_initialization_and_data_loading():
	print("\n--- Test 1: Inizializzazione e Caricamento Dati ---")

	var combat_manager = get_node_or_null("/root/CombatManager")
	if not combat_manager:
		print("❌ FALLITO: CombatManager non trovato nella scena.")
		return

	print("✅ PASS: CombatManager trovato e inizializzato.")

	# Verifica che il database dei nemici sia stato caricato
	if combat_manager.enemies_db.is_empty():
		print("❌ FALLITO: Il database dei nemici (enemies_db) è vuoto.")
		print("   Verificare che DataManager carichi correttamente 'res://data/enemies.json'.")
		return

	print("✅ PASS: Il database dei nemici è stato caricato correttamente.")
	print("   Nemici trovati: %d" % combat_manager.enemies_db.size())


## Test 2: Verifica la capacità di iniziare un combattimento.
func test_start_combat():
	print("\n--- Test 2: Inizio Combattimento ---")

	var combat_manager = get_node("/root/CombatManager")

	# Pulisci stato da test precedenti
	combat_manager.debug_reset_combat()
	await get_tree().process_frame

	var success = combat_manager.start_combat("wolf")

	if not success:
		print("❌ FALLITO: La funzione start_combat('wolf') ha restituito false.")
		return

	print("✅ PASS: start_combat('wolf') ha restituito true.")

	if not combat_manager.is_combat_active():
		print("❌ FALLITO: is_combat_active() è false dopo aver iniziato un combattimento.")
		combat_manager.debug_reset_combat()
		return

	print("✅ PASS: is_combat_active() è true.")

	if combat_manager.current_enemy.is_empty() or combat_manager.current_enemy.id != "wolf":
		print("❌ FALLITO: Il nemico corrente non è stato impostato correttamente.")
		print("   Nemico attuale: %s" % str(combat_manager.current_enemy))
		combat_manager.debug_reset_combat()
		return

	print("✅ PASS: Il nemico 'wolf' è stato caricato correttamente come avversario.")

	# Pulisci stato per il prossimo test
	combat_manager.debug_reset_combat()


## Test 3: Verifica che un'azione di attacco del giocatore abbia effetto.
func test_player_attack_action():
	print("\n--- Test 3: Azione di Attacco del Giocatore ---")

	var combat_manager = get_node("/root/CombatManager")
	var player_manager = get_node("/root/PlayerManager")

	# Imposta uno stato di base per il giocatore per rendere il test prevedibile
	player_manager.stats.forza = 14 # Dà un bonus al danno

	# Pulisci stato e inizia combattimento
	combat_manager.debug_reset_combat()
	await get_tree().process_frame
	combat_manager.start_combat("bandit")

	var enemy = combat_manager.current_enemy
	var hp_before = enemy.hp

	print("   HP nemico prima dell'attacco: %d" % hp_before)

	# Esegui l'azione di attacco
	combat_manager.perform_player_action(combat_manager.CombatAction.ATTACK)

	# Attendi che il turno si risolva
	await get_tree().create_timer(1.2).timeout # Attendi il timer interno del manager + un margine

	var hp_after = combat_manager.current_enemy.hp
	print("   HP nemico dopo l'attacco: %d" % hp_after)

	if hp_after >= hp_before:
		print("❌ FALLITO: L'HP del nemico non è diminuito dopo un attacco.")
		combat_manager.debug_reset_combat()
		return

	print("✅ PASS: L'HP del nemico è diminuito correttamente.")

	# Pulisci stato
	combat_manager.debug_reset_combat()


## Test 4: Verifica che lo scaling dei nemici funzioni correttamente.
func test_enemy_scaling():
	print("\n--- Test 4: Scaling dei Nemici ---")

	var combat_manager = get_node("/root/CombatManager")
	var player_manager = get_node("/root/PlayerManager")

	# Salva le statistiche originali per ripristinarle dopo
	var original_stats = player_manager.stats.duplicate(true)

	# Ottieni dati base del nemico con giocatore a livello basso
	player_manager.stats.forza = 10
	player_manager.stats.vigore = 10
	var enemy_low_level = combat_manager._get_enemy_data("mutant")
	print("   Statistiche 'mutant' a basso livello: HP=%d, Danno=%d" % [enemy_low_level.hp, enemy_low_level.damage])

	# Simula un level up del giocatore
	player_manager.stats.forza = 20
	player_manager.stats.vigore = 20

	# Ottieni di nuovo i dati del nemico
	var enemy_high_level = combat_manager._get_enemy_data("mutant")
	print("   Statistiche 'mutant' ad alto livello: HP=%d, Danno=%d" % [enemy_high_level.hp, enemy_high_level.damage])

	if enemy_high_level.hp <= enemy_low_level.hp:
		print("❌ FALLITO: L'HP del nemico non è aumentato con il livello del giocatore.")
		return

	if enemy_high_level.damage <= enemy_low_level.damage:
		print("❌ FALLITO: Il danno del nemico non è aumentato con il livello del giocatore.")
		return

	print("✅ PASS: Le statistiche del nemico scalano correttamente con il livello del giocatore.")

	# Ripristina le statistiche originali del giocatore
	player_manager.stats = original_stats
	print("   Statistiche giocatore ripristinate.")