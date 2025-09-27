# QuestManager.gd
# Singleton per la gestione delle quest principali e secondarie
# Gestisce progressione, obiettivi e ricompense delle quest

extends Node

# Segnali per comunicazione con altri sistemi
signal quest_started(quest_id: String)
signal quest_progressed(quest_id: String, stage_id: String)
signal quest_completed(quest_id: String)
signal quest_stage_unlocked(stage_id: String)

# Riferimenti ai manager
@onready var player_manager: PlayerManager
@onready var data_manager: DataManager

# Stato delle quest
var active_quests: Dictionary = {}
var completed_quests: Array = []
var quest_progress: Dictionary = {}

# Quest principale
var main_quest_id: String = "main_quest_ultimate_surviver"
var main_quest_stages: Array = []

func _ready():
	print("QuestManager pronto.")

# Inizializza il sistema quest
func initialize_quests():
	print("[QuestManager] Inizializzazione sistema quest...")

	# Ottieni riferimenti ai manager
	player_manager = get_node("/root/PlayerManager")
	data_manager = get_node("/root/DataManager")

	if not player_manager:
		print("[QuestManager] ERRORE: PlayerManager non trovato!")
		return

	if not data_manager:
		print("[QuestManager] ERRORE: DataManager non trovato!")
		return

	# Carica la quest principale
	load_main_quest()

	print("[QuestManager] Sistema quest inizializzato")

# Carica la quest principale dal file JSON
func load_main_quest():
	var quest_file = "res://data/quests/main_quest_complete.json"
	var quest_data = data_manager.load_json_file(quest_file)

	if quest_data and quest_data.has("main_quest"):
		var main_quest = quest_data.main_quest
		main_quest_id = main_quest.id
		main_quest_stages = main_quest.stages

		# Inizializza la quest principale se non è già attiva
		if not active_quests.has(main_quest_id):
			start_quest(main_quest_id)

		print("[QuestManager] Quest principale caricata: ", main_quest.title)
	else:
		print("[QuestManager] ERRORE: Impossibile caricare la quest principale")

# Avvia una nuova quest
func start_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id):
		print("[QuestManager] Quest già attiva: ", quest_id)
		return false

	active_quests[quest_id] = {
		"id": quest_id,
		"started_at": Time.get_unix_time_from_system(),
		"progress": 0
	}

	quest_progress[quest_id] = {}

	quest_started.emit(quest_id)
	print("[QuestManager] Quest avviata: ", quest_id)
	return true

# Controlla se una condizione di trigger è soddisfatta
func check_trigger_condition(condition_str: String) -> bool:
	var parts = condition_str.split(" ")
	if parts.size() != 3:
		# Gestisce condizioni semplici come "time_of_day == night"
		parts = condition_str.split("==")
		if parts.size() == 2:
			var variable = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			match variable:
				"time_of_day":
					return (value == "night" and TimeManager.is_night()) or (value == "day" and not TimeManager.is_night())
		return false

	var variable = parts[0]
	var op = parts[1]
	var value = parts[2].to_float()

	var current_value: float
	match variable:
		"exploration_time":
			current_value = TimeManager.get_total_minutes_survived()
		"thirst_level":
			current_value = 100.0 - (float(player_manager.water) / player_manager.max_water * 100.0)
		"hp_percentage":
			current_value = float(player_manager.hp) / player_manager.max_hp * 100.0
		_:
			# Gestisce condizioni speciali non numeriche
			if condition_str == "found_old_map": return has_item("old_map")
			if condition_str == "deep_reflection": return randf() < 0.1
			if condition_str == "crossroads_decision": return randf() < 0.05
			return false

	match op:
		">": return current_value > value
		"<": return current_value < value
		">=": return current_value >= value
		"<=": return current_value <= value
		"==": return is_equal_approx(current_value, value)
	
	return false

# Calcola il tempo di esplorazione (in minuti)
func get_exploration_time() -> int:
	return TimeManager.get_total_minutes_survived()

# Verifica se il giocatore sta riposando
func is_player_resting() -> bool:
	# Questa sarebbe collegata al sistema di riposo
	return randf() < 0.3  # Placeholder

# Verifica se il giocatore è vicino a una zona radioattiva
func is_near_radiation() -> bool:
	# Questa sarebbe collegata al sistema di biomi
	return randf() < 0.2  # Placeholder

# Calcola la percentuale di peso dell'inventario
func get_inventory_weight_percentage() -> float:
	return player_manager.get_inventory_weight() / 25.0 * 100.0 # Assumendo 25kg come max

# Verifica se il giocatore ha un item specifico
func has_item(item_id: String) -> bool:
	return player_manager.has_item(item_id)

# Verifica se il giocatore è vicino al Safe Place
func is_near_safe_place() -> bool:
	# Questa sarebbe calcolata dalla posizione del giocatore
	return randf() < 0.1  # Placeholder

# Verifica se il giocatore ha raggiunto il Safe Place
func has_reached_safe_place() -> bool:
	# Questa sarebbe verificata dalla posizione finale
	return quest_progress.get(main_quest_id, {}).get("reached_safe_place", false)

# Prova ad attivare un evento di quest
func try_trigger_quest_event(stage_id: String) -> bool:
	if not active_quests.has(main_quest_id):
		return false

	# Trova lo stage corrispondente
	var stage_data = null
	for stage in main_quest_stages:
		if stage.id == stage_id:
			stage_data = stage
			break

	if not stage_data:
		return false

	# Verifica la condizione di trigger
	var trigger_condition = stage_data.get("trigger_condition", "")
	if trigger_condition and not check_trigger_condition(trigger_condition):
		return false

	# L'evento può essere triggerato
	trigger_quest_stage(stage_id, stage_data)
	return true

# Attiva uno stage specifico della quest
func trigger_quest_stage(stage_id: String, stage_data: Dictionary):
	print("[QuestManager] Attivazione stage quest: ", stage_id)

	# Se lo stage ha un evento associato, triggeralo
	if stage_data.has("event_id"):
		EventManager.trigger_specific_event(stage_data.event_id)
	else:
		# Se non c'è un evento, emetti solo il log narrativo
		player_manager.narrative_log_generated.emit(stage_data.get("narrative_text", "Qualcosa è cambiato..."))

	# Qui verrebbe mostrato l'evento narrativo al giocatore
	# Per ora, applichiamo automaticamente il progresso
	update_quest_progress(main_quest_id, stage_id, "completed")

# Aggiorna il progresso di una quest
func update_quest_progress(quest_id: String, stage_id: String, progress_type: String):
	if not quest_progress.has(quest_id):
		quest_progress[quest_id] = {}

	quest_progress[quest_id][stage_id] = progress_type

	quest_progressed.emit(quest_id, stage_id)

	# Verifica se la quest è completata
	check_quest_completion(quest_id)

	print("[QuestManager] Progresso aggiornato: ", quest_id, " - ", stage_id, " - ", progress_type)

# Verifica se una quest è stata completata
func check_quest_completion(quest_id: String):
	if quest_id == main_quest_id:
		var final_stage = "mq_12_truth"
		if quest_progress.get(quest_id, {}).get(final_stage) == "completed":
			complete_quest(quest_id)

# Completa una quest
func complete_quest(quest_id: String):
	if completed_quests.has(quest_id):
		return

	completed_quests.append(quest_id)
	active_quests.erase(quest_id)

	quest_completed.emit(quest_id)

	print("[QuestManager] Quest completata: ", quest_id)

	# Ricompense per il completamento della quest principale
	if quest_id == main_quest_id:
		grant_main_quest_rewards()

# Concede le ricompense per il completamento della quest principale
func grant_main_quest_rewards():
	print("[QuestManager] Concessione ricompense quest principale")

	# Ricompense narrative e materiali
	player_manager.add_item("elian_letter", 1)
	player_manager.add_item("safe_place_key", 1)

	# Aumento permanente delle statistiche
	player_manager.modify_stat("carisma", 2)
	player_manager.modify_stat("intelligenza", 1)

	# Messaggio narrativo finale
	player_manager.narrative_log_generated.emit("[color=cyan]Hai completato il tuo viaggio. Ora conosci la verità. Il mondo continua... e anche tu.[/color]")

# Ottieni informazioni su una quest
func get_quest_info(quest_id: String) -> Dictionary:
	return {
		"id": quest_id,
		"active": active_quests.has(quest_id),
		"completed": completed_quests.has(quest_id),
		"progress": quest_progress.get(quest_id, {})
	}

# Ottieni il progresso della quest principale
func get_main_quest_progress() -> Dictionary:
	return get_quest_info(main_quest_id)

# Debug: mostra lo stato delle quest
func print_quest_status():
	print("\n=== STATO QUEST ===")
	print("Quest attive: ", active_quests.keys())
	print("Quest completate: ", completed_quests)
	print("Progresso quest principale: ", quest_progress.get(main_quest_id, {}))
	print("===================\n")