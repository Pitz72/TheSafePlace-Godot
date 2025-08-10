# EventManager.gd
# Singleton per la gestione degli eventi del gioco
# Gestisce il triggering, processing e applicazione conseguenze degli eventi

extends Node

# Segnali per comunicazione con altri sistemi
signal event_triggered(event_data: Dictionary)
signal event_completed(event_id: String, choice_index: int, result: Dictionary, skill_check_result)
signal skill_check_performed(stat_name: String, result: Dictionary)

# Riferimenti ai manager
@onready var player_manager: PlayerManager
@onready var data_manager: DataManager

# Cache eventi per performance
var cached_events: Dictionary = {}
var biome_event_pools: Dictionary = {}

# Gestione evento corrente
var current_event: Dictionary = {}
var current_event_id: String = ""

# Configurazione probabilità eventi per bioma
var biome_event_chances: Dictionary = {
	"pianure": 0.15,
	"foreste": 0.20,
	"villaggi": 0.25,
	"citta": 0.30,
	"fiumi": 0.18,
	"montagne": 0.12
}

func _ready():
	print("[EventManager] Inizializzazione EventManager...")
	
	# Ottieni riferimenti ai manager
	player_manager = get_node("/root/PlayerManager")
	data_manager = get_node("/root/DataManager")
	
	if not player_manager:
		print("[EventManager] ERRORE: PlayerManager non trovato!")
		return
		
	if not data_manager:
		print("[EventManager] ERRORE: DataManager non trovato!")
		return
	
	# Carica e organizza eventi
	_load_and_cache_events()
	
	print("[EventManager] EventManager inizializzato con successo")

# Carica tutti gli eventi e li organizza per bioma
func _load_and_cache_events():
	print("[EventManager] Caricamento eventi...")
	
	# Carica eventi random
	var random_events = data_manager.load_json_file("data/events/random_events.json")
	if random_events:
		print("   ✅ Caricato: random_events.json")
		# Itera attraverso ogni bioma nel file
		for biome_key in random_events.keys():
			var events_array = random_events[biome_key]
			if events_array is Array:
				for event in events_array:
					if event.has("id"):
						# Aggiungi il bioma all'evento per il processing
						event["biome"] = _normalize_biome_name(biome_key)
						cached_events[event["id"]] = event
						_add_event_to_biome_pool(event)
	
	# Carica eventi unici
	var unique_events = data_manager.load_json_file("data/events/unique_events.json")
	if unique_events:
		print("   ✅ Caricato: unique_events.json")
		# Gestisce la struttura con chiave "UNIQUE"
		if unique_events.has("UNIQUE") and unique_events["UNIQUE"] is Array:
			for event in unique_events["UNIQUE"]:
				if event.has("id"):
					event["biome"] = "unique"
					cached_events[event["id"]] = event
					_add_event_to_biome_pool(event)
	
	print("[EventManager] Caricati ", cached_events.size(), " eventi totali")
	for biome in biome_event_pools.keys():
		print("[EventManager] Bioma '", biome, "': ", biome_event_pools[biome].size(), " eventi")

# Normalizza i nomi dei biomi per la compatibilità
func _normalize_biome_name(biome_key: String) -> String:
	match biome_key.to_upper():
		"PLAINS":
			return "pianure"
		"FOREST":
			return "foreste"
		"VILLAGE":
			return "villaggi"
		"CITY":
			return "citta"
		"RIVER":
			return "fiumi"
		"REST_STOP":
			return "rest_stop"
		"UNIQUE":
			return "unique"
		_:
			return biome_key.to_lower()

# Aggiunge un evento al pool del bioma appropriato
func _add_event_to_biome_pool(event: Dictionary):
	if not event.has("biome"):
		return
		
	var biome = event["biome"]
	if not biome_event_pools.has(biome):
		biome_event_pools[biome] = []
		
	biome_event_pools[biome].append(event)

# Funzione principale: triggera un evento casuale per il bioma specificato
func trigger_random_event(biome: String) -> Dictionary:
	print("[EventManager] Tentativo trigger evento per bioma: ", biome)
	
	# Verifica se ci sono eventi per questo bioma
	if not biome_event_pools.has(biome) or biome_event_pools[biome].is_empty():
		print("[EventManager] Nessun evento disponibile per bioma: ", biome)
		return {"triggered": false, "reason": "no_events_for_biome"}
	
	# Controlla probabilità evento
	var chance = biome_event_chances.get(biome, 0.15)
	var roll = randf()
	
	print("[EventManager] Probabilità evento: ", chance, " - Roll: ", roll)
	
	if roll > chance:
		print("[EventManager] Evento non triggerato (probabilità)")
		return {"triggered": false, "reason": "probability_failed"}
	
	# Seleziona evento casuale dal pool
	var available_events = biome_event_pools[biome]
	var selected_event = available_events[randi() % available_events.size()]
	
	print("[EventManager] Evento triggerato: ", selected_event["id"])
	
	# Imposta evento corrente per UI
	current_event = selected_event
	current_event_id = selected_event["id"]
	
	# Emetti segnale
	event_triggered.emit(selected_event)
	
	return {
		"triggered": true,
		"event": selected_event,
		"biome": biome
	}

# Processa la scelta del giocatore per un evento
func process_event_choice(event_id: String, choice_index: String) -> Dictionary:
	print("[EventManager] Processing scelta evento: ", event_id, " - scelta index: ", choice_index)
	
	# Trova l'evento
	if not cached_events.has(event_id):
		print("[EventManager] ERRORE: Evento non trovato: ", event_id)
		return {"success": false, "error": "event_not_found"}
	
	var event = cached_events[event_id]
	var choices = event.get("choices", [])
	
	# Converti choice_index in intero
	var choice_idx = choice_index.to_int()
	
	# Verifica che l'indice sia valido
	if choice_idx < 0 or choice_idx >= choices.size():
		print("[EventManager] ERRORE: Indice scelta non valido: ", choice_idx, " (max: ", choices.size() - 1, ")")
		return {"success": false, "error": "choice_index_invalid"}
	
	# Ottieni la scelta selezionata
	var selected_choice = choices[choice_idx]
	
	# Processa skill check se presente
	var skill_check_result = null
	if selected_choice.has("skill_check"):
		skill_check_result = _process_skill_check(selected_choice["skill_check"])
		print("[EventManager] Risultato skill check: ", skill_check_result)
	
	# Determina le conseguenze da applicare
	var consequences_to_apply = {}
	
	if skill_check_result:
		# Usa conseguenze basate su successo/fallimento skill check
		if skill_check_result["success"]:
			consequences_to_apply = selected_choice.get("consequences_success", {})
		else:
			consequences_to_apply = selected_choice.get("consequences_failure", {})
	else:
		# Usa conseguenze dirette
		consequences_to_apply = selected_choice.get("consequences", {})
	
	# Applica le conseguenze
	if not consequences_to_apply.is_empty():
		_apply_event_consequences(consequences_to_apply)
	
	# Emetti segnale completamento
	event_completed.emit(event_id, choice_idx, selected_choice, skill_check_result)
	
	return {
		"success": true,
		"event_id": event_id,
		"choice_index": choice_idx,
		"choice_data": selected_choice,
		"skill_check_result": skill_check_result,
		"consequences_applied": consequences_to_apply
	}

# Processa un skill check
func _process_skill_check(skill_check_data: Dictionary) -> Dictionary:
	var stat_name = skill_check_data.get("stat", "forza")
	var difficulty = skill_check_data.get("difficulty", 15)
	var modifier = skill_check_data.get("modifier", 0)
	
	print("[EventManager] Esecuzione skill check: ", stat_name, " vs DC ", difficulty, " (mod: ", modifier, ")")
	
	# Chiama il sistema skill check del PlayerManager
	var result = player_manager.skill_check(stat_name, difficulty, modifier)
	
	# Emetti segnale
	skill_check_performed.emit(stat_name, result)
	
	return result

# Applica le conseguenze di un evento
func _apply_event_consequences(consequences: Dictionary):
	print("[EventManager] Applicazione conseguenze: ", consequences)
	
	# Usa la funzione del PlayerManager per applicare le conseguenze
	player_manager.apply_skill_check_result({}, consequences)

# Ottieni eventi disponibili per un bioma
func get_events_for_biome(biome: String) -> Array:
	return biome_event_pools.get(biome, [])

# Ottieni un evento specifico per ID
func get_event_by_id(event_id: String) -> Dictionary:
	return cached_events.get(event_id, {})

# Ottieni statistiche eventi
func get_event_stats() -> Dictionary:
	return {
		"total_events": cached_events.size(),
		"biome_pools": biome_event_pools.keys(),
		"events_per_biome": _get_events_per_biome_count()
	}

func _get_events_per_biome_count() -> Dictionary:
	var counts = {}
	for biome in biome_event_pools.keys():
		counts[biome] = biome_event_pools[biome].size()
	return counts

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIONE SCELTE EVENTI UI (FASE 4)
# ═══════════════════════════════════════════════════════════════════════════════
