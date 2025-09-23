extends Node

## PlayerManager Singleton - The Safe Place v0.1.2
## 
## Gestisce tutti i dati del personaggio giocatore (statistiche, inventario, risorse).
## Progettato come Singleton (Autoload) per accesso globale allo stato del player.
## 
## Milestone 2: Gameplay Core - Sistema centrale di gestione personaggio
## Integrato con DataManager per validazione oggetti e proprietà avanzate.

# ========================================
# ENUM STATI PERSONAGGIO (M3.T3)
# ========================================

## Definisce i possibili stati fisici del personaggio
enum Status {
	NORMAL,      ## Condizione normale, nessun problema
	WOUNDED,     ## Ferito, ridotta capacità di combattimento
	SICK,        ## Malato, debilitato fisicamente
	POISONED     ## Avvelenato, perdita HP graduale
}

# ========================================
# SEGNALI PUBBLICI
# ========================================

## Emesso quando l'inventario cambia (aggiunta/rimozione oggetti)
signal inventory_changed

## Emesso quando le statistiche del player cambiano
signal stats_changed

## Emesso quando HP, food o water cambiano
signal resources_changed

## Emesso per messaggi narrativi da mostrare nel diario di gioco
signal narrative_log_generated(message: String)

# ========================================
# RISORSE VITALI
# ========================================

## Punti vita correnti
var hp: int = 100
## Punti vita massimi
var max_hp: int = 100

## Livello fame corrente (0 = affamato)
var food: int = 100
## Livello fame massimo
var max_food: int = 100

## Livello sete corrente (0 = assetato)
var water: int = 100
## Livello sete massimo
var max_water: int = 100

# ========================================
# STATISTICHE PERSONAGGIO
# ========================================

## Statistiche del personaggio
## Chiavi: "forza", "agilita", "intelligenza", "carisma", "fortuna", "vigore"
var stats: Dictionary = {}

# ========================================
# SISTEMA PROGRESSIONE (M3.T1)
# ========================================

## Punti esperienza totali accumulati
var experience: int = 0

## Soglia esperienza per prossimo punto statistica
var experience_for_next_point: int = 100

## Punti statistica disponibili da spendere
var available_stat_points: int = 0

# ========================================
# STATI PERSONAGGIO (M3.T3)
# ========================================

## Array degli stati attivi del personaggio
## Può contenere più stati contemporaneamente
var active_statuses: Array[Status] = []

# ========================================
# SISTEMA STATO EMOTIVO (NARRATIVO)
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
var current_emotional_state: int = 0  # 0=Cold, 1=Guarded, 2=Open, 3=Connected, 4=Transformed

# ========================================
# INVENTARIO E EQUIPAGGIAMENTO
# ========================================

## Limite massimo di oggetti trasportabili
const MAX_INVENTORY_SLOTS: int = 10

## Inventario del giocatore
## Struttura: Array di Dictionary { "id": String, "quantity": int, "instance_data": Dictionary }
var inventory: Array[Dictionary] = []

## Arma equipaggiata corrente
## Struttura: Dictionary con dati completi dell'arma (da DataManager)
var equipped_weapon: Dictionary = {}

## Armatura equipaggiata corrente  
## Struttura: Dictionary con dati completi dell'armatura (da DataManager)
var equipped_armor: Dictionary = {}

# ========================================
# INIZIALIZZAZIONE
# ========================================

## Dati temporanei del personaggio in fase di creazione
var _pending_character_data: Dictionary = {}

func _ready() -> void:
	# L'inizializzazione del personaggio è stata spostata in MainGame.gd
	_connect_time_manager_signals()
	print("PlayerManager pronto, in attesa di ordini.")

## Prepara i dati di un nuovo personaggio senza applicarli allo stato attivo
## @return: Dictionary con i dati generati (stats, max_hp, hp)
func prepare_new_character_data() -> Dictionary:
	print("▶️ PlayerManager: Preparazione dati nuovo personaggio")
	
	# GENERAZIONE CASUALE STATISTICHE
	var new_stats = _generate_initial_stats()
	
	# CALCOLO HP DINAMICO BASATO SU VIGORE
	var new_max_hp = _calculate_max_hp(new_stats.vigore)
	
	# Salva i dati in variabile temporanea
	_pending_character_data = {
		"stats": new_stats,
		"max_hp": new_max_hp,
		"hp": new_max_hp
	}
	
	print("✅ PlayerManager: Dati personaggio preparati (non ancora applicati)")
	return _pending_character_data

## Applica i dati pendenti allo stato reale del giocatore
func finalize_character_creation() -> void:
	print("▶️ PlayerManager: Finalizzazione creazione personaggio")
	
	# Applica i dati pendenti allo stato reale del giocatore
	self.stats = _pending_character_data.stats
	self.max_hp = _pending_character_data.max_hp
	self.hp = _pending_character_data.hp
	
	# RISORSE SOPRAVVIVENZA DI DEFAULT
	food = 100
	max_food = 100
	water = 100
	max_water = 100
	
	# INVENTARIO E EQUIPAGGIAMENTO VUOTI
	inventory.clear()
	equipped_weapon.clear()
	equipped_armor.clear()
	
	# Pulisci i dati temporanei
	_pending_character_data.clear()
	
	print("✅ PlayerManager: Creazione personaggio finalizzata")
	
	# Emetti i segnali per aggiornare la UI
	stats_changed.emit()
	resources_changed.emit()

## Aggiunge oggetti di partenza per il nuovo sistema di gioco
## Set fisso: 2 bevande, 2 cibi, 2 cure, 1 arma base, 1 armatura base
func _add_starting_items() -> void:
	# Solo se DataManager è disponibile, aggiungi alcuni oggetti base
	if not DataManager:
		print("   ⚠️ DataManager non disponibile - inventario vuoto")
		return
	
	# Set fisso di oggetti iniziali (8 oggetti totali, 2 slot liberi)
	var starting_items = [
		# 2 oggetti da bere
		{"item_id": "water_purified", "quantity": 1},
		{"item_id": "water_purified", "quantity": 1},
		# 2 oggetti da mangiare
		{"item_id": "ration_pack", "quantity": 1},
		{"item_id": "ration_pack", "quantity": 1},
		# 2 oggetti di cura
		{"item_id": "bandages_clean", "quantity": 1},
		{"item_id": "bandages_clean", "quantity": 1},
		# 1 arma base
		{"item_id": "weapon_knife_rusty", "quantity": 1},
		# 1 armatura base
		{"item_id": "armor_rags", "quantity": 1}
	]
	
	print("   📦 Aggiunta set iniziale di oggetti...")
	for starting_item in starting_items:
		if DataManager.has_item(starting_item.item_id):
			add_item(starting_item.item_id, starting_item.quantity)
		else:
			print("   ⚠️ Oggetto di partenza non trovato: %s" % starting_item.item_id)
	
	print("   ✅ Set iniziale completato: %d/%d slot occupati" % [inventory.size(), MAX_INVENTORY_SLOTS])

# ========================================
# GENERAZIONE CASUALE PERSONAGGIO (M3.T3.5)
# ========================================

## Genera un singolo valore di statistica usando il metodo 4d6 drop lowest
## Lancia 4 dadi a 6 facce e somma i 3 più alti
## @return: Valore statistica compreso tra 3 e 18
func _roll_one_stat() -> int:
	var rolls = []
	
	# Lancia 4 dadi a 6 facce
	for i in 4:
		rolls.append(randi_range(1, 6))
	
	# Ordina i risultati
	rolls.sort()
	
	# Rimuove il tiro più basso (primo elemento dopo sort)
	rolls.remove_at(0)
	
	# Somma i 3 risultati rimanenti
	return rolls[0] + rolls[1] + rolls[2]

## Genera tutte le statistiche del personaggio con vincoli tematici
## Ultimo è un sopravvissuto: non forte fisicamente ma agile e percettivo
## @return: Dictionary con le 6 statistiche assegnate secondo i vincoli
func _generate_initial_stats() -> Dictionary:
	# Genera 6 valori statistici casuali
	var raw_values = []
	for i in 6:
		raw_values.append(_roll_one_stat())
	
	# Ordina i valori per identificare high/low
	var sorted_values = raw_values.duplicate()
	sorted_values.sort()
	
	# Identifica i range di valori
	var lowest_two = [sorted_values[0], sorted_values[1]]
	var middle_two = [sorted_values[2], sorted_values[3]]
	var highest_two = [sorted_values[4], sorted_values[5]]
	
	# Applica vincoli tematici per "Ultimo il Sopravvissuto"
	var generated_stats = {}
	
	# FORZA: Deve ricevere uno dei due valori più bassi
	generated_stats["forza"] = lowest_two[randi_range(0, 1)]
	
	# AGILITA e INTELLIGENZA: Devono ricevere i due valori più alti
	var high_shuffle = highest_two.duplicate()
	high_shuffle.shuffle()
	generated_stats["agilita"] = high_shuffle[0]
	generated_stats["intelligenza"] = high_shuffle[1]
	
	# VIGORE, CARISMA, FORTUNA: Ricevono i valori di mezzo e il low rimanente
	var remaining_values = middle_two.duplicate()
	remaining_values.append(lowest_two[1] if generated_stats["forza"] == lowest_two[0] else lowest_two[0])
	remaining_values.shuffle()
	
	generated_stats["vigore"] = remaining_values[0]
	generated_stats["carisma"] = remaining_values[1]
	generated_stats["fortuna"] = remaining_values[2]
	
	print("   🎲 Statistiche generate - Forza: %d (low), Agilità: %d (high), Intelligenza: %d (high)" % [generated_stats["forza"], generated_stats["agilita"], generated_stats["intelligenza"]])
	print("   🎲 Vigore: %d, Carisma: %d, Fortuna: %d" % [generated_stats["vigore"], generated_stats["carisma"], generated_stats["fortuna"]])
	
	return generated_stats

## Calcola gli HP massimi basati sulla statistica Vigore
## Formula: 80 HP base + (Vigore * 2)
## @param vigore_stat: Valore della statistica vigore (tipicamente 3-18)
## @return: HP massimi calcolati (range 86-116)
func _calculate_max_hp(vigore_stat: int) -> int:
	var calculated_hp = 80 + (vigore_stat * 2)
	print("   💗 HP Massimi: %d (80 base + %d vigore * 2)" % [calculated_hp, vigore_stat])
	return calculated_hp

# ========================================
# API INVENTARIO
# ========================================

## Aggiunge un oggetto all'inventario
## @param item_id: ID univoco dell'oggetto (deve esistere in DataManager)
## @param quantity: Quantità da aggiungere (deve essere > 0)
## @return: true se aggiunto con successo, false altrimenti
func add_item(item_id: String, quantity: int) -> bool:
	if quantity <= 0:
		print("⚠️ PlayerManager: Quantità non valida: %d" % quantity)
		return false
	
	# Verifica che l'oggetto esista nel DataManager
	if not DataManager or not DataManager.has_item(item_id):
		print("❌ PlayerManager: Oggetto non trovato nel database: %s" % item_id)
		return false
	
	# Ottieni dati oggetto per verificare se è stackable e gestire porzioni
	var item_data = DataManager.get_item_data(item_id)
	var is_stackable = item_data.get("stackable", true)  # Default: stackable
	# CORREZIONE: accesso corretto a max_portions nelle properties
	var max_portions = 0
	if item_data.has("properties") and item_data.properties.has("max_portions"):
		max_portions = item_data.properties.max_portions
	else:
		# Fallback per retrocompatibilità (formato legacy)
		max_portions = item_data.get("max_portions", 0)
	
	# Cerca se l'oggetto è già nell'inventario
	var existing_slot = _find_inventory_slot(item_id)
	
	if existing_slot != -1 and is_stackable:
		# OGGETTO STACKABLE GIÀ PRESENTE: incrementa quantità
		inventory[existing_slot].quantity += quantity
		print("📦 Aggiunto %dx %s (stack esistente, totale: %d)" % [quantity, item_id, inventory[existing_slot].quantity])
	else:
		# NUOVO OGGETTO O NON STACKABLE: verifica limite inventario
		if inventory.size() >= MAX_INVENTORY_SLOTS:
			print("❌ PlayerManager: Inventario pieno! Limite massimo: %d oggetti" % MAX_INVENTORY_SLOTS)
			return false
		
		# Crea nuovo slot
		var instance_data = {}
		
		# Se l'oggetto ha max_portions, inizializza le porzioni
		if max_portions > 0:
			instance_data["portions"] = max_portions
			print("📦 Oggetto con porzioni: %s inizializzato con %d porzioni" % [item_id, max_portions])
		
		var new_slot = {
			"id": item_id,
			"quantity": quantity,
			"instance_data": instance_data
		}
		inventory.append(new_slot)
		print("📦 Aggiunto %dx %s (nuovo slot, %d/%d slot occupati)" % [quantity, item_id, inventory.size(), MAX_INVENTORY_SLOTS])
	
	# Emetti segnale di cambiamento
	inventory_changed.emit()
	return true

## Rimuove un oggetto dall'inventario
## @param item_id: ID oggetto da rimuovere
## @param quantity: Quantità da rimuovere (deve essere > 0)
## @return: true se rimosso con successo, false se non c'è abbastanza quantità
func remove_item(item_id: String, quantity: int) -> bool:
	if quantity <= 0:
		print("⚠️ PlayerManager: Quantità non valida: %d" % quantity)
		return false
	
	var slot_index = _find_inventory_slot(item_id)
	if slot_index == -1:
		print("⚠️ PlayerManager: Oggetto non presente nell'inventario: %s" % item_id)
		return false
	
	var current_quantity = inventory[slot_index].quantity
	if current_quantity < quantity:
		print("⚠️ PlayerManager: Quantità insufficiente per %s (disponibile: %d, richiesto: %d)" % [item_id, current_quantity, quantity])
		return false
	
	# Rimuovi quantità
	inventory[slot_index].quantity -= quantity
	
	# Se quantità = 0, rimuovi completamente lo slot
	if inventory[slot_index].quantity == 0:
		inventory.remove_at(slot_index)
		print("📦 Rimosso completamente %s dall'inventario" % item_id)
	else:
		print("📦 Rimosso %dx %s (rimanente: %d)" % [quantity, item_id, inventory[slot_index].quantity])
	
	# Emetti segnale di cambiamento
	inventory_changed.emit()
	return true

## Controlla se il giocatore ha un oggetto specifico
## @param item_id: ID oggetto da cercare
## @return: true se presente (quantità > 0), false altrimenti
func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0

## Restituisce la quantità di un oggetto nell'inventario
## @param item_id: ID oggetto da contare
## @return: Quantità posseduta (0 se non presente)
func get_item_count(item_id: String) -> int:
	var slot_index = _find_inventory_slot(item_id)
	if slot_index != -1:
		return inventory[slot_index].quantity
	return 0

## Usa un oggetto dall'inventario (consumo con effetti e gestione porzioni)
## @param item_id: ID oggetto da usare
## @param quantity: Quantità da usare (default 1)
## @return: true se usato con successo, false altrimenti
func use_item(item_id: String, quantity: int = 1) -> bool:
	# Verifica che abbiamo l'oggetto
	if not has_item(item_id) or get_item_count(item_id) < quantity:
		print("⚠️ PlayerManager: Oggetto non disponibile o quantità insufficiente: %s" % item_id)
		return false
	
	# Ottieni dati oggetto per applicare effetti
	var item_data = DataManager.get_item_data(item_id)
	if not item_data:
		print("❌ PlayerManager: Dati oggetto non trovati: %s" % item_id)
		return false
	
	# Trova slot inventario per gestione porzioni
	var slot_index = _find_inventory_slot(item_id)
	if slot_index == -1:
		print("❌ PlayerManager: Errore interno - oggetto non trovato in inventario: %s" % item_id)
		return false
	
	var item_slot = inventory[slot_index]
	var has_portions = item_slot.instance_data.has("portions")
	
	# Applica effetti basati sulla categoria oggetto
	var category = item_data.get("category", "UNKNOWN")
	var item_name = item_data.get("name", item_id)
	
	match category:
		"CONSUMABLE":
			_apply_consumable_effects(item_data, quantity)
		"WEAPON":
			print("⚠️ Armi non possono essere 'usate' direttamente. Usa equip_weapon()")
			return false
		"ARMOR":
			print("⚠️ Armature non possono essere 'usate' direttamente. Usa equip_armor()")
			return false
		_:
			print("⚠️ Categoria oggetto non gestita per uso: %s" % category)
			# Per oggetti senza effetti, li gestiamo comunque
	
	# GESTIONE PORZIONI: Se l'oggetto ha porzioni, decrementa invece di rimuovere
	if has_portions:
		item_slot.instance_data.portions -= 1
		
		print("🍽️ Usata porzione di %s (%d porzioni rimanenti)" % [item_name, item_slot.instance_data.portions])
		
		# Solo se le porzioni raggiungono 0, rimuovi l'oggetto
		if item_slot.instance_data.portions <= 0:
			if not remove_item(item_id, quantity):
				print("❌ PlayerManager: Errore rimozione oggetto esaurito: %s" % item_id)
				return false
			print("📦 %s completamente consumato e rimosso dall'inventario" % item_name)
		else:
			# Emetti segnale per aggiornare UI (porzioni cambiate)
			inventory_changed.emit()
	else:
		# LOGICA NORMALE: Rimuovi oggetto dall'inventario (consumo standard)
		if not remove_item(item_id, quantity):
			print("❌ PlayerManager: Errore rimozione oggetto dopo uso: %s" % item_id)
			return false
	
	print("✅ Usato %dx %s" % [quantity, item_name])
	
	# Emetti messaggio narrativo per il diario
	_emit_narrative_message_for_use(item_data, quantity)
	
	return true

## Applica gli effetti di un oggetto consumabile
## @param item_data: Dati completi dell'oggetto
## @param quantity: Quantità usata (per moltiplicare effetti)
func _apply_consumable_effects(item_data: Dictionary, quantity: int) -> void:
	# Cerca gli effetti sia nel campo diretto che nelle properties
	var effects = []
	if item_data.has("effects"):
		effects = item_data.effects
	elif item_data.has("properties") and item_data.properties.has("effects"):
		effects = item_data.properties.effects
	
	var effects_applied = []
	
	# Itera through array of effects
	for effect in effects:
		var effect_type = effect.get("effect_type", "")
		var amount = effect.get("amount", 0)
		
		match effect_type:
			"heal":
				modify_hp(amount * quantity)
				effects_applied.append("Cura: +%d HP" % (amount * quantity))
			"nourish":
				modify_food(amount * quantity)
				effects_applied.append("Nutrimento: +%d Food" % (amount * quantity))
			"hydrate":
				modify_water(amount * quantity)
				effects_applied.append("Idratazione: +%d Water" % (amount * quantity))
			"restore_stamina":
				# Placeholder per stamina quando implementata
				effects_applied.append("Stamina: +%d (placeholder)" % (amount * quantity))
			"add_radiation":
				# Placeholder per radiazioni quando implementate
				effects_applied.append("Radiazioni: +%d (placeholder)" % (amount * quantity))
			"infection_chance", "poison_chance":
				# Placeholder per effetti negativi probabilistici
				var chance = effect.get("chance", 0.0)
				effects_applied.append("Rischio %s: %.1f%%" % [effect_type.replace("_chance", ""), chance * 100])
			_:
				print("⚠️ Effetto non gestito: %s" % effect_type)
	
	if effects_applied.size() > 0:
		print("⚡ Effetti applicati da %s (x%d): %s" % [item_data.get("name", "oggetto"), quantity, ", ".join(effects_applied)])
	else:
		print("⚡ Nessun effetto applicabile da %s" % item_data.get("name", "oggetto"))

## Trova l'indice dello slot inventario contenente l'oggetto specificato
## @param item_id: ID oggetto da cercare
## @return: Indice slot (0-based) o -1 se non trovato
func _find_inventory_slot(item_id: String) -> int:
	for i in range(inventory.size()):
		# HOTFIX: Usa .get("id") per evitare crash se un oggetto non ha un ID.
		if inventory[i].get("id") == item_id:
			return i
	return -1

## Equipaggia un oggetto (arma o armatura)
## @param item_id: ID oggetto da equipaggiare
## @return: true se equipaggiato con successo, false altrimenti
func equip_item(item_id: String) -> bool:
	# Verifica che abbiamo l'oggetto
	if not has_item(item_id):
		print("⚠️ PlayerManager: Oggetto non disponibile per equipaggiamento: %s" % item_id)
		return false
	
	# Ottieni dati oggetto
	var item_data = DataManager.get_item_data(item_id)
	if not item_data:
		print("❌ PlayerManager: Dati oggetto non trovati: %s" % item_id)
		return false
	
	var category = item_data.get("category", "UNKNOWN")
	var item_name = item_data.get("name", item_id)
	
	# Equipaggia basandoti sulla categoria
	match category:
		"WEAPON":
			# Rimuovi arma equipaggiata precedente (se presente)
			if not equipped_weapon.is_empty():
				var old_weapon_name = equipped_weapon.get("name", "Arma precedente")
				print("🔄 Disequipaggiando: %s" % old_weapon_name)
				# Potresti voler rimettere l'arma precedente nell'inventario in futuro
			
			# Equipaggia nuova arma
			equipped_weapon = item_data.duplicate()
			print("⚔️ Arma equipaggiata: %s" % item_name)
			
		"ARMOR":
			# Rimuovi armatura equipaggiata precedente (se presente)
			if not equipped_armor.is_empty():
				var old_armor_name = equipped_armor.get("name", "Armatura precedente")
				print("🔄 Disequipaggiando: %s" % old_armor_name)
				# Potresti voler rimettere l'armatura precedente nell'inventario in futuro
			
			# Equipaggia nuova armatura
			equipped_armor = item_data.duplicate()
			print("🛡️ Armatura equipaggiata: %s" % item_name)
			
		_:
			print("⚠️ PlayerManager: Categoria oggetto non equipaggiabile: %s (%s)" % [item_name, category])
			return false
	
	# Rimuovi oggetto dall'inventario (è ora equipaggiato)
	if not remove_item(item_id, 1):
		print("❌ PlayerManager: Errore rimozione oggetto dopo equipaggiamento: %s" % item_id)
		return false
	
	# Emetti segnali di aggiornamento
	inventory_changed.emit()
	
	# Emetti messaggio narrativo
	var narrative_message = _get_narrative_message_for_equip(item_data)
	narrative_log_generated.emit(narrative_message)
	
	print("✅ Equipaggiato %s" % item_name)
	return true

## Genera messaggio narrativo per equipaggiamento
func _get_narrative_message_for_equip(item_data: Dictionary) -> String:
	var item_name = item_data.get("name", "oggetto")
	var category = item_data.get("category", "")
	
	match category:
		"WEAPON":
			return "Afferri saldamente %s. Ti senti più sicuro con un'arma in mano." % item_name
		"ARMOR":
			return "Indossi %s. La protezione aggiuntiva ti fa sentire più preparato." % item_name
		_:
			return "Hai equipaggiato: %s" % item_name

## Emette messaggio narrativo per l'uso di oggetti
func _emit_narrative_message_for_use(item_data: Dictionary, _quantity: int) -> void:
	var item_name = item_data.get("name", "oggetto")
	var category = item_data.get("category", "")
	
	# Cerca gli effetti sia nel campo diretto che nelle properties
	var effects = []
	if item_data.has("effects"):
		effects = item_data.effects
	elif item_data.has("properties") and item_data.properties.has("effects"):
		effects = item_data.properties.effects
	
	var narrative_message = ""
	
	match category:
		"CONSUMABLE":
			# Messaggio specifico basato sugli effetti
			var has_hydrate = false
			var has_heal = false
			var has_nourish = false
			
			for effect in effects:
				match effect.get("effect_type", ""):
					"hydrate":
						has_hydrate = true
					"heal":
						has_heal = true
					"nourish":
						has_nourish = true
			
			# Messaggi narrativi specifici
			if has_hydrate and item_name.to_lower().contains("acqua"):
				narrative_message = "Bevi un sorso d'acqua. Ti senti rinfrescato e l'arsura si placa."
			elif has_heal and item_name.to_lower().contains("medicina"):
				narrative_message = "Applichi le medicine alle tue ferite. Il dolore si attenua."
			elif has_nourish and item_name.to_lower().contains("razione"):
				narrative_message = "Mangi la razione militare. Non è appetitosa, ma placa la fame."
			else:
				# Messaggio generico
				narrative_message = "Usi %s. Ti senti leggermente meglio." % item_name
		_:
			# Altri tipi di oggetti
			narrative_message = "Hai usato: %s" % item_name
	
	# Emetti il messaggio narrativo
	narrative_log_generated.emit(narrative_message)

# ========================================
# API RISORSE VITALI
# ========================================

## Modifica i punti vita del giocatore
## @param amount: Quantità da aggiungere (negativo per danno)
## @param allow_overheal: Se true, permette di superare max_hp
func modify_hp(amount: int, allow_overheal: bool = false) -> void:
	var old_hp = hp
	hp += amount
	
	if not allow_overheal and hp > max_hp:
		hp = max_hp
	elif hp < 0:
		hp = 0
	
	if hp != old_hp:
		print("❤️ HP: %d → %d (%+d)" % [old_hp, hp, amount])
		resources_changed.emit()

## Modifica il livello di fame
## @param amount: Quantità da aggiungere (negativo per perdere cibo)
func modify_food(amount: int) -> void:
	var old_food = food
	food = clamp(food + amount, 0, max_food)
	
	if food != old_food:
		print("🍖 Food: %d → %d (%+d)" % [old_food, food, amount])
		resources_changed.emit()

## Modifica il livello di sete
## @param amount: Quantità da aggiungere (negativo per perdere acqua)
func modify_water(amount: int) -> void:
	var old_water = water
	water = clamp(water + amount, 0, max_water)
	
	if water != old_water:
		print("💧 Water: %d → %d (%+d)" % [old_water, water, amount])
		resources_changed.emit()

# ========================================
# API STATISTICHE
# ========================================

## Modifica una statistica del personaggio
## @param stat_name: Nome statistica ("forza", "agilita", etc.)
## @param amount: Quantità da aggiungere (può essere negativo)
func modify_stat(stat_name: String, amount: int) -> void:
	if not stats.has(stat_name):
		print("⚠️ PlayerManager: Statistica non riconosciuta: %s" % stat_name)
		return
	
	var old_value = stats[stat_name]
	stats[stat_name] = max(0, stats[stat_name] + amount)  # Min 0
	
	if stats[stat_name] != old_value:
		print("📈 %s: %d → %d (%+d)" % [stat_name.capitalize(), old_value, stats[stat_name], amount])
		stats_changed.emit()

## Ottiene il valore di una statistica
## @param stat_name: Nome statistica
## @return: Valore corrente della statistica (0 se non esiste)
func get_stat(stat_name: String) -> int:
	return stats.get(stat_name, 0)

# ========================================
# API DEBUG E UTILITÀ
# ========================================

## Stampa un report completo dello stato del personaggio
func print_character_status() -> void:
	print("\n" + "=".repeat(40))
	print("👤 PLAYER STATUS REPORT")
	print("=".repeat(40))
	print("❤️ HP: %d/%d (%.1f%%)" % [hp, max_hp, (float(hp)/max_hp)*100])
	print("🍖 Food: %d/%d (%.1f%%)" % [food, max_food, (float(food)/max_food)*100])
	print("💧 Water: %d/%d (%.1f%%)" % [water, max_water, (float(water)/max_water)*100])
	print("\n📊 STATISTICHE:")
	for stat_name in stats:
		print("   %s: %d" % [stat_name.capitalize(), stats[stat_name]])
	print("\n📦 INVENTARIO (%d oggetti):" % inventory.size())
	for slot in inventory:
		var portions_info = ""
		if slot.instance_data.has("portions"):
			portions_info = " (%d porzioni)" % slot.instance_data.portions
		print("   %dx %s%s" % [slot.quantity, slot.id, portions_info])
	print("=".repeat(40) + "\n")

## Restituisce un Dictionary con tutto lo stato del personaggio (per salvataggio)
## @return: Dictionary completo con tutti i dati del personaggio
func get_save_data() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,
		"food": food,
		"max_food": max_food,
		"water": water,
		"max_water": max_water,
		"stats": stats.duplicate(),
		"inventory": inventory.duplicate(true),
		"equipped_weapon": equipped_weapon.duplicate(),
		"equipped_armor": equipped_armor.duplicate(),
		# M3.T1: Dati progressione per salvataggio
		"experience": experience,
		"experience_for_next_point": experience_for_next_point,
		"available_stat_points": available_stat_points,
		# Sistema narrativo
		"understanding_level": understanding_level,
		"character_empathy": character_empathy.duplicate(),
		"memory_strength": memory_strength.duplicate(),
		"total_wisdom": total_wisdom,
		"current_emotional_state": current_emotional_state
	}

## Carica lo stato del personaggio da un Dictionary (per caricamento salvataggio)
## @param save_data: Dictionary con dati del personaggio
func load_save_data(save_data: Dictionary) -> void:
	hp = save_data.get("hp", 100)
	max_hp = save_data.get("max_hp", 100)
	food = save_data.get("food", 100)
	max_food = save_data.get("max_food", 100)
	water = save_data.get("water", 100)
	max_water = save_data.get("max_water", 100)
	stats = save_data.get("stats", {})
	inventory = save_data.get("inventory", [])
	equipped_weapon = save_data.get("equipped_weapon", {})
	equipped_armor = save_data.get("equipped_armor", {})

	# M3.T1: Carica dati progressione
	experience = save_data.get("experience", 0)
	experience_for_next_point = save_data.get("experience_for_next_point", 100)
	available_stat_points = save_data.get("available_stat_points", 0)

	# Sistema narrativo
	understanding_level = save_data.get("understanding_level", 0)
	character_empathy = save_data.get("character_empathy", {})
	memory_strength = save_data.get("memory_strength", {})
	total_wisdom = save_data.get("total_wisdom", 0)
	current_emotional_state = save_data.get("current_emotional_state", 0)

	# Emetti segnali per aggiornare UI
	resources_changed.emit()
	stats_changed.emit()
	inventory_changed.emit()

	print("✅ PlayerManager: Dati caricati da salvataggio (inclusa progressione e stato emotivo)")

# ========================================
# API SISTEMA PROGRESSIONE (M3.T1)
# ========================================

## Aggiunge esperienza al personaggio e gestisce livellamento automatico
## @param amount: Quantità di esperienza da aggiungere
## @param reason: Motivo del guadagno (opzionale, per log narrativo)
func add_experience(amount: int, reason: String = "") -> void:
	if amount <= 0:
		print("⚠️ PlayerManager: Quantità esperienza non valida: %d" % amount)
		return
	
	# Incrementa esperienza
	experience += amount
	
	# Log solo in console per evitare spam nel diario
	print("⭐ Esperienza: +%d (totale: %d)" % [amount, experience])
	if reason != "":
		print("   Motivo: %s" % reason)
	
	# Controlla se si ha abbastanza esperienza per nuovo punto statistica
	while experience >= experience_for_next_point:
		_level_up()

## Gestisce il livellamento quando si raggiunge la soglia di esperienza
func _level_up() -> void:
	# Sottrai esperienza usata per livellamento
	experience -= experience_for_next_point
	
	# Calcola livello attuale dopo il livellamento
	var current_level = _calculate_current_level()
	
	# Incrementa punti disponibili SOLO dal livello 2 in poi
	if current_level >= 2:
		available_stat_points += 1
		var level_msg = "[color=yellow]Sei diventato più esperto! Hai un nuovo punto statistica da spendere.[/color]"
		narrative_log_generated.emit(level_msg)
		print("🎉 LIVELLAMENTO! Livello: %d, Punti disponibili: %d" % [current_level, available_stat_points])
	else:
		# Livello 1 -> 2: solo messaggio di livellamento senza punti
		var level_msg = "[color=cyan]Hai raggiunto il livello 2! Dal prossimo livellamento riceverai punti statistica.[/color]"
		narrative_log_generated.emit(level_msg)
		print("🎉 LIVELLAMENTO! Livello: %d (nessun punto assegnato)" % current_level)
	
	# Aumenta soglia per prossimo livellamento (progressione crescente)
	experience_for_next_point = int(experience_for_next_point * 1.5)
	
	# Emetti segnale per aggiornare UI statistiche
	stats_changed.emit()

## Spende un punto statistica per migliorare una statistica
## @param stat_name: Nome della statistica da migliorare
## @return: true se miglioramento riuscito, false altrimenti
func improve_stat(stat_name: String) -> bool:
	# Verifica punti disponibili
	if available_stat_points <= 0:
		print("⚠️ PlayerManager: Nessun punto statistica disponibile")
		return false
	
	# Verifica che la statistica esista
	if not stats.has(stat_name):
		print("⚠️ PlayerManager: Statistica non riconosciuta per miglioramento: %s" % stat_name)
		return false
	
	# Decrementa punti disponibili
	available_stat_points -= 1
	
	# Incrementa statistica
	var old_value = stats[stat_name]
	stats[stat_name] += 1
	
	# Messaggio narrativo per miglioramento
	var stat_display_name = stat_name.capitalize()
	match stat_name:
		"forza":
			stat_display_name = "Forza"
		"agilita":
			stat_display_name = "Agilità"
		"intelligenza":
			stat_display_name = "Intelligenza"
		"carisma":
			stat_display_name = "Carisma"
		"fortuna":
			stat_display_name = "Fortuna"
	
	var improvement_msg = "[color=cyan]%s migliorata: %d → %d[/color]" % [stat_display_name, old_value, stats[stat_name]]
	narrative_log_generated.emit(improvement_msg)
	
	print("📈 Statistica migliorata: %s %d → %d (punti rimanenti: %d)" % [
		stat_name, old_value, stats[stat_name], available_stat_points
	])
	
	# Emetti segnale per aggiornare UI
	stats_changed.emit()
	
	return true

## Restituisce se il giocatore ha punti statistica da spendere
## @return: true se ha punti disponibili, false altrimenti
func has_available_stat_points() -> bool:
	return available_stat_points > 0

## Calcola il livello attuale basato sull'esperienza totale
## @return: Livello attuale del personaggio (inizia da 1)
func _calculate_current_level() -> int:
	# Sistema AD&D: inizia da livello 1, ogni 100/150/225... EXP sale di livello
	if experience < 100:
		return 1
	elif experience < 250:  # 100 + 150
		return 2
	elif experience < 475:  # 100 + 150 + 225
		return 3
	elif experience < 812:  # ... + 337
		return 4
	elif experience < 1318:  # ... + 506
		return 5
	else:
		# Per livelli alti, approssimazione
		return 5 + int((experience - 1318) / 600.0)  # Incremento di ~600 EXP per livello

## Calcola la soglia di esperienza richiesta per raggiungere un livello specifico
## @param target_level: Livello target per cui calcolare la soglia
## @return: Esperienza totale richiesta per raggiungere quel livello
func _get_experience_threshold_for_level(target_level: int) -> int:
	match target_level:
		1:
			return 0
		2:
			return 100
		3:
			return 250  # 100 + 150
		4:
			return 475  # 100 + 150 + 225
		5:
			return 812  # ... + 337
		6:
			return 1318  # ... + 506
		_:
			# Per livelli alti, approssimazione
			return 1318 + ((target_level - 6) * 600)

## Ottiene informazioni complete sul sistema di progressione
## @return: Dictionary con tutti i dati di progressione
func get_progression_data() -> Dictionary:
	var current_level = _calculate_current_level()
	var next_level_threshold = _get_experience_threshold_for_level(current_level + 1)
	
	return {
		"experience": experience,
		"experience_for_next_point": experience_for_next_point,
		"available_stat_points": available_stat_points,
		"experience_to_next_level": next_level_threshold - experience,
		"current_level": current_level,
		"next_level_threshold": next_level_threshold
	}

# ========================================
# SISTEMA SOPRAVVIVENZA (M3.T2)
# ========================================

## Applica penalità automatiche di sopravvivenza (collegato a TimeManager)
## Viene chiamato ogni sera alle 19:00 dal segnale survival_penalty_tick
func apply_survival_penalties() -> void:
	print("💀 Applicazione penalità sopravvivenza notturne...")
	
	# PENALITÀ FAME: -10 food ogni notte
	var food_loss = -10
	modify_food(food_loss)
	narrative_log_generated.emit("La fame ti consuma. Perdi %d punti cibo." % abs(food_loss))
	
	# PENALITÀ SETE: -15 water ogni notte
	var water_loss = -15
	modify_water(water_loss)
	narrative_log_generated.emit("La sete si fa sentire. Perdi %d punti acqua." % abs(water_loss))
	
	# CONTROLLO STATO CRITICO: Se food o water sono a 0, danno HP
	_check_critical_survival_damage()
	
	print("💀 Penalità sopravvivenza applicate: Food %d, Water %d" % [food_loss, water_loss])

## Controlla se applicare danno critico per fame/sete azzerata
func _check_critical_survival_damage() -> void:
	var damage_taken = false
	
	# DANNO DA FAME CRITICA: Se food = 0, -20 HP
	if food <= 0:
		var hunger_damage = -20
		modify_hp(hunger_damage)
		narrative_log_generated.emit("[color=red]La fame estrema ti debilita gravemente! Perdi %d HP.[/color]" % abs(hunger_damage))
		damage_taken = true
		print("💀 FAME CRITICA: %d danni HP" % abs(hunger_damage))
	
	# DANNO DA SETE CRITICA: Se water = 0, -25 HP
	if water <= 0:
		var thirst_damage = -25
		modify_hp(thirst_damage)
		narrative_log_generated.emit("[color=red]La disidratazione ti uccide lentamente! Perdi %d HP.[/color]" % abs(thirst_damage))
		damage_taken = true
		print("💀 SETE CRITICA: %d danni HP" % abs(thirst_damage))
	
	# AVVISO GAME OVER se HP troppo bassi
	if damage_taken and hp <= 25:
		narrative_log_generated.emit("[color=yellow]⚠️ I tuoi HP sono criticamente bassi! Trova cibo e acqua subito![/color]")
		print("⚠️ AVVISO: HP critici (%d), sopravvivenza in pericolo!" % hp)

## Connette i segnali TimeManager per automazione sopravvivenza
func _connect_time_manager_signals() -> void:
	if not TimeManager:
		print("⚠️ PlayerManager: TimeManager non disponibile per connessione segnali")
		return
	
	# Connetti segnale penalità sopravvivenza (ogni sera alle 19:00)
	if not TimeManager.survival_penalty_tick.is_connected(_on_survival_penalty_tick):
		TimeManager.survival_penalty_tick.connect(_on_survival_penalty_tick)
		print("✅ PlayerManager: Connesso a TimeManager.survival_penalty_tick")

## Callback per segnale penalità sopravvivenza da TimeManager
func _on_survival_penalty_tick() -> void:
	print("⏰ PlayerManager: Ricevuto segnale penalità sopravvivenza")
	apply_survival_penalties()

# ========================================
# API GESTIONE STATI PERSONAGGIO (M3.T3)
# ========================================

## Aggiunge uno stato al personaggio se non già presente
## @param new_status: Stato da aggiungere al personaggio
func add_status(new_status: Status) -> void:
	# Controlla se lo stato è già presente
	if new_status in active_statuses:
		print("⚠️ PlayerManager: Stato %s già presente" % Status.keys()[new_status])
		return
	
	# Aggiungi lo stato all'array
	active_statuses.append(new_status)
	
	# Messaggio narrativo appropriato per ogni stato
	var status_message = ""
	match new_status:
		Status.WOUNDED:
			status_message = "Una ferita profonda inizia a sanguinare."
		Status.SICK:
			status_message = "Ti senti febbricitante."
		Status.POISONED:
			status_message = "Il veleno inizia a scorrere nelle tue vene."
		Status.NORMAL:
			status_message = "Ti senti in forma normale."
	
	# Emetti messaggio narrativo e segnali di aggiornamento
	narrative_log_generated.emit(status_message)
	stats_changed.emit()
	
	print("🩺 PlayerManager: Aggiunto stato %s" % Status.keys()[new_status])

## Rimuove uno stato dal personaggio se presente
## @param status_to_remove: Stato da rimuovere dal personaggio
func remove_status(status_to_remove: Status) -> void:
	# Controlla se lo stato è presente
	if not status_to_remove in active_statuses:
		print("⚠️ PlayerManager: Stato %s non presente" % Status.keys()[status_to_remove])
		return
	
	# Rimuovi lo stato dall'array
	active_statuses.erase(status_to_remove)
	
	# Messaggio narrativo di guarigione/rimozione
	var recovery_message = ""
	match status_to_remove:
		Status.WOUNDED:
			recovery_message = "Le tue ferite si sono rimarginate."
		Status.SICK:
			recovery_message = "Ti senti meglio, la febbre è passata."
		Status.POISONED:
			recovery_message = "Il veleno è stato neutralizzato."
		Status.NORMAL:
			recovery_message = "Mantieni la tua condizione normale."
	
	# Emetti messaggio narrativo e segnali di aggiornamento
	narrative_log_generated.emit(recovery_message)
	stats_changed.emit()
	
	print("🩺 PlayerManager: Rimosso stato %s" % Status.keys()[status_to_remove])

## Rimuove tutti gli stati attivi e ripristina condizione normale
func clear_all_statuses() -> void:
	if active_statuses.is_empty():
		print("ℹ️ PlayerManager: Nessuno stato da rimuovere, già normale")
		return
	
	print("🩺 PlayerManager: Rimozione stati in corso...")
	
	# Approccio sicuro: rimuovi stati uno per uno invece di clear()
	var count = active_statuses.size()
	while not active_statuses.is_empty():
		active_statuses.pop_back()
	
	print("🩺 PlayerManager: Rimossi %d stati attivi" % count)
	
	# Messaggio narrativo di ripristino completo
	narrative_log_generated.emit("Ti senti completamente ristabilito, tutti i disturbi sono svaniti.")
	stats_changed.emit()
	
	print("🩺 PlayerManager: Tutti gli stati rimossi, condizione normale ripristinata")

# ========================================
# SISTEMA SKILL CHECK (M3.T1 - FASE 1)
# ========================================

## Esegue un test di abilità D&D-style
## @param stat_name: Nome della statistica da testare ("forza", "agilita", "intelligenza", "carisma", "fortuna")
## @param difficulty: Classe di difficoltà del test (10=Facile, 15=Medio, 20=Difficile)
## @param modifier: Modificatore situazionale aggiuntivo (default 0)
## @return: Dictionary con risultato completo del test
func skill_check(stat_name: String, difficulty: int, modifier: int = 0) -> Dictionary:
	# Validazione parametri
	if not stats.has(stat_name):
		print("❌ PlayerManager: Statistica '%s' non trovata" % stat_name)
		return {
			"success": false,
			"error": "Statistica non valida: %s" % stat_name,
			"roll": 0,
			"total": 0,
			"difficulty": difficulty,
			"stat_used": stat_name,
			"stat_value": 0,
			"modifier": modifier
		}
	
	# Ottieni valore statistica e calcola modificatore D&D
	var stat_value = stats[stat_name]
	var stat_modifier = get_stat_modifier(stat_value)
	
	# Lancia 1d20
	var roll = roll_d20()
	
	# Calcola totale: 1d20 + modificatore statistica + modificatore situazionale
	var total = roll + stat_modifier + modifier
	
	# Determina successo
	var success = total >= difficulty
	
	# Crea risultato completo
	var result = {
		"success": success,
		"roll": roll,
		"total": total,
		"difficulty": difficulty,
		"stat_used": stat_name,
		"stat_value": stat_value,
		"stat_modifier": stat_modifier,
		"situational_modifier": modifier
	}
	
	# Log del test per debug
	print("🎲 Skill Check [%s]: %dd20=%d + stat_mod=%d + sit_mod=%d = %d vs DC%d → %s" % [
		stat_name.to_upper(),
		roll,
		stat_modifier,
		modifier,
		total,
		difficulty,
		"SUCCESS" if success else "FAILURE"
	])
	
	return result

## Calcola il modificatore D&D per una statistica
## Usa la formula standard D&D: (valore - 10) / 2 arrotondato per difetto
## @param stat_value: Valore della statistica (3-18)
## @return: Modificatore D&D (-4 a +4)
func get_stat_modifier(stat_value: int) -> int:
	return int((stat_value - 10) / 2.0)

## Lancia un dado a 20 facce
## @return: Valore casuale tra 1 e 20
func roll_d20() -> int:
	return randi_range(1, 20)

## Applica le conseguenze di un skill check agli eventi
## Questa funzione sarà utilizzata dall'EventManager per processare i risultati
## @param check_result: Risultato del skill check da skill_check()
## @param consequences: Dictionary con conseguenze successo/fallimento
func apply_skill_check_result(check_result: Dictionary, consequences: Dictionary) -> void:
	if not check_result.has("success"):
		print("❌ PlayerManager: Risultato skill check non valido")
		return
	
	# Seleziona conseguenze appropriate
	var outcome = consequences.get("success" if check_result.success else "failure", {})
	
	# Applica modifiche risorse
	if outcome.has("hp_change"):
		modify_hp(outcome.hp_change)
	
	if outcome.has("food_change"):
		modify_food(outcome.food_change)
	
	if outcome.has("water_change"):
		modify_water(outcome.water_change)
	
	# Applica oggetti ottenuti
	if outcome.has("items_gained"):
		for item in outcome.items_gained:
			if item.has("id"):
				add_item(item.id, item.get("quantity", 1))
				print("📦 Oggetto ottenuto: %dx %s" % [item.get("quantity", 1), item.id])
	
	# Applica stati
	if outcome.has("status_effects"):
		for status_name in outcome.status_effects:
			var status_enum = Status.get(status_name.to_upper())
			if status_enum != null:
				add_status(status_enum)
	
	# Messaggio narrativo
	if outcome.has("narrative_text"):
		narrative_log_generated.emit(outcome.narrative_text)
	
	print("✅ PlayerManager: Conseguenze skill check applicate")

## Applica una transazione di oggetti (aggiunta/rimozione multipla)
## @param transaction: Dictionary con formato {"add": [{"id": String, "quantity": int}], "remove": [{"id": String, "quantity": int}]}
## @return: bool - true se tutte le operazioni sono riuscite
func apply_item_transaction(transaction: Dictionary) -> bool:
	var success = true
	
	# Prima rimuovi gli oggetti (per verificare disponibilità)
	if transaction.has("remove"):
		for item_entry in transaction.remove:
			var item_id = item_entry.get("id", "")
			var quantity = item_entry.get("quantity", 1)
			if not remove_item(item_id, quantity):
				print("❌ PlayerManager: Transazione fallita - impossibile rimuovere %s (x%d)" % [item_id, quantity])
				success = false
				break
	
	# Poi aggiungi gli oggetti
	if success and transaction.has("add"):
		for item_entry in transaction.add:
			var item_id = item_entry.get("id", "")
			var quantity = item_entry.get("quantity", 1)
			if not add_item(item_id, quantity):
				print("❌ PlayerManager: Transazione fallita - impossibile aggiungere %s (x%d)" % [item_id, quantity])
				success = false
				break
	
	if success:
		print("✅ PlayerManager: Transazione oggetti completata con successo")
	else:
		print("❌ PlayerManager: Transazione oggetti fallita")
	
	return success
