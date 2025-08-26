# EventManager.gd
# Singleton per la gestione degli eventi del gioco
# Gestisce il triggering, processing e applicazione conseguenze degli eventi

extends Node

# Segnali per comunicazione con altri sistemi
signal event_triggered(event_data: Dictionary)
signal event_choice_resolved(result_text: String, narrative_log: String, skill_check_details: Dictionary)

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
# NOTA: Montagne rimosse in quanto invalicabili - eventi redistribuiti su altri biomi
var biome_event_chances: Dictionary = {
	"pianure": 0.38,     # Era 0.35 - Aumentato per compensare montagne
	"foreste": 0.48,     # Era 0.45 - Aumentato per più diversità eventi natura
	"villaggi": 0.58,    # Era 0.55 - Aumentato per più eventi sociali
	"citta": 0.68,       # Era 0.65 - Aumentato per più eventi urbani
	"fiumi": 0.43        # Era 0.40 - Aumentato per attraversamenti più dinamici
	# montagne: RIMOSSO - terreno invalicabile, eventi redistribuiti
}

func _ready():
	print("EventManager pronto.")

## Inizializza il sistema eventi. Chiamato esplicitamente da MainGame.
func initialize_events():
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
	
	# Lista dei file eventi da caricare
	var event_files = [
		"res://data/events/biomes/city_events.json",
		"res://data/events/biomes/forest_events.json",
		"res://data/events/biomes/plains_events.json",
		"res://data/events/biomes/rest_stop_events.json",
		"res://data/events/biomes/river_events.json",
		"res://data/events/biomes/unique_events.json",
		"res://data/events/biomes/village_events.json"
	]
	
	# Carica ogni file
	for file_path in event_files:
		_load_single_event_file(file_path)
	
	print("[EventManager] Caricati ", cached_events.size(), " eventi totali")
	for biome in biome_event_pools.keys():
		print("[EventManager] Bioma '", biome, "': ", biome_event_pools[biome].size(), " eventi")

# Carica un singolo file di eventi
func _load_single_event_file(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[EventManager] ERRORE: File non trovato: ", file_path)
		return
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result != OK:
		print("[EventManager] ERRORE: JSON non valido in ", file_path)
		return
	
	var data = json.data
	if not data is Dictionary:
		print("[EventManager] ERRORE: Formato non valido in ", file_path)
		return
	
	print("   ✅ Caricato: ", file_path.get_file())
	
	# Processa i dati del file
	for biome_key in data.keys():
		var biome_events = data[biome_key]
		if biome_events is Array:
			var normalized_biome = _normalize_biome_name(biome_key)
			for event_data in biome_events:
				if event_data is Dictionary and event_data.has("id"):
					# Aggiungi bioma al dict evento se mancante
					if not event_data.has("biome"):
						event_data["biome"] = normalized_biome
					
					# Aggiorna cache eventi
					cached_events[event_data.id] = event_data
					
					# Aggiungi al pool bioma
					_add_event_to_biome_pool(event_data)

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
	
	match legacy_consequence.get("type", ""):
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
			var item_id = legacy_consequence.get("id", "")
			var quantity = legacy_consequence.get("quantity", 1)
			modern_consequence["items_lost"] = [{"id": item_id, "quantity": quantity}]
		_:
			# Per tipi sconosciuti o complessi, mantieni la struttura originale
			modern_consequence = legacy_consequence.duplicate(true)
	
	return modern_consequence

# Seleziona un evento casuale per il bioma specificato (con controlli di sicurezza)
func get_random_event(biome: String) -> Dictionary:
	# 1. Controlla che il bioma esista nel database
	if not biome_event_pools.has(biome):
		print("[EventManager] Bioma non trovato: ", biome)
		return {}
	
	# 2. Ottieni l'array di eventi per il bioma
	var biome_events = biome_event_pools[biome]
	
	# 3. Controlla che l'array non sia vuoto
	if biome_events.is_empty():
		print("[EventManager] Nessun evento disponibile per bioma: ", biome)
		return {}
	
	# 4. Seleziona un evento casuale dall'array
	var selected_event = biome_events.pick_random()
	
	# 5. Controllo di sicurezza finale
	if selected_event is Dictionary and selected_event.has("id"):
		return selected_event
	else:
		print("[ERROR] EventManager: Evento selezionato per il bioma '", biome, "' è malformato o non valido.")
		return {}  # Restituisce un dizionario vuoto per evitare crash

# Funzione principale: triggera un evento casuale per il bioma specificato
func trigger_random_event(biome: String) -> Dictionary:
	print("[EventManager] Tentativo trigger evento per bioma: ", biome)
	
	# Controlla probabilità evento
	var chance = biome_event_chances.get(biome, 0.15)
	var roll = randf()
	
	print("[EventManager] Probabilità evento: ", chance, " - Roll: ", roll)
	
	if roll > chance:
		print("[EventManager] Evento non triggerato (probabilità)")
		return {"triggered": false, "reason": "probability_failed"}
	
	# Usa la nuova funzione robusta per selezionare l'evento
	var selected_event = get_random_event(biome)
	
	# Controllo di sicurezza: verifica che l'evento sia valido
	if selected_event.is_empty():
		print("[EventManager] Nessun evento valido trovato per il bioma '", biome, "'. Salto il turno dell'evento.")
		return {"triggered": false, "reason": "no_valid_events"}
	
	# Solo ora possiamo accedere a selected_event["id"] in sicurezza
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

# Sostituisci l'intera funzione 'process_event_choice' con questa: 
func process_event_choice(event_id: String, choice_index: int) -> void:
	print("[EventManager] Processing scelta evento: ", event_id, " - scelta index: ", choice_index)

	# Controlli di sicurezza iniziali
	if not cached_events.has(event_id):
		print("[EventManager] ERRORE: Evento non trovato in cache: ", event_id)
		return

	var event = cached_events[event_id]
	var choices = event.get("choices", [])

	if choice_index < 0 or choice_index >= choices.size():
		print("[EventManager] ERRORE: Indice scelta non valido: ", choice_index)
		return

	var choice = choices[choice_index]
	var result_text = ""
	var narrative_log = ""
	var skill_check_details = {}

	# --- INIZIO LOGICA DI RISOLUZIONE ---
	if choice.has("skillCheck"):
		var check_data = choice.skillCheck
		skill_check_details = SkillCheckManager.perform_check(check_data.stat, check_data.difficulty)

		if skill_check_details.success:
			result_text = choice.get("successText", "Successo!")
			if choice.has("reward"):
				PlayerManager.apply_item_transaction(choice.reward)
		else:
			result_text = choice.get("failureText", "Fallimento.")
			if choice.has("penalty"):
				_apply_penalty(choice.penalty)
	else:
		# Scelta senza skill check
		result_text = choice.get("resultText", "Azione completata.")
		if choice.has("reward"):
			PlayerManager.apply_item_transaction(choice.reward)
		if choice.has("penalty"):
			_apply_penalty(choice.penalty)
	# --- FINE LOGICA DI RISOLUZIONE ---

	narrative_log = result_text
	event_choice_resolved.emit(result_text, narrative_log, skill_check_details)



# Applica le conseguenze di un evento
func _apply_event_consequences(consequences: Dictionary):
	print("[EventManager] Applicazione conseguenze: ", consequences)
	
	# Usa la funzione del PlayerManager per applicare le conseguenze
	player_manager.apply_skill_check_result({}, consequences)

## Gestisce l'applicazione di una penalità da un evento.
## Creato per M3.T4.3 per centralizzare la logica delle penalità.
func _apply_penalty(penalty_data: Dictionary):
	if penalty_data.has("type"):
		match penalty_data.type:
			"damage":
				if penalty_data.has("amount"):
					PlayerManager.modify_hp(-penalty_data.amount)
			"status":
				if penalty_data.has("status"):
					# Converti la stringa dello stato (es. "WOUNDED") nell'enum del PlayerManager
					var status_enum = PlayerManager.Status.get(penalty_data.status.to_upper())
					if status_enum != null:
						PlayerManager.add_status(status_enum)
			"time":
				if penalty_data.has("minutes"):
					var minutes_to_advance = penalty_data.get("minutes", 0)
					if minutes_to_advance > 0:
						# Ogni mossa equivale a 30 minuti. Calcoliamo il numero di mosse.
						var moves = int(ceil(float(minutes_to_advance) / 30.0))
						TimeManager.advance_time_by_moves(moves)
			"remove_item":
				if penalty_data.has("item_id") and penalty_data.has("quantity"):
					PlayerManager.remove_item(penalty_data.item_id, penalty_data.quantity)

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
