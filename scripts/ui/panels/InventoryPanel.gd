extends PanelContainer

# Pannello Inventario (Left Panel)
@onready var inventory_list: VBoxContainer = $InventoryVBox/InventoryScroll/InventoryList

# ═══ VARIABILI INTERNE ═══

var selected_inventory_index: int = 0
var is_inventory_active: bool = false

# Colori per categorie oggetti (M2.T2.5) - Versione migliorata v0.3.5
# Colori più distintivi e contrastanti per migliore leggibilità
const CATEGORY_COLORS = {
	"weapon": "#FF4444",       # Rosso brillante per armi
	"armor": "#44AAFF",        # Blu brillante per armature
	"consumable": "#44FF44",   # Verde brillante per consumabili
	"unique": "#FFAA00",       # Arancione dorato per oggetti unici
	"crafting_material": "#AAAAAA", # Grigio chiaro per materiali
	"quest": "#AA44FF",        # Viola brillante per oggetti missione
	"ammo": "#FF8800",         # Arancione per munizioni
	"tool": "#00FFAA",         # Ciano per strumenti
	"accessory": "#FF44AA"     # Rosa per accessori
}

func _ready():
	if PlayerManager:
		PlayerManager.inventory_changed.connect(update_panel)
	if InputManager:
		InputManager.inventory_toggle.connect(_on_inventory_toggle)
		InputManager.inventory_navigate.connect(_on_inventory_navigate)
	update_panel()

func update_panel():
	"""Aggiorna pannello inventario dinamicamente con sistema di selezione"""
	# Verifica che inventory_list esista
	if not inventory_list:
		print("InventoryPanel: ❌ inventory_list è null")
		return
	
	# Step 1: Pulisci lista esistente
	clear_inventory_display()
	
	if not PlayerManager:
		var error_label = Label.new()
		error_label.text = "[ERROR] PlayerManager non disponibile"
		inventory_list.add_child(error_label)
		return
	
	# Step 2: Aggiungi ogni oggetto dell'inventario con selezione visuale - STILE ASCII PURO
	if PlayerManager.inventory.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "- Inventario vuoto -"
		inventory_list.add_child(empty_label)
		# Reset selezione se inventario vuoto
		selected_inventory_index = 0
	else:
		# Assicurati che selected_inventory_index sia valido
		if selected_inventory_index >= PlayerManager.inventory.size():
			selected_inventory_index = PlayerManager.inventory.size() - 1
		if selected_inventory_index < 0:
			selected_inventory_index = 0
			
		# Crea oggetti con indicatore selezione
		for i in range(PlayerManager.inventory.size()):
			var item = PlayerManager.inventory[i]
			var is_selected = (i == selected_inventory_index and is_inventory_active)
			add_inventory_item_to_display_with_selection(item, is_selected)
	
	print("InventoryPanel: ✅ Inventario aggiornato (%d oggetti) - Selezione: %d - Modalità attiva: %s" % [PlayerManager.inventory.size(), selected_inventory_index, is_inventory_active])

# ═══ UTILITY INVENTARIO ═══

func get_category_color(item_id: String) -> String:
	"""Restituisce il colore per la categoria dell'oggetto usando il sistema DataManager"""
	if not DataManager:
		return "#00FF40"  # Verde di default
	
	# Usa il nuovo sistema di colori del DataManager
	var color = DataManager.get_item_color(item_id)
	
	# Converte Color in stringa esadecimale
	return "#%02X%02X%02X" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]

func clear_inventory_display():
	"""Pulisce la lista inventario per aggiornamento"""
	for child in inventory_list.get_children():
		child.queue_free()

func add_inventory_item_to_display(item: Dictionary):
	"""Aggiunge un singolo oggetto alla visualizzazione inventario - STILE ASCII"""
	add_inventory_item_to_display_with_selection(item, false)

func add_inventory_item_to_display_with_selection(item: Dictionary, is_selected: bool):
	"""Aggiunge un singolo oggetto alla visualizzazione inventario con indicatore selezione e porzioni"""
	var item_label = RichTextLabel.new()
	item_label.bbcode_enabled = true
	item_label.fit_content = true
	item_label.scroll_active = false
	
	# HOTFIX: Usa .get("id") per evitare crash se un oggetto non ha un ID.
	var item_id = item.get("id", "oggetto_sconosciuto")

	# Ottieni dati oggetto dal DataManager (usando il nuovo campo "id")
	var item_data = DataManager.get_item_data(item_id)
	var item_name = item_data.get("name", item_id) if item_data else item_id
	
	# Calcola numero posizione oggetto nella lista (1-based per display)
	var item_index = -1
	for i in range(PlayerManager.inventory.size()):
		if PlayerManager.inventory[i] == item:
			item_index = i + 1  # Display 1-based (1, 2, 3...)
			break
	
	# Formatta testo con numerazione posizionale, porzioni e quantità
	var number_marker = "[%d]" % item_index if item_index > 0 else "[?]"
	var base_text = ""
	
	# Controlla se l'oggetto ha porzioni (instance_data.portions)
	var has_portions = item.instance_data.has("portions")
	var portions_info = ""
	
	if has_portions:
		var current_portions = item.instance_data.portions
		var max_portions = item_data.get("max_portions", current_portions) if item_data else current_portions
		portions_info = "(%d/%d)" % [current_portions, max_portions]
	
	# Costruisci il testo base con porzioni se presenti
	if item.quantity > 1:
		if has_portions:
			base_text = "%s %s %s x%d" % [number_marker, item_name, portions_info, item.quantity]
		else:
			base_text = "%s %s x%d" % [number_marker, item_name, item.quantity]
	else:
		if has_portions:
			base_text = "%s %s %s x%d" % [number_marker, item_name, portions_info, item.quantity]
		else:
			base_text = "%s %s" % [number_marker, item_name]
	
	# Ottieni colore per categoria
	var category_color = get_category_color(item_id)
	
	# Applica indicatore selezione con evidenziazione forte e colore categoria
	if is_selected:
		# Oggetto selezionato: sfondo del colore categoria, testo nero, bordato
		item_label.text = "[bgcolor=%s][color=#000000]> %s[/color][/bgcolor]" % [category_color, base_text]
	else:
		# Oggetto non selezionato: testo del colore categoria
		item_label.text = "[color=%s]  %s[/color]" % [category_color, base_text]
	
	inventory_list.add_child(item_label)

func _on_inventory_toggle():
	"""Callback: toggle modalità inventario"""
	is_inventory_active = !is_inventory_active
	
	if is_inventory_active:
		# Attiva modalità inventario
		InputManager.set_state(InputManager.InputState.INVENTORY)
		print("InventoryPanel: 🎒 Modalità inventario ATTIVATA")
		
		# PROBLEMA 1 RISOLTO: Evidenzia prima voce immediatamente
		if PlayerManager and PlayerManager.inventory.size() > 0:
			selected_inventory_index = 0  # Reset a prima voce
		
	else:
		# Disattiva modalità inventario
		InputManager.set_state(InputManager.InputState.MAP)
		print("InventoryPanel: 🗺️ Modalità mappa ATTIVATA")
		
		# PROBLEMA 2 RISOLTO: Reset evidenziazione quando si esce
		selected_inventory_index = 0
		
	# Aggiorna visual dell'inventario
	update_panel()

func _on_inventory_navigate(direction: Vector2i):
	"""Callback: navigazione inventario con WASD/frecce"""
	if not is_inventory_active:
		return  # Ignora se inventario non attivo
	
	if not PlayerManager or PlayerManager.inventory.size() == 0:
		return  # Nessun oggetto da navigare
	
	# Logica navigazione inventario
	if direction.y == -1:  # SU
		selected_inventory_index -= 1
		if selected_inventory_index < 0:
			selected_inventory_index = PlayerManager.inventory.size() - 1  # Wrap around all'ultimo
	elif direction.y == 1:  # GIÙ
		selected_inventory_index += 1
		if selected_inventory_index >= PlayerManager.inventory.size():
			selected_inventory_index = 0  # Wrap around al primo
	
	print("InventoryPanel: 🎯 Navigazione inventario: index %d" % selected_inventory_index)
	update_panel()  # Aggiorna evidenziazione