extends Node

## QuestManager Singleton - The Safe Place v0.4.1
##
## Gestisce il sistema di quest strutturato con frammenti, riflessioni e milestone emotivi
## Implementa il sistema narrativo profondo del GDD React adattato per Godot
##
## Architettura: Singleton (Autoload) per accesso globale al sistema quest

# ========================================
# ENUM E COSTANTI
# ========================================

enum QuestStage {
	INACTIVE = 0,
	ACTIVE = 1,
	COMPLETED = 2,
	FAILED = 3
}

enum FragmentType {
	NARRATIVE = 0,    # Frammento narrativo principale
	REFLECTION = 1,   # Riflessione personale
	MILESTONE = 2     # Milestone emotivo
}

# ========================================
# SEGNALI PUBBLICI
# ========================================

signal quest_stage_changed(quest_id: String, new_stage: QuestStage)
signal fragment_unlocked(fragment_id: String, fragment_type: FragmentType)
signal emotional_milestone_reached(milestone_id: String)
signal quest_completed(quest_id: String)

# ========================================
# VARIABILI STATO QUEST
# ========================================

## Database quest caricato
var quest_database: Dictionary = {}

## Stato corrente delle quest
var quest_states: Dictionary = {}  # quest_id -> QuestStage

## Frammenti sbloccati
var unlocked_fragments: Array[String] = []

## Riflessioni disponibili
var available_reflections: Array[String] = []

## Milestone emotivi raggiunti
var reached_milestones: Array[String] = []

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("📜 QuestManager: Inizializzazione sistema quest...")
	_load_quest_database()
	_initialize_quest_states()
	print("✅ QuestManager: Sistema quest pronto")

## Carica il database quest dal file JSON
func _load_quest_database() -> void:
	var quest_file = "res://data/quests/main_quest.json"
	quest_database = DataManager.load_json_file(quest_file)

	if quest_database.is_empty():
		push_error("QuestManager: Impossibile caricare database quest")
		return

	print("📜 QuestManager: Caricato database quest con %d quest" % quest_database.size())

## Inizializza lo stato di tutte le quest
func _initialize_quest_states() -> void:
	if not quest_database.has("MAIN_QUEST"):
		push_error("QuestManager: Database quest non contiene MAIN_QUEST")
		return

	var main_quest = quest_database["MAIN_QUEST"]
	for stage_data in main_quest:
		var quest_id = stage_data.get("id", "")
		if quest_id != "":
			quest_states[quest_id] = QuestStage.INACTIVE

	# Attiva la prima quest per default
	if quest_states.size() > 0:
		var first_quest = quest_states.keys()[0]
		quest_states[first_quest] = QuestStage.ACTIVE
		print("📜 QuestManager: Attivata quest iniziale: %s" % first_quest)

# ========================================
# API GESTIONE QUEST
# ========================================

## Verifica se una quest è attiva
func is_quest_active(quest_id: String) -> bool:
	return quest_states.get(quest_id, QuestStage.INACTIVE) == QuestStage.ACTIVE

## Verifica se una quest è completata
func is_quest_completed(quest_id: String) -> bool:
	return quest_states.get(quest_id, QuestStage.INACTIVE) == QuestStage.COMPLETED

## Ottiene lo stato corrente di una quest
func get_quest_state(quest_id: String) -> QuestStage:
	return quest_states.get(quest_id, QuestStage.INACTIVE)

## Ottiene i dati di una quest specifica
func get_quest_data(quest_id: String) -> Dictionary:
	if not quest_database.has("MAIN_QUEST"):
		return {}

	for stage_data in quest_database["MAIN_QUEST"]:
		if stage_data.get("id", "") == quest_id:
			return stage_data

	return {}

## Avanza una quest allo stage successivo
func advance_quest(quest_id: String) -> bool:
	var current_state = get_quest_state(quest_id)
	if current_state != QuestStage.ACTIVE:
		print("⚠️ QuestManager: Impossibile avanzare quest %s (stato: %d)" % [quest_id, current_state])
		return false

	quest_states[quest_id] = QuestStage.COMPLETED
	quest_stage_changed.emit(quest_id, QuestStage.COMPLETED)
	quest_completed.emit(quest_id)

	print("📜 QuestManager: Quest completata: %s" % quest_id)
	return true

# ========================================
# SISTEMA FRAMMENTI NARRATIVI
# ========================================

## Sblocca un frammento narrativo
func unlock_fragment(fragment_id: String, fragment_type: FragmentType = FragmentType.NARRATIVE) -> void:
	if fragment_id in unlocked_fragments:
		return  # Già sbloccato

	unlocked_fragments.append(fragment_id)
	fragment_unlocked.emit(fragment_id, fragment_type)

	print("📜 QuestManager: Frammento sbloccato: %s (tipo: %d)" % [fragment_id, fragment_type])

## Verifica se un frammento è sbloccato
func is_fragment_unlocked(fragment_id: String) -> bool:
	return fragment_id in unlocked_fragments

## Ottiene tutti i frammenti sbloccati
func get_unlocked_fragments() -> Array[String]:
	return unlocked_fragments.duplicate()

# ========================================
# SISTEMA RIFLESSIONI
# ========================================

## Aggiunge una riflessione disponibile
func add_available_reflection(reflection_id: String) -> void:
	if reflection_id in available_reflections:
		return  # Già disponibile

	available_reflections.append(reflection_id)
	print("📜 QuestManager: Riflessione disponibile: %s" % reflection_id)

## Rimuove una riflessione (dopo che è stata letta)
func remove_reflection(reflection_id: String) -> void:
	available_reflections.erase(reflection_id)
	print("📜 QuestManager: Riflessione rimossa: %s" % reflection_id)

## Ottiene le riflessioni disponibili
func get_available_reflections() -> Array[String]:
	return available_reflections.duplicate()

# ========================================
# SISTEMA MILESTONE EMOTIVI
# ========================================

## Raggiunge un milestone emotivo
func reach_emotional_milestone(milestone_id: String) -> void:
	if milestone_id in reached_milestones:
		return  # Già raggiunto

	reached_milestones.append(milestone_id)
	emotional_milestone_reached.emit(milestone_id)

	print("💭 QuestManager: Milestone emotivo raggiunto: %s" % milestone_id)

## Verifica se un milestone è stato raggiunto
func is_milestone_reached(milestone_id: String) -> bool:
	return milestone_id in reached_milestones

## Ottiene tutti i milestone raggiunti
func get_reached_milestones() -> Array[String]:
	return reached_milestones.duplicate()

# ========================================
# SISTEMA TRIGGER QUEST
# ========================================

## Verifica i trigger di quest basati sul progresso del giocatore
func check_quest_triggers() -> void:
	var player_progress = PlayerManager.get_progression_data()
	var current_level = player_progress.get("current_level", 1)

	# Trigger basati su livello personaggio
	_check_level_based_triggers(current_level)

	# Trigger basati su giorni sopravvissuti
	var survival_days = TimeManager.get_current_day()
	_check_survival_based_triggers(survival_days)

	# Trigger basati su bioma corrente (placeholder - da implementare)
	var current_biome = "pianure"  # Placeholder
	_check_biome_based_triggers(current_biome)

## Controlla trigger basati sul livello del personaggio
func _check_level_based_triggers(current_level: int) -> void:
	match current_level:
		2:
			if not is_quest_active("mq_02_water"):
				_activate_quest("mq_02_water")
		3:
			if not is_quest_active("mq_03_blood"):
				_activate_quest("mq_03_blood")

## Controlla trigger basati sui giorni di sopravvivenza
func _check_survival_based_triggers(survival_days: int) -> void:
	if survival_days >= 2 and not is_quest_active("mq_04_darkness"):
		_activate_quest("mq_04_darkness")
	elif survival_days >= 7 and not is_quest_active("mq_09_name"):
		_activate_quest("mq_09_name")

## Controlla trigger basati sul bioma corrente
func _check_biome_based_triggers(current_biome: String) -> void:
	if current_biome == "Ristoro" and not is_quest_active("mq_05_question"):
		_activate_quest("mq_05_question")

## Attiva una quest specifica
func _activate_quest(quest_id: String) -> void:
	if quest_states.has(quest_id):
		quest_states[quest_id] = QuestStage.ACTIVE
		quest_stage_changed.emit(quest_id, QuestStage.ACTIVE)
		print("📜 QuestManager: Quest attivata: %s" % quest_id)

# ========================================
# API DEBUG E TESTING
# ========================================

## Forza l'attivazione di una quest (per debug)
func debug_activate_quest(quest_id: String) -> void:
	_activate_quest(quest_id)
	print("🔧 DEBUG: Quest forzatamente attivata: %s" % quest_id)

## Ottieni lo stato completo del sistema quest
func get_quest_system_state() -> Dictionary:
	return {
		"quest_states": quest_states.duplicate(),
		"unlocked_fragments": unlocked_fragments.duplicate(),
		"available_reflections": available_reflections.duplicate(),
		"reached_milestones": reached_milestones.duplicate()
	}

## Reset completo del sistema quest (per testing)
func debug_reset_quest_system() -> void:
	quest_states.clear()
	unlocked_fragments.clear()
	available_reflections.clear()
	reached_milestones.clear()
	_initialize_quest_states()
	print("🔧 DEBUG: Sistema quest resettato")