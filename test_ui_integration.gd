extends Node

# Test per verificare l'integrazione UI del sistema eventi (FASE 4)

func _ready():
	print("\n" + "=".repeat(60))
	print("TEST INTEGRAZIONE UI SISTEMA EVENTI - FASE 4")
	print("=".repeat(60))
	
	# Test 1: Verifica caricamento EventManager
	test_event_manager_loading()
	
	# Test 2: Verifica segnali EventManager
	test_event_manager_signals()
	
	# Test 3: Simula trigger evento e gestione UI
	test_ui_event_flow()
	
	# Test 4: Verifica gestione scelte
	test_choice_processing()
	
	print("\n" + "=".repeat(60))
	print("TEST COMPLETATI")
	print("=".repeat(60))

func test_event_manager_loading():
	print("\n--- Test 1: Caricamento EventManager ---")
	
	var event_manager = get_node("/root/EventManager")
	if event_manager:
		print("✅ EventManager caricato correttamente")
		
		# Verifica eventi caricati
		var stats = event_manager.get_event_stats()
		print("📊 Eventi totali: ", stats["total_events"])
		print("📊 Biomi supportati: ", stats["biome_pools"].size())
		
		if stats["total_events"] > 0:
			print("✅ Eventi caricati con successo")
		else:
			print("❌ Nessun evento caricato")
	else:
		print("❌ EventManager non trovato")

func test_event_manager_signals():
	print("\n--- Test 2: Segnali EventManager ---")
	
	var event_manager = get_node("/root/EventManager")
	if not event_manager:
		print("❌ EventManager non disponibile")
		return
	
	# Verifica segnali disponibili
	var signals = event_manager.get_signal_list()
	var required_signals = ["event_triggered", "event_completed", "skill_check_performed"]
	
	for signal_name in required_signals:
		var found = false
		for signal_info in signals:
			if signal_info["name"] == signal_name:
				found = true
				break
		
		if found:
			print("✅ Segnale '", signal_name, "' disponibile")
		else:
			print("❌ Segnale '", signal_name, "' mancante")

func test_ui_event_flow():
	print("\n--- Test 3: Flusso UI Eventi ---")
	
	var event_manager = get_node("/root/EventManager")
	if not event_manager:
		print("❌ EventManager non disponibile")
		return
	
	# Connetti segnale per test
	var signal_received = false
	var event_data = {}
	
	event_manager.event_triggered.connect(func(data): 
		signal_received = true
		event_data = data
		print("📡 Segnale event_triggered ricevuto: ", data.get("id", "N/A"))
	)
	
	# Tenta trigger evento
	print("🎲 Tentativo trigger evento per bioma 'pianure'...")
	var result = event_manager.trigger_random_event("pianure")
	
	if result["triggered"]:
		print("✅ Evento triggerato con successo")
		print("📋 ID Evento: ", result["event"]["id"])
		print("📋 Titolo: ", result["event"]["title"])
		
		if signal_received:
			print("✅ Segnale UI ricevuto correttamente")
		else:
			print("❌ Segnale UI non ricevuto")
	else:
		print("❌ Evento non triggerato: ", result.get("reason", "unknown"))

func test_choice_processing():
	print("\n--- Test 4: Gestione Scelte ---")
	
	var event_manager = get_node("/root/EventManager")
	if not event_manager:
		print("❌ EventManager non disponibile")
		return
	
	# Verifica metodo process_event_choice
	if event_manager.has_method("process_event_choice"):
		print("✅ Metodo 'process_event_choice' disponibile")
		
		# Connetti segnale event_completed
		var completion_received = false
		event_manager.event_completed.connect(func(event_id, choice_index, result):
			completion_received = true
			print("📡 Segnale event_completed ricevuto:")
			print("   - Event ID: ", event_id)
			print("   - Choice Index: ", choice_index)
			print("   - Result: ", result)
		)
		
		# Simula evento corrente per test
		var test_event = {
			"id": "test_event",
			"title": "Test Event",
			"choices": [
				{"text": "Scelta 1"},
				{"text": "Scelta 2"}
			]
		}
		
		event_manager.current_event = test_event
		event_manager.current_event_id = "test_event"
		print("🎯 Evento test impostato")
		
		# Testa scelta
		print("🎯 Processando scelta 0...")
		event_manager.process_event_choice("test_event", "0")
		
		if completion_received:
			print("✅ Gestione scelte funzionante")
		else:
			print("❌ Gestione scelte non funzionante")
	else:
		print("❌ Metodo 'process_event_choice' non disponibile")
