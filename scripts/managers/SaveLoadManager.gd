extends Node

## SaveLoadManager Singleton - The Safe Place v0.4.1
##
## Gestisce il sistema di salvataggio e caricamento del gioco
## Implementa il sistema persistenza del GDD React adattato per Godot
##
## Architettura: Singleton (Autoload) per gestione globale save/load

# ========================================
# COSTANTI
# ========================================

const SAVE_PREFIX = "savegame_"
const MAX_SAVES = 10
const SAVE_VERSION = "0.4.1"

# ========================================
# SEGNALI PUBBLICI
# ========================================

signal save_completed(save_id: String)
signal load_completed(save_id: String)
signal save_failed(save_id: String, error: String)
signal load_failed(save_id: String, error: String)

# ========================================
# VARIABILI STATO
# ========================================

## Lista dei salvataggi disponibili
var available_saves: Array[Dictionary] = []

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("💾 SaveLoadManager: Inizializzazione sistema salvataggio...")
	_refresh_save_list()
	print("✅ SaveLoadManager: Sistema salvataggio pronto")

# ========================================
# API SALVATAGGIO
# ========================================

## Salva il gioco corrente
func save_game(save_name: String = "") -> String:
	var save_id = _generate_save_id()

	# Raccogli tutti i dati di gioco
	var game_state = _capture_game_state()

	# Crea metadata
	var metadata = _create_save_metadata(save_name, game_state)

	# Crea oggetto salvataggio completo
	var save_data = {
		"id": save_id,
		"timestamp": Time.get_unix_time_from_system(),
		"version": SAVE_VERSION,
		"metadata": metadata,
		"game_state": game_state
	}

	# Salva su disco
	var success = _save_to_file(save_id, save_data)

	if success:
		_refresh_save_list()
		save_completed.emit(save_id)
		print("💾 Salvataggio completato: %s" % save_id)
		return save_id
	else:
		var error_msg = "Errore scrittura file"
		save_failed.emit(save_id, error_msg)
		print("❌ Salvataggio fallito: %s - %s" % [save_id, error_msg])
		return ""

## Carica un salvataggio
func load_game(save_id: String) -> bool:
	# Trova il salvataggio
	var save_data = _load_from_file(save_id)
	if save_data.is_empty():
		var error_msg = "File salvataggio non trovato"
		load_failed.emit(save_id, error_msg)
		print("❌ Caricamento fallito: %s - %s" % [save_id, error_msg])
		return false

	# Verifica versione compatibilità
	if not _is_save_compatible(save_data):
		var error_msg = "Versione salvataggio incompatibile"
		load_failed.emit(save_id, error_msg)
		print("❌ Caricamento fallito: %s - %s" % [save_id, error_msg])
		return false

	# Ripristina stato di gioco
	var success = _restore_game_state(save_data.game_state)

	if success:
		load_completed.emit(save_id)
		print("💾 Caricamento completato: %s" % save_id)
		return true
	else:
		var error_msg = "Errore ripristino stato"
		load_failed.emit(save_id, error_msg)
		print("❌ Caricamento fallito: %s - %s" % [save_id, error_msg])
		return false

## Elimina un salvataggio
func delete_save(save_id: String) -> bool:
	var file_path = _get_save_file_path(save_id)
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		file.close()

		# Elimina file
		var dir = DirAccess.open("user://")
		if dir.file_exists(file_path):
			var success = dir.remove(file_path)
			if success:
				_refresh_save_list()
				print("🗑️ Salvataggio eliminato: %s" % save_id)
				return true
			else:
				print("❌ Errore eliminazione file: %s" % save_id)
				return false
		else:
			print("⚠️ File salvataggio non trovato: %s" % save_id)
			return false
	else:
		print("⚠️ Salvataggio non trovato: %s" % save_id)
		return false

# ========================================
# GESTIONE LISTA SALVATAGGI
# ========================================

## Ottiene la lista dei salvataggi disponibili
func get_save_list() -> Array[Dictionary]:
	return available_saves.duplicate()

## Aggiorna la lista dei salvataggi
func _refresh_save_list() -> void:
	available_saves.clear()

	var dir = DirAccess.open("user://")
	if not dir:
		print("❌ Impossibile accedere directory user")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with(SAVE_PREFIX) and file_name.ends_with(".json"):
			var save_id = file_name.trim_prefix(SAVE_PREFIX).trim_suffix(".json")
			var save_data = _load_from_file(save_id)

			if not save_data.is_empty():
				var save_info = {
					"id": save_id,
					"name": save_data.metadata.get("name", "Salvataggio Senza Nome"),
					"timestamp": save_data.get("timestamp", 0),
					"version": save_data.get("version", "unknown"),
					"metadata": save_data.get("metadata", {})
				}
				available_saves.append(save_info)

		file_name = dir.get_next()

	dir.list_dir_end()

	# Ordina per timestamp (più recente prima)
	available_saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	# Mantieni solo i più recenti
	if available_saves.size() > MAX_SAVES:
		for i in range(MAX_SAVES, available_saves.size()):
			delete_save(available_saves[i].id)

		available_saves.resize(MAX_SAVES)

# ========================================
# SERIALIZZAZIONE STATO GIOCO
# ========================================

## Cattura lo stato completo del gioco
func _capture_game_state() -> Dictionary:
	return {
		# Stato giocatore
		"player": PlayerManager.get_save_data(),

		# Stato mondo (placeholder - da implementare in World.gd)
		"world": {
			"current_position": Vector2(0, 0),  # Placeholder
			"current_biome": "pianure",  # Placeholder
			"discovered_areas": []  # Placeholder
		},

		# Stato tempo
		"time": TimeManager.get_save_data(),

		# Stato eventi
		"events": EventManager.get_save_data(),

		# Stato quest
		"quests": QuestManager.get_save_data(),

		# Stato narrativo
		"narrative": NarrativeManager.get_save_data(),

		# Stato crafting
		"crafting": CraftingManager.get_crafting_system_state(),

		# Stato combattimento (se in corso)
		"combat": CombatManager.get_combat_state() if CombatManager.current_combat_state != CombatManager.CombatState.IDLE else {}
	}

## Ripristina lo stato del gioco
func _restore_game_state(game_state: Dictionary) -> bool:
	# Ordine di ripristino importante per dipendenze

	# 1. Ripristina tempo (base per tutto)
	if game_state.has("time"):
		TimeManager.load_save_data(game_state.time)

	# 2. Ripristina mondo (placeholder - da implementare in World.gd)
	if game_state.has("world"):
		print("💾 Placeholder: Ripristino stato mondo non implementato")

	# 3. Ripristina giocatore
	if game_state.has("player"):
		PlayerManager.load_save_data(game_state.player)

	# 4. Ripristina stati narrativi
	if game_state.has("narrative"):
		NarrativeManager.load_save_data(game_state.narrative)

	if game_state.has("quests"):
		QuestManager.load_save_data(game_state.quests)

	# 5. Ripristina sistemi di gioco
	if game_state.has("events"):
		EventManager.load_save_data(game_state.events)

	if game_state.has("crafting"):
		CraftingManager.load_save_data(game_state.crafting)

	# 6. Ripristina combattimento se era in corso
	if game_state.has("combat") and not game_state.combat.is_empty():
		CombatManager.load_save_data(game_state.combat)

	print("💾 Stato gioco ripristinato da salvataggio")
	return true

# ========================================
# METADATA SALVATAGGI
# ========================================

## Crea i metadata per un salvataggio
func _create_save_metadata(save_name: String, game_state: Dictionary) -> Dictionary:
	var player_data = game_state.get("player", {})
	var time_data = game_state.get("time", {})
	var world_data = game_state.get("world", {})

	var save_display_name = save_name
	if save_display_name == "":
		var timestamp = Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system()))
		save_display_name = "Salvataggio %02d/%02d %02d:%02d" % [
			timestamp.day, timestamp.month, floor(timestamp.hour), floor(timestamp.minute)
		]

	return {
		"name": save_display_name,
		"description": "Salvataggio automatico",
		"player_level": PlayerManager.get_progression_data().get("current_level", 1),
		"player_hp": player_data.get("hp", 100),
		"current_day": time_data.get("day", 1),
		"current_biome": world_data.get("current_biome", "unknown"),
		"play_time": _calculate_play_time(),
		"game_version": SAVE_VERSION
	}

## Calcola il tempo di gioco (placeholder)
func _calculate_play_time() -> int:
	# Per ora restituisce un valore fisso
	# In futuro potrebbe tracciare il tempo effettivo di gioco
	return 0

# ========================================
# GESTIONE FILE
# ========================================

## Salva dati su file
func _save_to_file(save_id: String, data: Dictionary) -> bool:
	var file_path = _get_save_file_path(save_id)
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if not file:
		print("❌ Errore apertura file per scrittura: %s" % file_path)
		return false

	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

	return true

## Carica dati da file
func _load_from_file(save_id: String) -> Dictionary:
	var file_path = _get_save_file_path(save_id)
	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("❌ Errore parsing JSON salvataggio: %s" % save_id)
		return {}

	return json.data

## Ottiene il percorso file per un salvataggio
func _get_save_file_path(save_id: String) -> String:
	return "user://%s%s.json" % [SAVE_PREFIX, save_id]

# ========================================
# UTILITÀ
# ========================================

## Genera un ID univoco per il salvataggio
func _generate_save_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random = randi_range(1000, 9999)
	return "save_%d_%d" % [timestamp, random]

## Verifica compatibilità versione salvataggio
func _is_save_compatible(save_data: Dictionary) -> bool:
	var save_version = save_data.get("version", "0.0.0")

	# Per ora accetta solo versioni esatte
	# In futuro potrebbe implementare migrazione
	return save_version == SAVE_VERSION

# ========================================
# API DEBUG E TESTING
# ========================================

## Forza un salvataggio di test
func debug_force_save(save_name: String = "Debug Save") -> String:
	print("🔧 DEBUG: Salvataggio forzato")
	return save_game(save_name)

## Carica l'ultimo salvataggio disponibile
func debug_load_latest() -> bool:
	if available_saves.size() > 0:
		var latest_save = available_saves[0]
		print("🔧 DEBUG: Caricamento ultimo salvataggio: %s" % latest_save.id)
		return load_game(latest_save.id)
	else:
		print("🔧 DEBUG: Nessun salvataggio disponibile")
		return false

## Lista tutti i file di salvataggio nella directory
func debug_list_save_files() -> void:
	print("🔧 DEBUG: File salvataggio nella directory user://")
	var dir = DirAccess.open("user://")
	if not dir:
		print("❌ Impossibile accedere directory user")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count = 0

	while file_name != "":
		if file_name.begins_with(SAVE_PREFIX):
			count += 1
			print("  - %s" % file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("Totale file salvataggio: %d" % count)

## Elimina tutti i salvataggi (per testing)
func debug_clear_all_saves() -> void:
	var saves_to_delete = available_saves.duplicate()
	for save_info in saves_to_delete:
		delete_save(save_info.id)
	print("🔧 DEBUG: Tutti i salvataggi eliminati")