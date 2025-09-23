extends Node

## NarrativeManager Singleton - The Safe Place v0.4.1
##
## Gestisce il sistema di progressione emotiva e narrativa profonda
## Implementa il sistema di comprensione, empatia e ricordi del GDD React
##
## Architettura: Singleton (Autoload) per stato narrativo globale

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
# SEGNALI PUBBLICI
# ========================================

signal emotional_state_changed(new_state: EmotionalState, old_state: EmotionalState)
signal understanding_level_changed(new_level: int, old_level: int)
signal empathy_changed(character: String, new_level: int, old_level: int)
signal memory_strength_changed(memory: String, new_level: int, old_level: int)
signal wisdom_gained(amount: int, reason: String)

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

func _ready() -> void:
	print("💭 NarrativeManager: Inizializzazione sistema narrativo...")
	_initialize_emotional_state()
	print("✅ NarrativeManager: Sistema narrativo pronto")

## Inizializza lo stato emotivo di default
func _initialize_emotional_state() -> void:
	# Stato iniziale: freddo e pragmatico
	current_emotional_state = EmotionalState.COLD
	understanding_level = 0
	total_wisdom = 0

	print("💭 NarrativeManager: Stato emotivo inizializzato - Freddo e pragmatico")

# ========================================
# API PROGRESSIONE EMOTIVA
# ========================================

## Aumenta il livello di comprensione
func increase_understanding(amount: int, reason: String = "") -> void:
	var old_level = understanding_level
	understanding_level = clamp(understanding_level + amount, 0, 100)

	if understanding_level != old_level:
		understanding_level_changed.emit(understanding_level, old_level)
		_check_emotional_state_transition()
		print("💭 Comprehensione aumentata: %d → %d (%s)" % [old_level, understanding_level, reason])

## Aumenta empatia per un personaggio
func increase_empathy(character: String, amount: int, reason: String = "") -> void:
	if not character_empathy.has(character):
		push_error("NarrativeManager: Personaggio sconosciuto: %s" % character)
		return

	var old_level = character_empathy[character]
	var max_empathy = EMPATHY_THRESHOLDS[character]["max"]
	character_empathy[character] = clamp(character_empathy[character] + amount, 0, max_empathy)

	if character_empathy[character] != old_level:
		empathy_changed.emit(character, character_empathy[character], old_level)
		print("💭 Empatia %s aumentata: %d → %d (%s)" % [character, old_level, character_empathy[character], reason])

## Aumenta forza di un ricordo
func increase_memory_strength(memory: String, amount: int, reason: String = "") -> void:
	if not memory_strength.has(memory):
		push_error("NarrativeManager: Ricordo sconosciuto: %s" % memory)
		return

	var old_level = memory_strength[memory]
	memory_strength[memory] = clamp(memory_strength[memory] + amount, 0, 100)

	if memory_strength[memory] != old_level:
		memory_strength_changed.emit(memory, memory_strength[memory], old_level)
		print("💭 Forza ricordo '%s' aumentata: %d → %d (%s)" % [memory, old_level, memory_strength[memory], reason])

## Aggiunge saggezza
func add_wisdom(amount: int, reason: String = "") -> void:
	total_wisdom += amount
	wisdom_gained.emit(amount, reason)
	print("🧠 Saggezza guadagnata: +%d (totale: %d) - %s" % [amount, total_wisdom, reason])

# ========================================
# GESTIONE STATO EMOTIVO
# ========================================

## Ottiene lo stato emotivo corrente
func get_emotional_state() -> EmotionalState:
	return current_emotional_state

## Ottiene la descrizione dello stato emotivo corrente
func get_emotional_state_description() -> String:
	match current_emotional_state:
		EmotionalState.COLD:
			return "Freddo e pragmatico. Le emozioni sono un lusso che non puoi permetterti."
		EmotionalState.GUARDED:
			return "Diffidente ma curioso. Inizi a sentire che c'è qualcosa di più della sopravvivenza."
		EmotionalState.OPEN:
			return "Aperto alle emozioni. I ricordi iniziano a riaffiorare."
		EmotionalState.CONNECTED:
			return "Connesso ai ricordi. Cominci a capire il dolore di tuo padre."
		EmotionalState.TRANSFORMED:
			return "Trasformato dall'esperienza. Sei cambiato per sempre."
		_:
			return "Stato emotivo sconosciuto"

## Controlla se deve cambiare stato emotivo
func _check_emotional_state_transition() -> void:
	var new_state = _calculate_emotional_state()
	if new_state != current_emotional_state:
		var old_state = current_emotional_state
		current_emotional_state = new_state
		emotional_state_changed.emit(new_state, old_state)
		print("💭 Stato emotivo cambiato: %s → %s" % [
			_get_emotional_state_name(old_state),
			_get_emotional_state_name(new_state)
		])

## Calcola lo stato emotivo basato sui livelli attuali
func _calculate_emotional_state() -> EmotionalState:
	if understanding_level >= UNDERSTANDING_THRESHOLDS[EmotionalState.TRANSFORMED]:
		return EmotionalState.TRANSFORMED
	elif understanding_level >= UNDERSTANDING_THRESHOLDS[EmotionalState.CONNECTED]:
		return EmotionalState.CONNECTED
	elif understanding_level >= UNDERSTANDING_THRESHOLDS[EmotionalState.OPEN]:
		return EmotionalState.OPEN
	elif understanding_level >= UNDERSTANDING_THRESHOLDS[EmotionalState.GUARDED]:
		return EmotionalState.GUARDED
	else:
		return EmotionalState.COLD

## Ottiene il nome di uno stato emotivo
func _get_emotional_state_name(state: EmotionalState) -> String:
	match state:
		EmotionalState.COLD: return "Freddo"
		EmotionalState.GUARDED: return "Diffidente"
		EmotionalState.OPEN: return "Aperto"
		EmotionalState.CONNECTED: return "Connesso"
		EmotionalState.TRANSFORMED: return "Trasformato"
		_: return "Sconosciuto"

# ========================================
# API VALORI EMOTIVI
# ========================================

## Ottiene il livello di comprensione corrente
func get_understanding_level() -> int:
	return understanding_level

## Ottiene il livello di empatia per un personaggio
func get_empathy_level(character: String) -> int:
	return character_empathy.get(character, 0)

## Ottiene la forza di un ricordo
func get_memory_strength(memory: String) -> int:
	return memory_strength.get(memory, 0)

## Ottiene la saggezza totale
func get_total_wisdom() -> int:
	return total_wisdom

## Ottiene tutti i valori emotivi
func get_emotional_state_snapshot() -> Dictionary:
	return {
		"emotional_state": current_emotional_state,
		"understanding_level": understanding_level,
		"character_empathy": character_empathy.duplicate(),
		"memory_strength": memory_strength.duplicate(),
		"total_wisdom": total_wisdom
	}

# ========================================
# SISTEMA EVENTI NARRATIVI
# ========================================

## Triggera un evento narrativo basato sul contesto
func trigger_narrative_event(event_type: String, context: Dictionary = {}) -> Dictionary:
	var event_result = {}

	match event_type:
		"atmosphere_message":
			event_result = _generate_atmosphere_message(context)
		"reflection_trigger":
			event_result = _trigger_reflection(context)
		"emotional_insight":
			event_result = _generate_emotional_insight(context)
		"memory_flashback":
			event_result = _trigger_memory_flashback(context)

	return event_result

## Genera un messaggio atmosfera basato sullo stato emotivo
func _generate_atmosphere_message(_context: Dictionary) -> Dictionary:
	var messages = []

	match current_emotional_state:
		EmotionalState.COLD:
			messages = [
				"Il mondo è silenzioso. Solo la sopravvivenza conta.",
				"Ogni passo è calcolato. Le emozioni sono un rischio.",
				"Il pragmatismo è la tua unica guida."
			]
		EmotionalState.GUARDED:
			messages = [
				"C'è qualcosa nell'aria... un ricordo che sfugge.",
				"Perché questo posto ti sembra familiare?",
				"Le ombre sembrano sussurrare segreti."
			]
		EmotionalState.OPEN:
			messages = [
				"I ricordi iniziano a tornare. Dolci e dolorosi.",
				"Tuo padre... cosa ti ha nascosto?",
				"La verità è vicina, lo senti."
			]
		EmotionalState.CONNECTED:
			messages = [
				"Capisci ora. Il dolore di papà era reale.",
				"Le sue lezioni erano per proteggerti.",
				"Il viaggio ti ha cambiato."
			]
		EmotionalState.TRANSFORMED:
			messages = [
				"Sei diverso ora. Più saggio, più compassionevole.",
				"Il viaggio non finisce qui. Continua dentro di te.",
				"Hai trovato ciò che cercavi... e anche di più."
			]

	var selected_message = messages[randi() % messages.size()]
	return {
		"type": "atmosphere",
		"message": selected_message,
		"emotional_context": current_emotional_state
	}

## Triggera una riflessione basata sul contesto
func _trigger_reflection(context: Dictionary) -> Dictionary:
	var reflection_type = context.get("type", "general")
	var reflection = {}

	match reflection_type:
		"elian_empathy":
			reflection = {
				"text": "Papà aveva i suoi motivi per essere così duro. Ora lo capisci.",
				"emotional_impact": { "elian_empathy": 5, "understanding": 3 }
			}
		"lena_memory":
			reflection = {
				"text": "Mamma... i suoi occhi brillavano quando parlava di questo posto.",
				"emotional_impact": { "lena_empathy": 5, "understanding": 2 }
			}
		"self_realization":
			reflection = {
				"text": "Chi sei veramente? Il sopravvissuto pragmatico o qualcosa di più?",
				"emotional_impact": { "ultimo_empathy": 5, "understanding": 4 }
			}

	return {
		"type": "reflection",
		"reflection": reflection
	}

## Genera un insight emotivo
func _generate_emotional_insight(_context: Dictionary) -> Dictionary:
	var insight = "Un pensiero profondo emerge dalla tua esperienza..."

	# Insight basato sui ricordi più forti
	var strongest_memory = _get_strongest_memory()
	match strongest_memory:
		"silence":
			insight = "Il silenzio della fine del mondo... era lo stesso silenzio nei suoi occhi."
		"water_lesson":
			insight = "L'acqua che tuo padre ti insegnò a purificare... era pura come il suo amore."
		"blood_taste":
			insight = "Il sapore del sangue di quella notte... era il prezzo della tua sopravvivenza."

	return {
		"type": "insight",
		"message": insight,
		"trigger_memory": strongest_memory
	}

## Triggera un flashback di memoria
func _trigger_memory_flashback(context: Dictionary) -> Dictionary:
	var memory_type = context.get("memory", "")
	var flashback = {}

	if memory_strength.has(memory_type):
		var strength = memory_strength[memory_type]
		if strength > 50:
			flashback = {
				"memory": memory_type,
				"vividness": "crystal_clear",
				"emotional_impact": 10
			}
		elif strength > 25:
			flashback = {
				"memory": memory_type,
				"vividness": "clear",
				"emotional_impact": 5
			}
		else:
			flashback = {
				"memory": memory_type,
				"vividness": "fuzzy",
				"emotional_impact": 2
			}

	return {
		"type": "flashback",
		"flashback": flashback
	}

## Trova il ricordo più forte
func _get_strongest_memory() -> String:
	var strongest = ""
	var max_strength = 0

	for memory in memory_strength:
		if memory_strength[memory] > max_strength:
			max_strength = memory_strength[memory]
			strongest = memory

	return strongest

# ========================================
# API SALVATAGGIO/CARICAMENTO
# ========================================

## Ottiene i dati da salvare
func get_save_data() -> Dictionary:
	return {
		"understanding_level": understanding_level,
		"character_empathy": character_empathy.duplicate(),
		"memory_strength": memory_strength.duplicate(),
		"total_wisdom": total_wisdom,
		"current_emotional_state": current_emotional_state
	}

## Carica i dati salvati
func load_save_data(save_data: Dictionary) -> void:
	understanding_level = save_data.get("understanding_level", 0)
	character_empathy = save_data.get("character_empathy", {})
	memory_strength = save_data.get("memory_strength", {})
	total_wisdom = save_data.get("total_wisdom", 0)
	current_emotional_state = save_data.get("current_emotional_state", EmotionalState.COLD)

	print("💭 NarrativeManager: Stato emotivo caricato dal salvataggio")

# ========================================
# API DEBUG E TESTING
# ========================================

## Forza uno stato emotivo (per debug)
func debug_set_emotional_state(new_state: EmotionalState) -> void:
	var old_state = current_emotional_state
	current_emotional_state = new_state
	emotional_state_changed.emit(new_state, old_state)
	print("🔧 DEBUG: Stato emotivo forzato: %s" % _get_emotional_state_name(new_state))

## Aggiunge valori di debug (per testing)
func debug_add_emotional_values(amount: int = 10) -> void:
	increase_understanding(amount, "debug")
	for character in character_empathy:
		increase_empathy(character, amount, "debug")
	for memory in memory_strength:
		increase_memory_strength(memory, amount, "debug")
	add_wisdom(amount, "debug")
	print("🔧 DEBUG: Aggiunti %d punti a tutti i valori emotivi" % amount)

## Reset completo dello stato emotivo (per testing)
func debug_reset_emotional_state() -> void:
	understanding_level = 0
	character_empathy = { "elian": 0, "lena": 0, "ultimo": 0 }
	memory_strength = {
		"silence": 0, "water_lesson": 0, "blood_taste": 0, "darkness_lesson": 0,
		"burden": 0, "angels": 0, "confession": 0, "truth": 0
	}
	total_wisdom = 0
	current_emotional_state = EmotionalState.COLD
	print("🔧 DEBUG: Stato emotivo resettato")