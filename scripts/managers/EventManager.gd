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

# Configurazione probabilità eventi per bioma (v0.3.5 - Aumentate per migliore gameplay)
var biome_event_chances: Dictionary = {
	"pianure": 0.35,     # Era 0.15 - Aumentato per più eventi
	"foreste": 0.45,     # Era 0.20 - Foreste più pericolose
	"villaggi": 0.55,    # Era 0.25 - Villaggi più interessanti
	"citta": 0.65,       # Era 0.30 - Città più dinamiche
	"fiumi": 0.40,       # Era 0.18 - Attraversamenti più avventurosi
	"montagne": 0.30     # Era 0.12 - Montagne più sfidanti
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
	
	# Svuota cache per ricarichi futuri
	cached_events.clear()
	biome_event_pools.clear()
	
	# Tracciamento ID per evitare duplicati tra fonti diverse
	var seen_ids: Dictionary = {}
	
	# 1) Carica eventi modulari per bioma dalla cartella data/events/biomes
	_load_events_from_biomes_dir(seen_ids)
	
	# 2) Gli eventi unici sono ora caricati tramite unique_events.json nella directory biomes
	
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
	
	# Normalizza l'evento prima di aggiungerlo al pool
	var normalized_event = _normalize_event_schema(event)
	biome_event_pools[biome].append(normalized_event)

# Normalizza lo schema degli eventi da formato legacy a formato moderno
func _normalize_event_schema(event: Dictionary) -> Dictionary:
	var normalized = event.duplicate(true)
	
	# Normalizza le scelte
	if normalized.has("choices"):
		for choice in normalized["choices"]:
			_normalize_choice_schema(choice)
	
	return normalized

# Normalizza una singola scelta da formato legacy a formato moderno
func _normalize_choice_schema(choice: Dictionary):
	# Converte skillCheck -> skill_check
	if choice.has("skillCheck"):
		choice["skill_check"] = choice["skillCheck"]
		choice.erase("skillCheck")
	
	# Se ha skill_check, gestisce reward/penalty -> consequences_success/failure
	if choice.has("skill_check"):
		if choice.has("reward"):
			choice["consequences_success"] = _convert_legacy_consequence(choice["reward"])
			choice.erase("reward")
		
		if choice.has("penalty"):
			choice["consequences_failure"] = _convert_legacy_consequence(choice["penalty"])
			choice.erase("penalty")
		
		# Gestisce successText e failureText (per futura implementazione UI)
		if choice.has("successText"):
			if not choice.has("consequences_success"):
				choice["consequences_success"] = {}
			choice["consequences_success"]["narrative_text"] = choice["successText"]
			choice.erase("successText")
		
		if choice.has("failureText"):
			if not choice.has("consequences_failure"):
				choice["consequences_failure"] = {}
			choice["consequences_failure"]["narrative_text"] = choice["failureText"]
			choice.erase("failureText")
	else:
		# Senza skill_check, converte reward/penalty -> consequences
		if choice.has("reward"):
			choice["consequences"] = _convert_legacy_consequence(choice["reward"])
			choice.erase("reward")
		elif choice.has("penalty"):
			choice["consequences"] = _convert_legacy_consequence(choice["penalty"])
			choice.erase("penalty")

# Converte una conseguenza legacy nel formato moderno
func _convert_legacy_consequence(legacy_consequence: Dictionary) -> Dictionary:
	var modern_consequence = {}
	
	match legacy_consequence.get("consequence_type", ""):
		"damage":
			modern_consequence["hp_change"] = -legacy_consequence.get("amount", 0)
		"heal":
			modern_consequence["hp_change"] = legacy_consequence.get("amount", 0)
		"item":
			var item = legacy_consequence.get("item", {})
			modern_consequence["items_gained"] = [item]
		"items":
			modern_consequence["items_gained"] = legacy_consequence.get("items", [])
		"status":
			modern_consequence["status_effects"] = [legacy_consequence.get("status", "")]
		"stats":
			# Per modifiche dirette alle risorse
			if legacy_consequence.has("hp"):
				modern_consequence["hp_change"] = legacy_consequence["hp"]
			if legacy_consequence.has("food"):
				modern_consequence["food_change"] = legacy_consequence["food"]
			if legacy_consequence.has("water"):
				modern_consequence["water_change"] = legacy_consequence["water"]
		"full_hydrate":
			modern_consequence["water_change"] = 999  # Valore alto per idratazione completa
		"remove_item":
			# TODO: Implementare rimozione oggetti se necessario
			pass
		_:
			# Per tipi sconosciuti o complessi, mantieni la struttura originale
			modern_consequence = legacy_consequence.duplicate(true)
	
	return modern_consequence

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

func _load_events_from_biomes_dir(seen_ids: Dictionary) -> void:
	var dir := DirAccess.open("res://data/events/biomes")
	if dir == null:
		print("[EventManager] ⚠️ Cartella eventi per bioma non trovata, fallback al file legacy se disponibile")
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var rel_path := "data/events/biomes/" + file_name
			var json_obj := data_manager.load_json_file(rel_path)
			if json_obj:
				print("   ✅ Caricato: ", file_name)
				for biome_key in json_obj.keys():
					var events_array = json_obj[biome_key]
					if events_array is Array:
						for event in events_array:
							if event.has("id"):
								var ev_id: String = event["id"]
								if seen_ids.has(ev_id):
									continue
								event["biome"] = _normalize_biome_name(biome_key)
								cached_events[ev_id] = event
								_add_event_to_biome_pool(event)
								seen_ids[ev_id] = true
		file_name = dir.get_next()
	dir.list_dir_end()

# Funzione rimossa: _load_unique_events
# Gli eventi unici sono ora caricati tramite unique_events.json nella directory biomes

# Funzione rimossa: _load_rest_stop_events
# Gli eventi REST_STOP sono ora caricati tramite rest_stop_events.json nella directory biomes
