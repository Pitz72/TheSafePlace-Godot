extends Node

## CraftingManager Singleton - The Safe Place v0.4.1
##
## Gestisce il sistema di crafting con ricette, materiali e produzione oggetti
## Implementa il sistema crafting del GDD React adattato per Godot
##
## Architettura: Singleton (Autoload) per gestione globale crafting

# ========================================
# ENUM E COSTANTI
# ========================================

enum CraftingResult {
	SUCCESS = 0,
	INSUFFICIENT_MATERIALS = 1,
	MISSING_TOOLS = 2,
	INSUFFICIENT_SKILL = 3,
	WORKBENCH_REQUIRED = 4,
	UNKNOWN_RECIPE = 5
}

# ========================================
# SEGNALI PUBBLICI
# ========================================

signal crafting_completed(item_id: String, quantity: int)
signal crafting_failed(recipe_id: String, reason: CraftingResult)
signal recipe_unlocked(recipe_id: String)
signal workbench_access_changed(has_access: bool)

# ========================================
# VARIABILI STATO CRAFTING
# ========================================

## Database ricette caricato
var recipes_database: Dictionary = {}

## Ricette sbloccate
var unlocked_recipes: Array[String] = []

## Accesso al workbench (solo nei rifugi)
var has_workbench_access: bool = false

## Skill crafting del giocatore (basato su intelligenza)
var crafting_skill: int = 0

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("🔨 CraftingManager: Inizializzazione sistema crafting...")
	_load_recipes_database()
	_initialize_unlocked_recipes()
	_connect_signals()
	print("✅ CraftingManager: Sistema crafting pronto")

## Carica il database ricette
func _load_recipes_database() -> void:
	var recipes_file = "res://data/crafting/recipes.json"
	recipes_database = DataManager.load_json_file(recipes_file)

	if recipes_database.is_empty():
		push_error("CraftingManager: Impossibile caricare database ricette")
		return

	print("🔨 CraftingManager: Caricato database ricette con %d ricette" % recipes_database.size())

## Inizializza le ricette base sbloccate
func _initialize_unlocked_recipes() -> void:
	# Ricette base sempre disponibili (no skill requirement)
	unlocked_recipes = [
		"repair_cloth",     # Riparazione stoffa
		"sharpen_knife",    # Affilatura coltello
		"make_bandage"      # Creazione bende
	]

	print("🔨 CraftingManager: Ricette base sbloccate: %d" % unlocked_recipes.size())

## Connette i segnali necessari
func _connect_signals() -> void:
	# Nota: Connessione a MainGame rimossa per evitare dipendenze circolari
	# L'accesso workbench sarà gestito tramite chiamate dirette da MainGame
	print("🔨 CraftingManager: Segnali connessi (senza dipendenze esterne)")

# ========================================
# API CRAFTING PRINCIPALE
# ========================================

## Tenta di craftare un oggetto
func attempt_crafting(recipe_id: String, quantity: int = 1) -> CraftingResult:
	# Verifica se la ricetta è sbloccata
	if not is_recipe_unlocked(recipe_id):
		print("🔨 Crafting fallito: Ricetta non sbloccata - %s" % recipe_id)
		crafting_failed.emit(recipe_id, CraftingResult.UNKNOWN_RECIPE)
		return CraftingResult.UNKNOWN_RECIPE

	# Ottieni dati ricetta
	var recipe_data = get_recipe_data(recipe_id)
	if recipe_data.is_empty():
		print("🔨 Crafting fallito: Ricetta non trovata - %s" % recipe_id)
		crafting_failed.emit(recipe_id, CraftingResult.UNKNOWN_RECIPE)
		return CraftingResult.UNKNOWN_RECIPE

	# Verifica requisiti workbench
	if recipe_data.get("requires_workbench", false) and not has_workbench_access:
		print("🔨 Crafting fallito: Workbench richiesto - %s" % recipe_id)
		crafting_failed.emit(recipe_id, CraftingResult.WORKBENCH_REQUIRED)
		return CraftingResult.WORKBENCH_REQUIRED

	# Verifica skill requirement
	var required_skill = recipe_data.get("required_skill", 0)
	if crafting_skill < required_skill:
		print("🔨 Crafting fallito: Skill insufficiente (%d < %d) - %s" % [crafting_skill, required_skill, recipe_id])
		crafting_failed.emit(recipe_id, CraftingResult.INSUFFICIENT_SKILL)
		return CraftingResult.INSUFFICIENT_SKILL

	# Verifica materiali disponibili
	if not _has_required_materials(recipe_data, quantity):
		print("🔨 Crafting fallito: Materiali insufficienti - %s" % recipe_id)
		crafting_failed.emit(recipe_id, CraftingResult.INSUFFICIENT_MATERIALS)
		return CraftingResult.INSUFFICIENT_MATERIALS

	# Verifica strumenti richiesti
	if not _has_required_tools(recipe_data):
		print("🔨 Crafting fallito: Strumenti mancanti - %s" % recipe_id)
		crafting_failed.emit(recipe_id, CraftingResult.MISSING_TOOLS)
		return CraftingResult.MISSING_TOOLS

	# Esegui il crafting
	return _execute_crafting(recipe_data, quantity)

## Esegue il crafting effettivo
func _execute_crafting(recipe_data: Dictionary, quantity: int) -> CraftingResult:
	var recipe_id = recipe_data.get("id", "unknown")

	# Rimuovi materiali richiesti
	if not _consume_materials(recipe_data, quantity):
		print("🔨 Crafting fallito: Errore consumo materiali - %s" % recipe_id)
		crafting_failed.emit(recipe_id, CraftingResult.INSUFFICIENT_MATERIALS)
		return CraftingResult.INSUFFICIENT_MATERIALS

	# Aggiungi oggetto prodotto
	var output_item = recipe_data.get("output", {})
	var output_id = output_item.get("id", "")
	var output_quantity = output_item.get("quantity", 1) * quantity

	if PlayerManager.add_item(output_id, output_quantity):
		print("🔨 Crafting riuscito: %dx %s creato da %s" % [output_quantity, output_id, recipe_id])
		crafting_completed.emit(output_id, output_quantity)

		# Aumenta skill crafting
		_increase_crafting_skill(1)

		return CraftingResult.SUCCESS
	else:
		print("🔨 Crafting fallito: Impossibile aggiungere oggetto - %s" % output_id)
		# Nota: materiali già consumati, potrebbe essere necessario refund
		crafting_failed.emit(recipe_id, CraftingResult.INSUFFICIENT_MATERIALS)
		return CraftingResult.INSUFFICIENT_MATERIALS

# ========================================
# GESTIONE MATERIALI E STRUMENTI
# ========================================

## Verifica se il giocatore ha i materiali richiesti
func _has_required_materials(recipe_data: Dictionary, quantity: int) -> bool:
	var materials = recipe_data.get("materials", [])
	if materials.is_empty():
		return true  # Nessun materiale richiesto

	for material in materials:
		var material_id = material.get("id", "")
		var required_quantity = material.get("quantity", 1) * quantity

		if PlayerManager.get_item_count(material_id) < required_quantity:
			return false

	return true

## Verifica se il giocatore ha gli strumenti richiesti
func _has_required_tools(recipe_data: Dictionary) -> bool:
	var tools = recipe_data.get("tools", [])
	if tools.is_empty():
		return true  # Nessuno strumento richiesto

	for tool_id in tools:
		if PlayerManager.get_item_count(tool_id) < 1:
			return false

	return true

## Consuma i materiali richiesti
func _consume_materials(recipe_data: Dictionary, quantity: int) -> bool:
	var materials = recipe_data.get("materials", [])
	var success = true

	for material in materials:
		var material_id = material.get("id", "")
		var consume_quantity = material.get("quantity", 1) * quantity

		if not PlayerManager.remove_item(material_id, consume_quantity):
			success = false
			break

	return success

# ========================================
# GESTIONE RICETTE
# ========================================

## Verifica se una ricetta è sbloccata
func is_recipe_unlocked(recipe_id: String) -> bool:
	return recipe_id in unlocked_recipes

## Sblocca una ricetta
func unlock_recipe(recipe_id: String) -> void:
	if recipe_id in unlocked_recipes:
		return  # Già sbloccata

	unlocked_recipes.append(recipe_id)
	recipe_unlocked.emit(recipe_id)
	print("🔨 Ricetta sbloccata: %s" % recipe_id)

## Ottiene i dati di una ricetta
func get_recipe_data(recipe_id: String) -> Dictionary:
	if recipes_database.has(recipe_id):
		return recipes_database[recipe_id]
	return {}

## Ottiene tutte le ricette disponibili
func get_available_recipes() -> Array[String]:
	var available = []
	for recipe_id in unlocked_recipes:
		if recipes_database.has(recipe_id):
			available.append(recipe_id)
	return available

## Ottiene le ricette che possono essere craftate (materiali disponibili)
func get_craftable_recipes() -> Array[String]:
	var craftable = []

	for recipe_id in unlocked_recipes:
		var recipe_data = get_recipe_data(recipe_id)
		if not recipe_data.is_empty():
			if _has_required_materials(recipe_data, 1) and _has_required_tools(recipe_data):
				craftable.append(recipe_id)

	return craftable

# ========================================
# GESTIONE SKILL E PROGRESSIONE
# ========================================

## Aggiorna il livello skill crafting basato sull'intelligenza del giocatore
func update_crafting_skill() -> void:
	var intelligence = PlayerManager.get_stat("intelligenza")
	crafting_skill = intelligence  # Per ora 1:1, potrebbe essere modificato
	print("🔨 Skill crafting aggiornato: %d (basato su intelligenza)" % crafting_skill)

## Aumenta il skill crafting
func _increase_crafting_skill(amount: int) -> void:
	crafting_skill += amount
	print("🔨 Skill crafting aumentato: +%d (totale: %d)" % [amount, crafting_skill])

## Ottiene il livello skill corrente
func get_crafting_skill() -> int:
	return crafting_skill

# ========================================
# GESTIONE WORKBENCH
# ========================================

## Imposta l'accesso al workbench
func set_workbench_access(has_access: bool) -> void:
	if has_workbench_access != has_access:
		has_workbench_access = has_access
		workbench_access_changed.emit(has_access)
		print("🔨 Accesso workbench: %s" % ("Disponibile" if has_access else "Non disponibile"))

## Verifica se c'è accesso al workbench
func has_workbench() -> bool:
	return has_workbench_access

## Nota: Callback rimosso per evitare dipendenze circolari
## L'accesso workbench sarà gestito tramite chiamate dirette da MainGame

# ========================================
# API RICERCA E FILTRI
# ========================================

## Cerca ricette per categoria
func get_recipes_by_category(category: String) -> Array[String]:
	var matching = []

	for recipe_id in unlocked_recipes:
		var recipe_data = get_recipe_data(recipe_id)
		if recipe_data.get("category", "") == category:
			matching.append(recipe_id)

	return matching

## Ottiene ricette che richiedono workbench
func get_workbench_recipes() -> Array[String]:
	var workbench_only = []

	for recipe_id in unlocked_recipes:
		var recipe_data = get_recipe_data(recipe_id)
		if recipe_data.get("requires_workbench", false):
			workbench_only.append(recipe_id)

	return workbench_only

## Ottiene il costo totale di una ricetta
func get_recipe_cost(recipe_id: String) -> Array[Dictionary]:
	var recipe_data = get_recipe_data(recipe_id)
	return recipe_data.get("materials", [])

# ========================================
# API DEBUG E TESTING
# ========================================

## Forza sblocco di una ricetta (per debug)
func debug_unlock_recipe(recipe_id: String) -> void:
	unlock_recipe(recipe_id)
	print("🔧 DEBUG: Ricetta forzatamente sbloccata: %s" % recipe_id)

## Aggiunge materiali di test (per testing)
func debug_add_crafting_materials() -> void:
	var test_materials = [
		{"id": "cloth_scraps", "quantity": 5},
		{"id": "wood_sticks", "quantity": 3},
		{"id": "metal_scraps", "quantity": 2}
	]

	for material in test_materials:
		PlayerManager.add_item(material.id, material.quantity)

	print("🔧 DEBUG: Materiali crafting di test aggiunti")

## Reset sistema crafting (per testing)
func debug_reset_crafting_system() -> void:
	unlocked_recipes.clear()
	has_workbench_access = false
	crafting_skill = 0
	_initialize_unlocked_recipes()
	print("🔧 DEBUG: Sistema crafting resettato")

## Ottieni stato completo del sistema crafting
func get_crafting_system_state() -> Dictionary:
	return {
		"unlocked_recipes": unlocked_recipes.duplicate(),
		"has_workbench_access": has_workbench_access,
		"crafting_skill": crafting_skill,
		"available_recipes": get_available_recipes(),
		"craftable_recipes": get_craftable_recipes()
	}