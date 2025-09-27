# =============================================================================
# 🛡️ SISTEMA EVENTI NARRATIVI - CODICE IMMUTABILE
# =============================================================================
#
# ⚠️  ATTENZIONE: IL SISTEMA EVENTI È CONSIDERATO IMMUTABILE
#
# Gli eventi narrativi e le loro conseguenze sono stati progettati per creare
# momenti memorabili e scelte significative nel mondo post-apocalittico.
# Ogni evento contribuisce all'immersione e alla narrativa ramificata.
#
# 🚫 NESSUN LLM DEVE MODIFICARE:
#    - I testi degli eventi esistenti
#    - Le conseguenze degli eventi
#    - La logica di triggering eventi
#    - I messaggi di risultato eventi
#    - Le probabilità di spawn eventi
#
# 📋 AUTORIZZAZIONE RICHIESTA PER:
#    - Aggiunta di nuovi eventi con testi originali
#    - Modifiche al bilanciamento probabilità
#    - Nuovi tipi di conseguenze eventi
#    - Estensioni del sistema skill check
#
# 🎯 MOTIVAZIONE:
#    Gli eventi sono i momenti chiave dell'esperienza narrativa.
#    Ogni modifica potrebbe alterare il bilanciamento e l'immersione.
#
# 🔒 FIRMA DI PROTEZIONE: ELIANO_EVENTS_IMMUTABLE_V1.0
# =============================================================================

# EventManager.gd
# Singleton per la gestione degli eventi del gioco
# Gestisce il triggering, processing e applicazione conseguenze degli eventi

extends Node

# Segnali per comunicazione con altri sistemi
signal event_triggered(event_data: Dictionary)
# signal event_choice_resolved(result_text: String, narrative_log: String, skill_check_details: Dictionary) # OBSOLETO

signal skill_check_completed(skill_check_details: Dictionary)
signal event_consequences_applied(narrative_log: String)

# Segnali per disaccoppiamento da PlayerManager (M-CLEANUP-2.1)
signal item_transaction_requested(transaction_data: Dictionary)
signal status_change_requested(status_to_add: PlayerManager.Status)
signal resource_change_requested(resource_type: String, amount: int)
signal experience_gain_requested(amount: int, reason: String)
signal combat_trigger_requested(enemy_id: String)

# Riferimenti ai manager
@onready var player_manager: PlayerManager
@onready var data_manager: DataManager
@onready var quest_manager: QuestManager
@onready var combat_manager: Node

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
	quest_manager = get_node("/root/QuestManager")
	combat_manager = get_node("/root/CombatManager")

	if not player_manager:
		print("[EventManager] ERRORE: PlayerManager non trovato!")
		return

	if not data_manager:
		print("[EventManager] ERRORE: DataManager non trovato!")
		return

	if not quest_manager:
		print("[EventManager] ERRORE: QuestManager non trovato!")
		return

	if not combat_manager:
		print("[EventManager] ERRORE: CombatManager non trovato!")
		return
	
	# Carica e organizza eventi
	_load_and_cache_events()
	_normalize_all_cached_events()
	
	print("[EventManager] EventManager inizializzato con successo")

# Carica tutti gli eventi e li organizza per bioma
func _load_and_cache_events():
	print("[EventManager] Caricamento eventi...")
	cached_events.clear()
	biome_event_pools.clear()
	var seen_ids = {}

	# Carica eventi specifici per bioma
	_load_events_from_dir("res://data/events/biomes", seen_ids)
	
	# Carica esplicitamente le categorie di eventi globali
	_load_events_from_file("res://data/events/random_events_godot.json", seen_ids)
	_load_events_from_file("res://data/events/easter_eggs_godot.json", seen_ids)
	_load_events_from_file("res://data/events/lore_events_complete.json", seen_ids)
	_load_events_from_file("res://data/events/unique_events_godot.json", seen_ids)

	print("[EventManager] Caricati %d eventi totali." % cached_events.size())
	for biome in biome_event_pools.keys():
		print("   - Bioma '%s': %d eventi" % [biome, biome_event_pools[biome].size()])

# Normalizza tutti gli eventi in cache dopo il caricamento
func _normalize_all_cached_events():
	print("[EventManager] Normalizzazione schemi eventi...")
	for event_id in cached_events:
		var event = cached_events[event_id]
		cached_events[event_id] = _normalize_event_schema(event)
	print("[EventManager] Normalizzazione completata.")

# Carica un singolo file di eventi
func _load_events_from_file(file_path: String, seen_ids: Dictionary) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[EventManager] ERRORE: Impossibile aprire il file: ", file_path)
		return
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result != OK or not json.data is Dictionary:
		print("[EventManager] ERRORE: JSON non valido in ", file_path)
		return
	
	var data = json.data
	if not data is Dictionary:
		print("[EventManager] ERRORE: Formato non valido in ", file_path)
		return
	
	print("   ✅ Caricato: ", file_path.get_file())
	for biome_key in data.keys():
		var biome_events = data[biome_key]
		if biome_events is Array:
			var normalized_biome = _normalize_biome_name(biome_key)
			for event_data in biome_events:
				if event_data is Dictionary and event_data.has("id"):
					var event_id = event_data.id
					if seen_ids.has(event_id): continue
					event_data["biome"] = normalized_biome
					cached_events[event_id] = event_data
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
	
	biome_event_pools[biome].append(event)

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

## Triggera un evento specifico tramite il suo ID
func trigger_specific_event(event_id: String) -> bool:
	if not cached_events.has(event_id):
		print("[EventManager] ERRORE: Tentativo di triggerare evento specifico non esistente: ", event_id)
		return false
	
	var selected_event = cached_events[event_id]
	
	print("[EventManager] Evento specifico triggerato: ", selected_event["id"])
	
	# Imposta evento corrente per UI
	current_event = selected_event
	current_event_id = selected_event["id"]
	
	# Emetti segnale
	event_triggered.emit(selected_event)
	
	# Resetta cooldown eventi normali
	get_node("/root/MainGame")._reset_cooldowns()
	
	return true

# Applica le conseguenze di un evento
func _apply_event_consequences(consequences: Dictionary):
	print("[EventManager] Applicazione conseguenze: ", consequences)
	
	# Usa la funzione del PlayerManager per applicare le conseguenze
	player_manager.apply_skill_check_result({}, consequences)

## Gestisce l'applicazione di una ricompensa da un evento.
func _apply_reward(reward_data: Dictionary):
	# Emette segnali basati sui dati della ricompensa
	if reward_data.has("items_gained"):
		item_transaction_requested.emit({"items_gained": reward_data.items_gained})
	
	if reward_data.has("experience"):
		experience_gain_requested.emit(reward_data.experience, "Evento")
		
	if reward_data.has("hp_change") and reward_data.hp_change > 0:
		resource_change_requested.emit("hp", reward_data.hp_change)


## Gestisce l'applicazione di una penalità da un evento.
## Creato per M3.T4.3 per centralizzare la logica delle penalità.
## MODIFICATO per M-CLEANUP-2.1 per usare segnali
func _apply_penalty(penalty_data: Dictionary):
	if penalty_data.has("type"):
		match penalty_data.type:
			"damage":
				if penalty_data.has("amount"):
					resource_change_requested.emit("hp", -penalty_data.amount)
			"status":
				if penalty_data.has("status"):
					# Converti la stringa dello stato (es. "WOUNDED") nell'enum del PlayerManager
					var status_enum = PlayerManager.Status.get(penalty_data.status.to_upper())
					if status_enum != null:
						status_change_requested.emit(status_enum)
			"time":
				if penalty_data.has("minutes"):
					var minutes_to_advance = penalty_data.get("minutes", 0)
					if minutes_to_advance > 0:
						# Ogni mossa equivale a 30 minuti. Calcoliamo il numero di mosse.
						var moves = int(ceil(float(minutes_to_advance) / 30.0))
						# NOTA: TimeManager non è PlayerManager, la chiamata diretta è accettabile qui
						TimeManager.advance_time_by_moves(moves)
			"remove_item":
				if penalty_data.has("id") and penalty_data.has("quantity"):
					var transaction = {"items_lost": [{"id": penalty_data.id, "quantity": penalty_data.quantity}]}
					item_transaction_requested.emit(transaction)

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

func _load_events_from_dir(dir_path: String, seen_ids: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		print("[EventManager] ⚠️ Cartella eventi non trovata: ", dir_path)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path = dir_path.path_join(file_name)
			_load_events_from_file(full_path, seen_ids)
		file_name = dir.get_next()
	dir.list_dir_end()

# Sostituisci l'intera funzione 'process_event_choice' con questa: 
# Processa la scelta del giocatore per un evento (Logica riscritta per M3.T4.FIX)
func process_event_choice(event_id: String, choice_index: int) -> void:
	print("[EventManager] Processing scelta evento: ", event_id, " - scelta index: ", choice_index)

	if not cached_events.has(event_id):
		print("[EventManager] ERRORE: Evento non trovato: ", event_id)
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
	var consequences = {}

	if choice.has("skill_check"):
		var check_data = choice.get("skill_check", {})
		var stat = check_data.get("stat", "forza")
		var difficulty = check_data.get("difficulty", 15)
		
		skill_check_details = SkillCheckManager.perform_check(stat, difficulty)

		# Emetti subito il risultato dello skill check per l'UI
		skill_check_completed.emit(skill_check_details)

		if skill_check_details.get("success", false):
			consequences = choice.get("consequences_success", {})
			result_text = consequences.get("narrative_text", "Successo!")
		else:
			consequences = choice.get("consequences_failure", {})
			result_text = consequences.get("narrative_text", "Fallimento.")
	else:
		consequences = choice.get("consequences", {})
		result_text = consequences.get("narrative_text", "Azione completata.")

	if not consequences.is_empty():
		_apply_event_consequences(consequences)

	narrative_log = result_text
	
	event_consequences_applied.emit(narrative_log)

# ═══════════════════════════════════════════════════════════════════════════════
# INTEGRAZIONE COMBAT SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

## Triggera un incontro nemico da un evento
func trigger_enemy_encounter(biome: String) -> void:
	print("[EventManager] Trigger incontro nemico in bioma: ", biome)

	# Seleziona nemico basato su bioma
	var enemy_id = _select_random_enemy_for_biome(biome)

	if enemy_id.is_empty():
		print("[EventManager] Nessun nemico disponibile per bioma: ", biome)
		return

	# Avvia combattimento
	if combat_manager and combat_manager.start_combat(enemy_id):
		event_triggered.emit({
			"type": "combat",
			"enemy_id": enemy_id,
			"description": "Sei stato attaccato!"
		})
		print("[EventManager] Incontro nemico triggerato: ", enemy_id)
	else:
		print("[EventManager] ERRORE: Impossibile avviare combattimento")

## Seleziona un nemico casuale per il bioma
func _select_random_enemy_for_biome(biome: String) -> String:
	# Mappatura bioma → nemici possibili
	var biome_enemies = {
		"foreste": ["wolf", "bandit"],
		"pianure": ["wolf", "bandit", "mutant"],
		"città": ["bandit", "mutant"],
		"villaggi": ["bandit"],
		"fiumi": ["wolf", "mutant"],
		"ristoro": ["bandit"]
	}

	var enemies = biome_enemies.get(biome, ["wolf"])
	return enemies[randi() % enemies.size()]

# Funzione rimossa: _load_unique_events
# Gli eventi unici sono ora caricati tramite unique_events.json nella directory biomes

# Funzione rimossa: _load_rest_stop_events
# Gli eventi REST_STOP sono ora caricati tramite rest_stop_events.json nella directory biomes
