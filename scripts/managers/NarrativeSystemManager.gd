extends Node

## NarrativeSystemManager - Consolidamento NarrativeManager + QuestManager + EventManager
##
## Responsabilità unificate:
## - Sistema progressione emotiva e narrativa (NarrativeManager)
## - Gestione quest principali e secondarie (QuestManager)
## - Sistema eventi dinamici e skill check (EventManager)
## - Integrazione narrativa completa per esperienza immersiva

# ========================================
# ENUM E COSTANTI
# ========================================

enum EmotionalState {
	COLD = 0,        # Distaccato, pragmatico
	GUARDED = 1,     # Diffidente ma curioso
	OPEN = 2,        # Aperto alle emozioni
	CONNECTED = 3,   # Connesso ai ricordi
	TRANSFORMED = 4  # Cambiato dall'esperienza
}

# ========================================
# SEGNALI PUBBLICI - NARRATIVA
# ========================================

signal emotional_state_changed(new_state: EmotionalState, old_state: EmotionalState)
signal understanding_level_changed(new_level: int, old_level: int)
signal empathy_changed(character: String, new_level: int, old_level: int)
signal memory_strength_changed(memory: String, new_level: int, old_level: int)
signal wisdom_gained(amount: int, reason: String)

# ========================================
# SEGNALI PUBBLICI - QUEST
# ========================================

signal quest_started(quest_id: String)
signal quest_progressed(quest_id: String, stage_id: String)
signal quest_completed(quest_id: String)

# ========================================
# SEGNALI PUBBLICI - EVENTI
# ========================================

signal event_triggered(event_data: Dictionary)
signal skill_check_completed(skill_check_details: Dictionary)
signal event_consequences_applied(narrative_log: String)

# Segnali per transazioni con PlayerSystemManager
signal item_transaction_requested(transaction_data: Dictionary)
signal status_change_requested(status_to_add: String)
signal resource_change_requested(resource_type: String, amount: int)
signal experience_gain_requested(amount: int, reason: String)

# ========================================
# VARIABILI STATO EMOTIVO
# ========================================

## Livello di comprensione generale della storia
var understanding_level: int = 0

## Livello empatia per personaggi chiave
var character_empathy: Dictionary = {
	"elian": 0,      # Padre - Elian
	"lena": 0,       # Madre - Lena (ricordi)
	"ultimo": 0      # Se stesso
}

## Forza dei ricordi chiave
var memory_strength: Dictionary = {
	"silence": 0,        # Il silenzio della fine
	"water_lesson": 0,   # La lezione dell'acqua
	"blood_taste": 0,    # Il sapore del sangue
	"darkness_lesson": 0,# Imparare il buio
	"burden": 0,         # Il fardello del padre
	"angels": 0,         # Gli angeli della cenere
	"confession": 0,     # La confessione
	"truth": 0           # La verità finale
}

## Saggezza accumulata
var total_wisdom: int = 0

## Stato emotivo corrente
var current_emotional_state: EmotionalState = EmotionalState.COLD

# ========================================
# VARIABILI QUEST
# ========================================

## Stato delle quest
var active_quests: Dictionary = {}
var completed_quests: Array = []
var quest_progress: Dictionary = {}

## Quest principale
var main_quest_id: String = "main_quest_ultimate_surviver"
var main_quest_stages: Array = []

# ========================================
# VARIABILI EVENTI
# ========================================

## Cache eventi per performance
var cached_events: Dictionary = {}
var biome_event_pools: Dictionary = {}

## Gestione evento corrente
var current_event: Dictionary = {}
var current_event_id: String = ""

## Configurazione probabilità eventi per bioma
var biome_event_chances: Dictionary = {
	"pianure": 0.38,
	"foreste": 0.48,
	"villaggi": 0.58,
	"citta": 0.68,
	"fiumi": 0.43
}

# ========================================
# SOGLIE PROGRESSIONE
# ========================================

const UNDERSTANDING_THRESHOLDS = {
	EmotionalState.COLD: 0,
	EmotionalState.GUARDED: 25,
	EmotionalState.OPEN: 50,
	EmotionalState.CONNECTED: 75,
	EmotionalState.TRANSFORMED: 100
}

const EMPATHY_THRESHOLDS = {
	"elian": { "low": 10, "medium": 25, "high": 40, "max": 60 },
	"lena": { "low": 5, "medium": 15, "high": 30, "max": 50 },
	"ultimo": { "low": 15, "medium": 30, "high": 50, "max": 75 }
}

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready():
	print("📖 NarrativeSystemManager: Inizializzazione sistema narrativo...")
	_initialize_narrative_system()
	_initialize_quest_system()
	_initialize_event_system()
	_connect_signals()
	print("📖 NarrativeSystemManager: Sistema narrativo pronto")

func _initialize_narrative_system():
	"""Inizializza il sistema narrativo"""
	current_emotional_state = EmotionalState.COLD
	understanding_level = 0
	total_wisdom = 0
	print("💭 Sistema narrativo inizializzato - Stato: Freddo e pragmatico")

func _initialize_quest_system():
	"""Inizializza il sistema quest"""
	_load_main_quest()
	print("🎯 Sistema quest inizializzato")

func _initialize_event_system():
	"""Inizializza il sistema eventi"""
	_load_events_cache()
	print("⚡ Sistema eventi inizializzato")

func _connect_signals():
	"""Connette i segnali necessari"""
	# Connetti ai segnali del PlayerSystemManager per transazioni
	if item_transaction_requested.connect(_on_item_transaction_requested):
		pass
	if resource_change_requested.connect(_on_resource_change_requested):
		pass
	if experience_gain_requested.connect(_on_experience_gain_requested):
		pass

# ========================================
# API NARRATIVA - PROGRESSIONE EMOTIVA
# ========================================

func increase_understanding(amount: int, reason: String = "") -> void:
	"""Aumenta il livello di comprensione"""
	var old_level = understanding_level
	understanding_level = min(understanding_level + amount, 100)
	
	if understanding_level != old_level:
		understanding_level_changed.emit(understanding_level, old_level)
		_check_emotional_state_progression()
		
		if not reason.is_empty():
			print("🧠 Comprensione aumentata: +%d (%s)" % [amount, reason])

func increase_empathy(character: String, amount: int, reason: String = "") -> void:
	"""Aumenta l'empatia verso un personaggio"""
	if not character_empathy.has(character):
		print("⚠️ Personaggio non riconosciuto: %s" % character)
		return
	
	var old_level = character_empathy[character]
	var max_empathy = EMPATHY_THRESHOLDS[character]["max"]
	character_empathy[character] = min(old_level + amount, max_empathy)
	
	if character_empathy[character] != old_level:
		empathy_changed.emit(character, character_empathy[character], old_level)
		
		if not reason.is_empty():
			print("❤️ Empatia verso %s aumentata: +%d (%s)" % [character, amount, reason])

func strengthen_memory(memory: String, amount: int, reason: String = "") -> void:
	"""Rafforza un ricordo specifico"""
	if not memory_strength.has(memory):
		print("⚠️ Ricordo non riconosciuto: %s" % memory)
		return
	
	var old_strength = memory_strength[memory]
	memory_strength[memory] = min(old_strength + amount, 100)
	
	if memory_strength[memory] != old_strength:
		memory_strength_changed.emit(memory, memory_strength[memory], old_strength)
		
		if not reason.is_empty():
			print("🧠 Ricordo '%s' rafforzato: +%d (%s)" % [memory, amount, reason])

func gain_wisdom(amount: int, reason: String = "") -> void:
	"""Guadagna saggezza"""
	total_wisdom += amount
	wisdom_gained.emit(amount, reason)
	
	if not reason.is_empty():
		print("✨ Saggezza guadagnata: +%d (%s)" % [amount, reason])

func _check_emotional_state_progression():
	"""Controlla se il livello di comprensione permette progressione emotiva"""
	var new_state = current_emotional_state
	
	for state in UNDERSTANDING_THRESHOLDS:
		if understanding_level >= UNDERSTANDING_THRESHOLDS[state]:
			new_state = state
	
	if new_state != current_emotional_state:
		var old_state = current_emotional_state
		current_emotional_state = new_state
		emotional_state_changed.emit(new_state, old_state)
		print("🎭 Stato emotivo cambiato: %s → %s" % [_emotional_state_to_string(old_state), _emotional_state_to_string(new_state)])

func _emotional_state_to_string(state: EmotionalState) -> String:
	"""Converte stato emotivo in stringa"""
	match state:
		EmotionalState.COLD: return "Freddo"
		EmotionalState.GUARDED: return "Guardingo"
		EmotionalState.OPEN: return "Aperto"
		EmotionalState.CONNECTED: return "Connesso"
		EmotionalState.TRANSFORMED: return "Trasformato"
		_: return "Sconosciuto"

# ========================================
# API QUEST - GESTIONE
# ========================================

func start_quest(quest_id: String) -> bool:
	"""Avvia una nuova quest"""
	if active_quests.has(quest_id):
		print("🎯 Quest già attiva: %s" % quest_id)
		return false
	
	active_quests[quest_id] = {
		"id": quest_id,
		"started_at": Time.get_unix_time_from_system(),
		"progress": 0
	}
	
	quest_progress[quest_id] = {}
	quest_started.emit(quest_id)
	print("🎯 Quest avviata: %s" % quest_id)
	return true

func progress_quest(quest_id: String, stage_id: String) -> bool:
	"""Fa progredire una quest"""
	if not active_quests.has(quest_id):
		print("⚠️ Quest non attiva: %s" % quest_id)
		return false
	
	quest_progress[quest_id][stage_id] = true
	quest_progressed.emit(quest_id, stage_id)
	print("📈 Quest progredita: %s - %s" % [quest_id, stage_id])
	return true

func complete_quest(quest_id: String) -> bool:
	"""Completa una quest"""
	if not active_quests.has(quest_id):
		print("⚠️ Quest non attiva: %s" % quest_id)
		return false
	
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	quest_completed.emit(quest_id)
	print("✅ Quest completata: %s" % quest_id)
	return true

func is_quest_active(quest_id: String) -> bool:
	"""Verifica se una quest è attiva"""
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	"""Verifica se una quest è completata"""
	return quest_id in completed_quests

func _load_main_quest():
	"""Carica la quest principale"""
	var quest_file = "res://data/quests/main_quest_complete.json"
	var quest_data = CoreDataManager.load_json_file(quest_file)
	
	if quest_data and quest_data.has("main_quest"):
		var main_quest = quest_data.main_quest
		main_quest_id = main_quest.id
		main_quest_stages = main_quest.stages
		
		# Inizializza la quest principale se non è già attiva
		if not active_quests.has(main_quest_id):
			start_quest(main_quest_id)
		
		print("📖 Quest principale caricata: %s" % main_quest.get("title", "Senza titolo"))
	else:
		print("❌ Impossibile caricare la quest principale")

# ========================================
# API EVENTI - TRIGGERING
# ========================================

func try_trigger_event(biome: String) -> bool:
	"""Tenta di triggerare un evento in base al bioma"""
	if not biome_event_chances.has(biome):
		print("⚠️ Bioma non riconosciuto: %s" % biome)
		return false
	
	var chance = biome_event_chances[biome]
	var roll = randf()
	
	if roll <= chance:
		return _trigger_random_event(biome)
	
	return false

func trigger_specific_event(event_id: String) -> bool:
	"""Triggera un evento specifico"""
	var event_data = _get_event_data(event_id)
	if event_data.is_empty():
		print("❌ Evento non trovato: %s" % event_id)
		return false
	
	current_event = event_data
	current_event_id = event_id
	event_triggered.emit(event_data)
	print("⚡ Evento triggerato: %s" % event_id)
	return true

func resolve_event_choice(choice_index: int) -> Dictionary:
	"""Risolve una scelta dell'evento corrente"""
	if current_event.is_empty():
		print("❌ Nessun evento corrente da risolvere")
		return {}
	
	var choices = current_event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		print("❌ Indice scelta non valido: %d" % choice_index)
		return {}
	
	var choice = choices[choice_index]
	var result = _process_event_choice(choice)
	
	# Pulisci evento corrente
	current_event = {}
	current_event_id = ""
	
	return result

func _trigger_random_event(biome: String) -> bool:
	"""Triggera un evento casuale per il bioma"""
	var events_pool = _get_biome_events(biome)
	if events_pool.is_empty():
		return false
	
	var random_event = events_pool[randi() % events_pool.size()]
	return trigger_specific_event(random_event)

func _get_biome_events(biome: String) -> Array:
	"""Restituisce gli eventi disponibili per un bioma"""
	if biome_event_pools.has(biome):
		return biome_event_pools[biome]
	
	# Carica eventi per il bioma se non in cache
	var events = []
	for event_id in cached_events:
		var event_data = cached_events[event_id]
		var event_biomes = event_data.get("biomes", [])
		if biome in event_biomes:
			events.append(event_id)
	
	biome_event_pools[biome] = events
	return events

func _get_event_data(event_id: String) -> Dictionary:
	"""Restituisce i dati di un evento"""
	if cached_events.has(event_id):
		return cached_events[event_id]
	
	# Carica evento se non in cache
	var event_file = "res://data/events/%s.json" % event_id
	var event_data = CoreDataManager.load_json_file(event_file)
	
	if not event_data.is_empty():
		cached_events[event_id] = event_data
	
	return event_data

func _load_events_cache():
	"""Carica la cache degli eventi"""
	# Implementazione semplificata - carica eventi base
	print("📚 Cache eventi caricata")

func _process_event_choice(choice: Dictionary) -> Dictionary:
	"""Processa una scelta dell'evento"""
	var result = {
		"success": true,
		"narrative_text": choice.get("result_text", ""),
		"skill_check": null
	}
	
	# Processa skill check se presente
	if choice.has("skill_check"):
		var skill_check = choice.skill_check
		var check_result = PlayerSystemManager.skill_check(
			skill_check.get("stat", "forza"),
			skill_check.get("difficulty", 10),
			skill_check.get("modifier", 0)
		)
		
		result.skill_check = check_result
		skill_check_completed.emit(check_result)
		
		# Usa risultato appropriato basato su successo/fallimento
		if check_result.success and choice.has("success_result"):
			result.narrative_text = choice.success_result.get("text", "")
			_apply_consequences(choice.success_result.get("consequences", {}))
		elif not check_result.success and choice.has("failure_result"):
			result.narrative_text = choice.failure_result.get("text", "")
			_apply_consequences(choice.failure_result.get("consequences", {}))
	else:
		# Applica conseguenze dirette
		_apply_consequences(choice.get("consequences", {}))
	
	event_consequences_applied.emit(result.narrative_text)
	return result

func _apply_consequences(consequences: Dictionary):
	"""Applica le conseguenze di un evento"""
	# HP, food, water changes
	if consequences.has("hp"):
		resource_change_requested.emit("hp", consequences.hp)
	if consequences.has("food"):
		resource_change_requested.emit("food", consequences.food)
	if consequences.has("water"):
		resource_change_requested.emit("water", consequences.water)
	
	# Items gained/lost
	if consequences.has("items_gained") or consequences.has("items_lost"):
		item_transaction_requested.emit(consequences)
	
	# Experience gain
	if consequences.has("experience"):
		experience_gain_requested.emit(consequences.experience, "Evento")
	
	# Narrative progression
	if consequences.has("understanding"):
		increase_understanding(consequences.understanding, "Evento")
	if consequences.has("wisdom"):
		gain_wisdom(consequences.wisdom, "Evento")

# ========================================
# HANDLER SEGNALI
# ========================================

func _on_item_transaction_requested(transaction: Dictionary):
	"""Gestisce richieste di transazione oggetti"""
	PlayerSystemManager.apply_item_transaction(transaction)

func _on_resource_change_requested(resource_type: String, amount: int):
	"""Gestisce richieste di cambio risorse"""
	match resource_type:
		"hp":
			PlayerSystemManager.modify_hp(amount)
		"food":
			PlayerSystemManager.modify_food(amount)
		"water":
			PlayerSystemManager.modify_water(amount)

func _on_experience_gain_requested(amount: int, reason: String):
	"""Gestisce richieste di guadagno esperienza"""
	PlayerSystemManager.add_experience(amount, reason)

# ========================================
# API QUERY
# ========================================

func get_emotional_state() -> EmotionalState:
	"""Restituisce lo stato emotivo corrente"""
	return current_emotional_state

func get_understanding_level() -> int:
	"""Restituisce il livello di comprensione"""
	return understanding_level

func get_character_empathy(character: String) -> int:
	"""Restituisce il livello di empatia verso un personaggio"""
	return character_empathy.get(character, 0)

func get_memory_strength(memory: String) -> int:
	"""Restituisce la forza di un ricordo"""
	return memory_strength.get(memory, 0)

func get_total_wisdom() -> int:
	"""Restituisce la saggezza totale"""
	return total_wisdom

func get_active_quests() -> Dictionary:
	"""Restituisce le quest attive"""
	return active_quests.duplicate()

func get_completed_quests() -> Array:
	"""Restituisce le quest completate"""
	return completed_quests.duplicate()

# ========================================
# DEBUG
# ========================================

func debug_print_narrative_status():
	"""Debug: stampa stato narrativo"""
	print("=== NarrativeSystemManager Debug ===")
	print("Stato emotivo: ", _emotional_state_to_string(current_emotional_state))
	print("Comprensione: ", understanding_level)
	print("Saggezza totale: ", total_wisdom)
	print("Quest attive: ", active_quests.size())
	print("Quest completate: ", completed_quests.size())
	print("Empatia: ", character_empathy)
	print("Ricordi: ", memory_strength)