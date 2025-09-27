extends Node

## DataManager Singleton - The Safe Place v0.0.3
## 
## Gestisce il caricamento e l'accesso a tutti i database JSON modulari del gioco.
## Architettura: 
## - data/system/ → File condivisi (rarity_system.json)
## - data/items/ → Database oggetti categorizzati (weapons, armor, consumables, etc.)
##
## Progettato come Singleton (Autoload) per accesso globale ai dati.

# ========================================
# COSTANTI - SISTEMA COLORI OGGETTI
# ========================================

## Colori base per categoria oggetti (LINGUAGGIO COMUNE)
const CATEGORY_COLORS: Dictionary = {
	"WEAPON": Color(0.8, 0.2, 0.2),      # Rosso
	"ARMOR": Color(0.2, 0.6, 0.8),       # Blu
	"CONSUMABLE": Color(0.2, 0.8, 0.2),  # Verde
	"TOOL": Color(0.8, 0.6, 0.2),        # Arancione
	"AMMO": Color(0.6, 0.4, 0.2),        # Marrone
	"CRAFTING_MATERIAL": Color(0.6, 0.2, 0.8), # Viola
	"QUEST": Color(0.8, 0.8, 0.2),       # Giallo
	"UNIQUE": Color(0.8, 0.4, 0.6),      # Rosa
	"ACCESSORY": Color(0.4, 0.8, 0.8)    # Ciano
}

## Moltiplicatori intensità per rarità oggetti
const RARITY_MULTIPLIERS: Dictionary = {
	"COMMON": 0.6,
	"UNCOMMON": 0.8,
	"RARE": 1.0,
	"EPIC": 1.3,
	"LEGENDARY": 1.6
}

# ========================================
# VARIABILI PUBBLICHE - DATABASE CARICATI
# ========================================

## Sistema rarità condiviso da tutti i database
var rarity_system: Dictionary = {}
## Database effetti di stato per combattimento
var status_effects: Dictionary = {}
var special_abilities: Dictionary = {}

## Database oggetti separati per categoria
var unique_items: Dictionary = {}
var weapons: Dictionary = {}
var armor: Dictionary = {}
var consumables: Dictionary = {}
var crafting_materials: Dictionary = {}
var ammo: Dictionary = {}
var misc_items: Dictionary = {}
var materials: Dictionary = {}
var quest_items: Dictionary = {}

## Database unificato di tutti gli oggetti per accesso rapido
## Struttura: { "item_id": { dati_oggetto }, ... }
var items: Dictionary = {}

# ========================================
# STATISTICHE DI CARICAMENTO
# ========================================

var _total_items_loaded: int = 0
var _loading_errors: Array[String] = []

# CACHE PERFORMANCE
var _name_search_cache: Dictionary = {}  # Cache per ricerche nome
var _category_cache: Dictionary = {}     # Cache per categorie
var _rarity_cache: Dictionary = {}       # Cache per rarità

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("🗄️ DataManager inizializzazione...")
	_load_all_data()
	_validate_data_integrity()
	print("✅ DataManager pronto - %d oggetti caricati" % _total_items_loaded)
	if _loading_errors.size() > 0:
		print("⚠️ Errori durante caricamento: %d" % _loading_errors.size())
		for error in _loading_errors:
			print("   - %s" % error)

# ========================================
# CARICAMENTO DATI PRIVATO
# ========================================

## Carica tutti i database JSON dall'architettura modulare
func _load_all_data() -> void:
	print("📁 Caricamento database modulari...")
	
	# 1. SISTEMA CONDIVISO
	rarity_system = _load_json_file("res://data/system/rarity_system.json")
	status_effects = _load_json_file("res://data/system/status_effects.json")
	special_abilities = _load_json_file("res://data/system/special_abilities.json")
	if rarity_system.has("rarity_system"):
		print("   ✅ Sistema rarità: %d livelli" % rarity_system.rarity_system.size())
	
	# 2. DATABASE OGGETTI CATEGORIZZATI (MODULARI)
	_load_items_database_modular()
	unique_items = _load_json_file("res://data/items/unique_items.json")
	weapons = _load_json_file("res://data/items/weapons.json")
	armor = _load_json_file("res://data/items/armor.json")
	consumables = _load_json_file("res://data/items/consumables.json")
	crafting_materials = _load_json_file("res://data/items/crafting_materials.json")
	ammo = _load_json_file("res://data/items/ammo.json")
	quest_items = _load_json_file("res://data/items/quest_items.json")
	
	# 3. UNIFICAZIONE OGGETTI
	_merge_item_databases()
	
	print("📊 Caricamento completato:")
	print("   • Oggetti unici: %d" % _count_items(unique_items))
	print("   • Armi: %d" % _count_items(weapons))
	print("   • Armature: %d" % _count_items(armor))
	print("   • Consumabili: %d" % _count_items(consumables))
	print("   • Materiali crafting: %d" % _count_items(crafting_materials))
	print("   • Munizioni: %d" % _count_items(ammo))
	print("   • Oggetti quest: %d" % _count_items(quest_items))

## Helper per caricare e parsare singoli file JSON con gestione errori robusta
func _load_json_file(file_path: String) -> Dictionary:
	# Verifica esistenza file prima dell'apertura
	if not FileAccess.file_exists(file_path):
		var error_msg = "File non trovato: %s" % file_path
		_loading_errors.append(error_msg)
		push_error("DataManager: %s" % error_msg)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)

	# Gestione errori FileAccess specifici
	if file == null:
		var error_code = FileAccess.get_open_error()
		var error_msg = "Errore accesso file %s: %s (codice %d)" % [
			file_path,
			_get_file_access_error_message(error_code),
			error_code
		]
		_loading_errors.append(error_msg)
		push_error("DataManager: %s" % error_msg)
		return {}

	# Lettura contenuto file con controllo dimensione
	var file_content = file.get_as_text()
	file.close()

	# Verifica contenuto non vuoto
	if file_content.is_empty():
		var error_msg = "File vuoto: %s" % file_path
		_loading_errors.append(error_msg)
		push_error("DataManager: %s" % error_msg)
		return {}

	# Parsing JSON con validazione avanzata
	var json = JSON.new()
	var parse_result = json.parse(file_content)

	# Gestione errore: JSON non valido
	if parse_result != OK:
		var error_msg = "JSON malformato in %s - Linea %d: %s" % [
			file_path,
			json.get_error_line(),
			json.get_error_message()
		]
		_loading_errors.append(error_msg)
		push_error("DataManager: %s" % error_msg)
		return {}

	# Verifica che sia un Dictionary
	var data = json.data
	if not data is Dictionary:
		var error_msg = "Struttura JSON invalida in %s - Root deve essere un Object, trovato %s" % [
			file_path,
			type_string(typeof(data))
		]
		_loading_errors.append(error_msg)
		push_error("DataManager: %s" % error_msg)
		return {}

	print("   ✅ Caricato: %s (%d caratteri)" % [file_path.get_file(), file_content.length()])
	return data

## Converte codici errore FileAccess in messaggi leggibili
func _get_file_access_error_message(error_code: int) -> String:
	match error_code:
		ERR_FILE_NOT_FOUND:
			return "File non trovato"
		ERR_FILE_NO_PERMISSION:
			return "Permessi insufficienti"
		ERR_FILE_CANT_OPEN:
			return "Impossibile aprire il file"
		ERR_FILE_CANT_READ:
			return "Impossibile leggere il file"
		_:
			return "Errore sconosciuto (%d)" % error_code

## Unisce tutti i database di oggetti in un singolo dizionario per accesso rapido
func _merge_item_databases() -> void:
	print("🔗 Unificazione database oggetti...")
	
	var databases = [
		unique_items,
		weapons, 
		armor,
		consumables,
		crafting_materials,
		ammo,
		quest_items
	]
	
	items.clear()
	var conflicts: Array[String] = []
	
	for database in databases:
		# Determina la chiave principale basandosi sulla struttura del file
		var main_key = ""
		if database.has("unique_items"):
			main_key = "unique_items"
		elif database.has("items"):
			main_key = "items"
		elif database.has("weapons"):
			main_key = "weapons"
		elif database.has("armor"):
			main_key = "armor"
		elif database.has("consumables"):
			main_key = "consumables"
		elif database.has("crafting_materials"):
			main_key = "crafting_materials"
		elif database.has("ammo"):
			main_key = "ammo"
		elif database.has("quest_items"):
			main_key = "quest_items"
		
		if main_key != "":
			var data_collection = database[main_key]
			
			# Gestione sia Array che Dictionary
			if data_collection is Array:
				# Array di oggetti (es. unique_items)
				for item_data in data_collection:
					if item_data.has("id"):
						var item_id = item_data.id
						if items.has(item_id):
							conflicts.append("ID duplicato: %s" % item_id)
						else:
							items[item_id] = item_data
							_total_items_loaded += 1
			elif data_collection is Dictionary:
				# Dictionary di oggetti (es. weapons, armor)
				for item_id in data_collection:
					if items.has(item_id):
						conflicts.append("ID duplicato: %s" % item_id)
					else:
						items[item_id] = data_collection[item_id]
						_total_items_loaded += 1
	
	if conflicts.size() > 0:
		print("⚠️ Conflitti ID rilevati:")
		for conflict in conflicts:
			print("   - %s" % conflict)
			_loading_errors.append(conflict)
	
	print("   ✅ Database unificato: %d oggetti totali" % items.size())

## Conta gli oggetti in un database specifico
func _count_items(database: Dictionary) -> int:
	# Cerca la chiave principale del database
	var main_keys = ["items", "unique_items", "weapons", "armor", "consumables", "crafting_materials", "ammo", "quest_items"]
	for key in main_keys:
		if database.has(key):
			var data = database[key]
			if data is Array:
				return data.size()
			elif data is Dictionary:
				return data.size()
	return 0

## Verifica integrità dei dati caricati
func _validate_data_integrity() -> void:
	print("🔍 Validazione integrità dati...")
	
	# Verifica sistema rarità
	if not rarity_system.has("rarity_system"):
		_loading_errors.append("Sistema rarità mancante o corrotto")
	
	# Verifica che tutti gli oggetti abbiano proprietà essenziali
	var invalid_items: Array[String] = []
	for item_id in items:
		var item_data = items[item_id]
		if not _validate_item_properties(item_data):
			invalid_items.append(item_id)
	
	if invalid_items.size() > 0:
		print("⚠️ Oggetti con proprietà mancanti: %d" % invalid_items.size())
		for item_id in invalid_items:
			_loading_errors.append("Proprietà mancanti in oggetto: %s" % item_id)
	
	print("   ✅ Validazione completata")

## Verifica che un oggetto abbia tutte le proprietà essenziali
func _validate_item_properties(item_data: Dictionary) -> bool:
	var required_properties = ["id", "name", "description", "category", "rarity", "weight", "value"]
	for prop in required_properties:
		if not item_data.has(prop):
			return false
	return true

# ========================================
# API PUBBLICA - ACCESSO AI DATI
# ========================================

## Restituisce i dati di un oggetto specifico dal database unificato
## @param item_id: ID univoco dell'oggetto
## @return: Dictionary con dati oggetto, o {} se non trovato
func get_item_data(item_id: String) -> Dictionary:
	# Prima cerca nel database unificato (più efficiente)
	if items.has(item_id):
		return items[item_id].duplicate(true)

	# Fallback: cerca nei database modulari (per compatibilità)
	var databases = [weapons, armor, consumables, crafting_materials, ammo, misc_items, materials, unique_items, quest_items]

	for db in databases:
		if db.has(item_id):
			return db[item_id].duplicate(true)

	# Item non trovato
	print("⚠️ DataManager: Oggetto non trovato: %s" % item_id)
	return {}

## Restituisce i dati di un livello di rarità
## @param rarity_name: Nome rarità (es. "COMMON", "EPIC", "LEGENDARY")
## @return: Dictionary con dati rarità, o {} se non trovato
func get_rarity_data(rarity_name: String) -> Dictionary:
	if rarity_system.has("rarity_system") and rarity_system.rarity_system.has(rarity_name):
		return rarity_system.rarity_system[rarity_name]
	
	print("⚠️ DataManager: Rarità non trovata: %s" % rarity_name)
	return {}

## Restituisce i dati di un effetto di stato
func get_status_effect_data(effect_id: String) -> Dictionary:
	if status_effects.has(effect_id):
		return status_effects[effect_id]
	print("⚠️ DataManager: Effetto di stato non trovato: %s" % effect_id)
	return {}

## Restituisce i dati di un'abilità speciale
func get_special_ability_data(enemy_category: String, ability_tier: String) -> Dictionary:
	if special_abilities.has(enemy_category) and special_abilities[enemy_category].has(ability_tier):
		return special_abilities[enemy_category][ability_tier]
	# Non stampare un errore qui, è normale che un nemico non abbia abilità
	return {}

## Restituisce tutti gli oggetti di una categoria specifica (con cache)
## @param category: Categoria oggetti ("WEAPON", "ARMOR", "CONSUMABLE", etc.)
## @return: Dictionary con oggetti della categoria
func get_items_by_category(category: String) -> Dictionary:
	# Controlla cache prima
	if _category_cache.has(category):
		return _category_cache[category].duplicate()

	var filtered_items: Dictionary = {}

	for item_id in items:
		var item_data = items[item_id]
		if item_data.has("category") and item_data.category == category:
			filtered_items[item_id] = item_data

	# Salva in cache
	_category_cache[category] = filtered_items.duplicate()

	return filtered_items

## Restituisce tutti gli oggetti di una sottocategoria specifica
## @param subcategory: Sottocategoria oggetti ("melee", "ranged", "food", etc.)
## @return: Dictionary con oggetti della sottocategoria
func get_items_by_subcategory(subcategory: String) -> Dictionary:
	var filtered_items: Dictionary = {}
	
	for item_id in items:
		var item_data = items[item_id]
		if item_data.has("subcategory") and item_data.subcategory == subcategory:
			filtered_items[item_id] = item_data
	
	return filtered_items

## Restituisce tutti gli oggetti di una rarità specifica (con cache)
## @param rarity: Livello rarità ("COMMON", "RARE", "LEGENDARY", etc.)
## @return: Dictionary con oggetti della rarità
func get_items_by_rarity(rarity: String) -> Dictionary:
	# Controlla cache prima
	if _rarity_cache.has(rarity):
		return _rarity_cache[rarity].duplicate()

	var filtered_items: Dictionary = {}

	for item_id in items:
		var item_data = items[item_id]
		if item_data.has("rarity") and item_data.rarity == rarity:
			filtered_items[item_id] = item_data

	# Salva in cache
	_rarity_cache[rarity] = filtered_items.duplicate()

	return filtered_items

## Cerca oggetti per nome (ricerca fuzzy case-insensitive con cache)
## @param search_term: Termine di ricerca
## @return: Array di ID oggetti che matchano
func search_items_by_name(search_term: String) -> Array[String]:
	var search_lower = search_term.to_lower()

	# Controlla cache prima
	if _name_search_cache.has(search_lower):
		return _name_search_cache[search_lower].duplicate()

	var results: Array[String] = []

	# Pre-calcola lowercase names per performance
	for item_id in items:
		var item_data = items[item_id]
		if item_data.has("name"):
			var name_lower = item_data.name.to_lower()
			if name_lower.contains(search_lower):
				results.append(item_id)

	# Salva in cache per ricerche future
	_name_search_cache[search_lower] = results.duplicate()

	return results

## Verifica se un oggetto esiste nel database
## @param item_id: ID oggetto da verificare
## @return: true se esiste, false altrimenti
func has_item(item_id: String) -> bool:
	return items.has(item_id)

## Calcola il colore di un oggetto basato su categoria e rarità
## @param item_id: ID dell'oggetto
## @return: Color calcolato, o Color.WHITE se oggetto non trovato
func get_item_color(item_id: String) -> Color:
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		return Color.WHITE
	
	# Ottieni colore base dalla categoria
	var base_color = Color.WHITE
	if item_data.has("category") and CATEGORY_COLORS.has(item_data.category):
		base_color = CATEGORY_COLORS[item_data.category]
	
	# Ottieni moltiplicatore dalla rarità
	var multiplier = 1.0
	if item_data.has("rarity") and RARITY_MULTIPLIERS.has(item_data.rarity):
		multiplier = RARITY_MULTIPLIERS[item_data.rarity]
	
	# Calcola colore finale
	return Color(base_color.r * multiplier, base_color.g * multiplier, base_color.b * multiplier, base_color.a)

## Restituisce statistiche generali sui dati caricati
## @return: Dictionary con statistiche
func get_loading_stats() -> Dictionary:
	return {
		"total_items": _total_items_loaded,
		"unique_items": _count_items(unique_items),
		"weapons": _count_items(weapons),
		"armor": _count_items(armor),
		"consumables": _count_items(consumables),
		"crafting_materials": _count_items(crafting_materials),
		"ammo": _count_items(ammo),
		"quest_items": _count_items(quest_items),
		"rarity_levels": rarity_system.rarity_system.size() if rarity_system.has("rarity_system") else 0,
		"loading_errors": _loading_errors.size(),
		"has_errors": _loading_errors.size() > 0
	}

## Restituisce la lista degli errori di caricamento (per debugging)
## @return: Array di stringhe con messaggi errore
func get_loading_errors() -> Array[String]:
	return _loading_errors.duplicate()

# ========================================
# API AVANZATA - ACCESSO SPECIALIZZATO
# ========================================

## Restituisce tutte le armi ordinate per danno
## @return: Array di Dictionary ordinato per danno crescente
func get_weapons_by_damage() -> Array[Dictionary]:
	var weapon_list: Array[Dictionary] = []
	
	for item_id in items:
		var item_data = items[item_id]
		if item_data.has("category") and item_data.category == "WEAPON":
			weapon_list.append(item_data)
	
	# Ordinamento per danno medio
	weapon_list.sort_custom(func(a, b): 
		var damage_a = _get_average_damage(a)
		var damage_b = _get_average_damage(b)
		return damage_a < damage_b
	)
	
	return weapon_list

## Calcola il danno medio di un'arma
## @param weapon_data: Dati dell'arma
## @return: Valore numerico del danno medio
func _get_average_damage(weapon_data: Dictionary) -> float:
	# Cerca il danno sia nel campo diretto che nelle properties
	var damage = null
	if weapon_data.has("damage"):
		damage = weapon_data.damage
	elif weapon_data.has("properties") and weapon_data.properties.has("damage"):
		damage = weapon_data.properties.damage
	else:
		return 0.0
	
	if damage is String:
		# Formato "min-max" (es. "10-15")
		var parts = damage.split("-")
		if parts.size() == 2:
			var min_dmg = parts[0].to_float()
			var max_dmg = parts[1].to_float()
			return (min_dmg + max_dmg) / 2.0
		else:
			return damage.to_float()
	elif damage is int or damage is float:
		return float(damage)
	else:
		return 0.0

## Restituisce tutti gli oggetti equipaggiabili per uno slot specifico
## @param slot: Slot equipaggiamento ("main_hand", "body", "feet", etc.)
## @return: Dictionary con oggetti per lo slot
func get_items_by_slot(slot: String) -> Dictionary:
	var slot_items: Dictionary = {}
	
	for item_id in items:
		var item_data = items[item_id]
		# Controlla sia il campo diretto che nelle properties
		var item_slot = null
		if item_data.has("slot"):
			item_slot = item_data.slot
		elif item_data.has("properties") and item_data.properties.has("slot"):
			item_slot = item_data.properties.slot
		
		if item_slot == slot:
			slot_items[item_id] = item_data
	
	return slot_items

## Restituisce i colori definiti per le rarità
## @return: Dictionary con mapping rarità → colore
func get_rarity_colors() -> Dictionary:
	var colors: Dictionary = {}
	
	if rarity_system.has("rarity_system"):
		for rarity_name in rarity_system.rarity_system:
			var rarity_data = rarity_system.rarity_system[rarity_name]
			if rarity_data.has("color"):
				colors[rarity_name] = rarity_data.color
	
	return colors

## Metodo pubblico per caricare file JSON (per EventManager e altri sistemi)
## @param file_path: Percorso del file JSON da caricare
## @return: Dictionary con i dati caricati
func load_json_file(file_path: String) -> Dictionary:
	return _load_json_file(file_path)

# ========================================
# DEBUG E DIAGNOSTICA
# ========================================

## Stampa un report completo sui dati caricati (per debugging)
func print_loading_report() -> void:
	print("\n" + "=".repeat(50))
	print("📊 DATAMANAGER - REPORT CARICAMENTO")
	print("=".repeat(50))
	
	var stats = get_loading_stats()
	print("📦 Oggetti totali: %d" % stats.total_items)
	print("   • Oggetti unici: %d" % stats.unique_items)
	print("   • Armi: %d" % stats.weapons)
	print("   • Armature: %d" % stats.armor)
	print("   • Consumabili: %d" % stats.consumables)
	print("   • Materiali crafting: %d" % stats.crafting_materials)
	print("   • Munizioni: %d" % stats.ammo)
	print("   • Oggetti quest: %d" % stats.quest_items)
	print("🎲 Livelli rarità: %d" % stats.rarity_levels)
	print("❌ Errori: %d" % stats.loading_errors)
	
	if stats.has_errors:
		print("\n⚠️ ERRORI RILEVATI:")
		for error in _loading_errors:
			print("   - %s" % error)
	
	print("=".repeat(50) + "\n")
  
## Carica database oggetti modulari dalla cartella categories
func _load_items_database_modular() -> void:
	print("[DataManager] Caricamento database oggetti modulari...")
	# Carica file categorizzati
	var category_files = {
		"weapons": "res://data/items/categories/weapons.json",
		"consumables": "res://data/items/categories/consumables.json",
		"misc": "res://data/items/categories/misc.json",
		"materials": "res://data/items/categories/materials.json"
	}

	for category in category_files.keys():
		var file_path = category_files[category]
		var data = _load_json_file(file_path)
		if data and data.has(category):
			set(category + "_items", data[category])
			print("   ✅ %s: %d item" % [category.capitalize(), data[category].size()])
		else:
			print("   ❌ Errore caricamento %s" % category)

	print("[DataManager] Database oggetti modulari caricati")
