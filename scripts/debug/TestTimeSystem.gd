extends Node

## Script di Test - Sistema Temporale M3.T2
## 
## Verifica il funzionamento di TimeManager, integrazione con PlayerManager e UI
## Per uso durante sviluppo e testing M3.T2 "Il Passaggio del Tempo"

# ========================================
# VARIABILI DI TEST
# ========================================

## Timer per test automatici
var test_timer: float = 0.0

## Flag per test in corso
var testing_active: bool = false

## Contatore test completati
var tests_completed: int = 0

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("🧪 TestTimeSystem inizializzazione...")
	print("   CONTROLLI DISPONIBILI:")
	print("   [F5] - Test rapido avanzamento tempo")
	print("   [F6] - Test ciclo giorno/notte")
	print("   [F7] - Test penalità sopravvivenza")
	print("   [F8] - Test salvataggio/caricamento tempo")
	print("   [F9] - Status completo sistema temporale")
	print("   [F10] - Test danno HP critico immediato")
	
	# Verifica che i manager siano disponibili
	_verify_managers()
	
	print("✅ TestTimeSystem pronto per test M3.T2")

func _verify_managers() -> void:
	"""Verifica che tutti i manager necessari siano disponibili"""
	print("🔍 Verifica manager disponibili:")
	print("  TimeManager: %s" % ("✅ OK" if TimeManager else "❌ MANCANTE"))
	print("  PlayerManager: %s" % ("✅ OK" if PlayerManager else "❌ MANCANTE"))
	print("  InputManager: %s" % ("✅ OK" if InputManager else "❌ MANCANTE"))

# ========================================
# INPUT HANDLING
# ========================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				test_time_advancement()
			KEY_F6:
				test_day_night_cycle()
			KEY_F7:
				test_survival_penalties()
			KEY_F8:
				test_save_load_system()
			KEY_F9:
				print_system_status()
			KEY_F10:
				test_critical_hp_damage()

# ========================================
# TEST SPECIFICI
# ========================================

## Test F5: Avanzamento tempo rapido
func test_time_advancement() -> void:
	print("\n🧪 === TEST F5: AVANZAMENTO TEMPO ===")
	
	if not TimeManager:
		print("❌ TimeManager non disponibile")
		return
	
	print("⏰ Tempo iniziale: %s %s" % [TimeManager.get_formatted_time(), TimeManager.get_formatted_day()])
	
	# Test avanzamento di 5 movimenti (2.5 ore)
	print("🚶 Simulando 5 movimenti (2.5 ore)...")
	TimeManager.advance_time_by_moves(5)
	
	print("⏰ Tempo finale: %s %s" % [TimeManager.get_formatted_time(), TimeManager.get_formatted_day()])
	print("✅ Test avanzamento tempo completato")

## Test F6: Ciclo giorno/notte completo
func test_day_night_cycle() -> void:
	print("\n🧪 === TEST F6: CICLO GIORNO/NOTTE ===")
	
	if not TimeManager:
		print("❌ TimeManager non disponibile")
		return
	
	# Porta il tempo alle 18:00 per testare transizione notte
	print("🌅 Impostando tempo a 18:00 per test transizione...")
	var moves_to_evening = ((18 * 60) - (TimeManager.current_hour * 60 + TimeManager.current_minute)) / 30
	if moves_to_evening > 0:
		TimeManager.advance_time_by_moves(int(moves_to_evening))
	
	print("⏰ Tempo pre-notte: %s (è notte: %s)" % [TimeManager.get_formatted_time(), "Sì" if TimeManager.is_night() else "No"])
	
	# Avanza alla notte (19:00)
	print("🌙 Avanzando alla notte...")
	TimeManager.advance_time_by_moves(2)  # 18:00 → 19:00
	
	print("⏰ Tempo notte: %s (è notte: %s)" % [TimeManager.get_formatted_time(), "Sì" if TimeManager.is_night() else "No"])
	
	# Avanza al mattino (06:00)
	print("☀️ Avanzando al mattino...")
	var moves_to_morning = ((6 * 60) - (TimeManager.current_hour * 60 + TimeManager.current_minute)) / 30
	if moves_to_morning <= 0:
		moves_to_morning += (24 * 60) / 30  # Aggiungi un giorno completo
	TimeManager.advance_time_by_moves(int(moves_to_morning))
	
	print("⏰ Tempo mattino: %s (è notte: %s)" % [TimeManager.get_formatted_time(), "Sì" if TimeManager.is_night() else "No"])
	print("✅ Test ciclo giorno/notte completato")

## Test F7: Penalità sopravvivenza
func test_survival_penalties() -> void:
	print("\n🧪 === TEST F7: PENALITÀ SOPRAVVIVENZA ===")
	
	if not PlayerManager:
		print("❌ PlayerManager non disponibile")
		return
	
	print("💊 Risorse pre-penalità:")
	print("  HP: %d/%d" % [PlayerManager.hp, PlayerManager.max_hp])
	print("  Food: %d/%d" % [PlayerManager.food, PlayerManager.max_food])
	print("  Water: %d/%d" % [PlayerManager.water, PlayerManager.max_water])
	
	# Applica penalità manualmente per test
	print("💀 Applicando penalità sopravvivenza...")
	PlayerManager.apply_survival_penalties()
	
	print("💊 Risorse post-penalità:")
	print("  HP: %d/%d" % [PlayerManager.hp, PlayerManager.max_hp])
	print("  Food: %d/%d" % [PlayerManager.food, PlayerManager.max_food])
	print("  Water: %d/%d" % [PlayerManager.water, PlayerManager.max_water])
	
	# Test stato critico
	print("💀 Test stato critico (azzeramento risorse)...")
	PlayerManager.modify_food(-PlayerManager.food)  # Azzera food
	PlayerManager.modify_water(-PlayerManager.water)  # Azzera water
	PlayerManager._check_critical_survival_damage()
	
	print("💊 Risorse post-test critico:")
	print("  HP: %d/%d" % [PlayerManager.hp, PlayerManager.max_hp])
	print("  Food: %d/%d" % [PlayerManager.food, PlayerManager.max_food])
	print("  Water: %d/%d" % [PlayerManager.water, PlayerManager.max_water])
	
	print("✅ Test penalità sopravvivenza completato")

## Test F8: Save/Load sistema temporale
func test_save_load_system() -> void:
	print("\n🧪 === TEST F8: SAVE/LOAD SISTEMA ===")
	
	if not TimeManager:
		print("❌ TimeManager non disponibile")
		return
	
	# Salva stato attuale
	print("💾 Salvando stato temporale...")
	var saved_data = TimeManager.get_time_data()
	print("  Dati salvati: %s" % str(saved_data))
	
	# Modifica stato
	print("🔄 Modificando stato temporale...")
	var original_time = TimeManager.get_formatted_time()
	TimeManager.advance_time_by_moves(10)  # Avanza di 5 ore
	print("  Tempo modificato: %s" % TimeManager.get_formatted_time())
	
	# Ripristina stato
	print("📂 Ripristinando stato temporale...")
	TimeManager.load_time_data(saved_data)
	print("  Tempo ripristinato: %s" % TimeManager.get_formatted_time())
	
	# Verifica che sia tornato allo stato originale
	if TimeManager.get_formatted_time() == original_time:
		print("✅ Test save/load completato con successo")
	else:
		print("❌ Test save/load fallito - tempo non ripristinato correttamente")

## Test F9: Status completo sistema
func print_system_status() -> void:
	print("\n🧪 === STATUS SISTEMA M3.T2 ===")
	
	# Status TimeManager
	if TimeManager:
		print("⏰ TIMEMANAGER:")
		TimeManager.debug_print_time_status()
	else:
		print("❌ TimeManager non disponibile")
	
	# Status PlayerManager (risorse)
	if PlayerManager:
		print("\n💊 PLAYERMANAGER (Risorse):")
		print("  HP: %d/%d (%.1f%%)" % [PlayerManager.hp, PlayerManager.max_hp, (float(PlayerManager.hp)/PlayerManager.max_hp)*100])
		print("  Food: %d/%d (%.1f%%)" % [PlayerManager.food, PlayerManager.max_food, (float(PlayerManager.food)/PlayerManager.max_food)*100])
		print("  Water: %d/%d (%.1f%%)" % [PlayerManager.water, PlayerManager.max_water, (float(PlayerManager.water)/PlayerManager.max_water)*100])
	else:
		print("❌ PlayerManager non disponibile")
	
	# Status Connessioni Segnali
	print("\n🔗 CONNESSIONI SEGNALI:")
	if TimeManager and PlayerManager:
		var is_connected = TimeManager.survival_penalty_tick.is_connected(PlayerManager._on_survival_penalty_tick)
		print("  TimeManager → PlayerManager: %s" % ("✅ CONNESSO" if is_connected else "❌ DISCONNESSO"))
	
	print("\n🎮 CONTROLLI TEST:")
	print("  [F5] Test avanzamento tempo")
	print("  [F6] Test ciclo giorno/notte") 
	print("  [F7] Test penalità sopravvivenza")
	print("  [F8] Test save/load")
	print("  [F9] Status sistema (questo)")
	print("  [F10] Test danno HP critico")
	
	print("✅ Status completo mostrato")

## Test F10: Danno HP critico immediato (NUOVO)
func test_critical_hp_damage() -> void:
	print("\n🧪 === TEST F10: DANNO HP CRITICO IMMEDIATO ===")
	
	if not PlayerManager:
		print("❌ PlayerManager non disponibile")
		return
	
	print("💊 HP iniziale: %d/%d" % [PlayerManager.hp, PlayerManager.max_hp])
	print("💊 Risorse iniziali: Food %d, Water %d" % [PlayerManager.food, PlayerManager.water])
	
	# Scenario 1: Azzera solo food
	print("\n🍖 TEST FAME CRITICA:")
	var original_food = PlayerManager.food
	PlayerManager.modify_food(-PlayerManager.food)  # Azzera food completamente
	print("  Food azzerato: %d (era %d)" % [PlayerManager.food, original_food])
	PlayerManager._check_critical_survival_damage()
	print("  HP dopo fame critica: %d/%d (-20 HP previsto)" % [PlayerManager.hp, PlayerManager.max_hp])
	
	# Scenario 2: Azzera solo water  
	print("\n💧 TEST SETE CRITICA:")
	var original_water = PlayerManager.water
	PlayerManager.modify_water(-PlayerManager.water)  # Azzera water completamente
	print("  Water azzerato: %d (era %d)" % [PlayerManager.water, original_water])
	PlayerManager._check_critical_survival_damage()
	print("  HP dopo sete critica: %d/%d (-25 HP previsto)" % [PlayerManager.hp, PlayerManager.max_hp])
	
	# Calcola danno totale
	var total_damage = 100 - PlayerManager.hp
	print("\n📊 RIEPILOGO:")
	print("  Danno totale subito: %d HP" % total_damage)
	print("  HP rimanenti: %d/%d" % [PlayerManager.hp, PlayerManager.max_hp])
	
	# Verifica avviso game over
	if PlayerManager.hp <= 25:
		print("  ⚠️ AVVISO GAME OVER: HP criticamente bassi!")
	
	# Test movimento notturno
	print("\n🌙 TEST MOVIMENTO NOTTURNO:")
	if TimeManager.is_night():
		print("  È notte: movimento player avrà penalità -2 HP")
	else:
		print("  È giorno: nessuna penalità movimento")
	
	print("✅ Test danno HP critico completato") 