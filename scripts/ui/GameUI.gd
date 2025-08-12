extends Control

class_name GameUI

# ========================================
# SEGNALI
# ========================================
signal world_ready(world_instance: Node)

# ========================================
# SCENE PRECARICATE
# ========================================

const ItemInteractionPopup = preload("res://scenes/ui/popups/ItemInteractionPopup.tscn")
const LevelUpPopup = preload("res://scenes/ui/popups/LevelUpPopup.tscn")
const EventPopupScene = preload("res://scenes/ui/popups/EventPopup.tscn")
const CharacterCreationPopup = preload("res://scenes/ui/popups/CharacterCreationPopup.tscn")

# ═══ REFERENZE NODI PANNELLI ═══

@onready var survival_panel: PanelContainer = $MainLayout/ThreeColumnLayout/LeftPanel/SurvivalPanel
@onready var inventory_panel: PanelContainer = $MainLayout/ThreeColumnLayout/LeftPanel/InventoryPanel
@onready var log_panel: PanelContainer = $MainLayout/ThreeColumnLayout/CenterPanel/LogPanel
@onready var info_panel: PanelContainer = $MainLayout/ThreeColumnLayout/RightPanel/InfoPanel
@onready var stats_panel: PanelContainer = $MainLayout/ThreeColumnLayout/RightPanel/StatsPanel
@onready var equipment_panel: PanelContainer = $MainLayout/ThreeColumnLayout/RightPanel/EquipmentPanel
@onready var commands_panel: PanelContainer = $MainLayout/ThreeColumnLayout/RightPanel/CommandsPanel

# Pannello Mappa (Center Panel)
@onready var map_display: TextureRect = $MainLayout/ThreeColumnLayout/CenterPanel/MapPanel/MapVBox/MapDisplay
@onready var world_viewport: SubViewport = $MainLayout/ThreeColumnLayout/CenterPanel/MapPanel/MapVBox/WorldViewport

# ═══ VARIABILI INTERNE ═══

var world_scene_instance: Node = null
var event_popup_instance: Control = null
var is_event_popup_active: bool = false
var character_creation_popup_instance: CanvasLayer = null
var is_character_creation_popup_active: bool = false

# ═══ INIZIALIZZAZIONE PRINCIPALE ═══

func _ready():
	add_to_group("gameui")
	verify_player_manager()
	connect_player_manager_signals()
	# update_all_ui() // Spostato o gestito da segnali
	call_deferred("debug_world_viewport")
	_connect_input_manager()
	_connect_time_manager_signals()
	_initialize_event_system()
	call_deferred("_force_status_update")
	# La creazione del personaggio è ora gestita da MainGame.gd

# ═══ VERIFICA E SETUP INIZIALE ═══

# Funzione pubblica chiamata da MainGame per avviare l'istanziazione del mondo.
# Questo assicura che MainGame sia già in ascolto del segnale world_ready.
func initialize_world():
	instantiate_world_scene()

func verify_player_manager():
	if not PlayerManager:
		push_error("GameUI: PlayerManager Singleton non configurato correttamente")

func instantiate_world_scene():
	if not world_viewport:
		return
	var world_scene = preload("res://scenes/World.tscn")
	if world_scene:
		world_scene_instance = world_scene.instantiate()
		world_viewport.add_child(world_scene_instance)
		world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		print("✅ GameUI: Mondo istanziato. Emissione segnale world_ready.")
		world_ready.emit(world_scene_instance) # Notifica che il mondo è pronto
		call_deferred("connect_viewport_to_display")
	else:
		push_error("GameUI: Impossibile caricare res://scenes/World.tscn")

# ═══ CONNESSIONI SEGNALI ═══

func connect_player_manager_signals():
	if not PlayerManager:
		return
	# I segnali specifici dei pannelli (resources, stats, inventory) sono gestiti dai pannelli stessi.
	# GameUI gestisce solo segnali più ampi.
	PlayerManager.narrative_log_generated.connect(_on_narrative_log_generated)

func _connect_input_manager():
	if not InputManager:
		return
	# I segnali di inventario sono gestiti da InventoryPanel.
	InputManager.inventory_use_item.connect(_on_inventory_use_item)
	InputManager.action_cancel.connect(_on_action_cancel)
	InputManager.action_confirm.connect(_on_action_confirm)
	InputManager.level_up_request.connect(_on_level_up_request)

func _connect_time_manager_signals():
	if not TimeManager:
		return
	# Il segnale time_advanced è gestito da InfoPanel.
	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.night_started.connect(_on_night_started)
	TimeManager.day_started.connect(_on_day_started)

# ═══ CALLBACK SEGNALI ═══

func _on_narrative_log_generated(message: String):
	if log_panel and log_panel.has_method("add_log_message"):
		log_panel.add_log_message(message)

func _on_day_changed(new_day: int):
	if log_panel and log_panel.has_method("add_log_message"):
		log_panel.add_log_message("[color=yellow]🌅 Inizia il %s[/color]" % TimeManager.get_formatted_day())

func _on_night_started():
	if log_panel and log_panel.has_method("add_log_message"):
		log_panel.add_log_message("[color=#6699ff]Alla fine della giornata, fame e sete si fanno sentire.[/color]")

func _on_day_started():
	if log_panel and log_panel.has_method("add_log_message"):
		log_panel.add_log_message("[color=#ffff40]☀️ Sorge il sole. Un nuovo giorno di sopravvivenza inizia.[/color]")

func _on_inventory_use_item(slot_number: int):
	if not PlayerManager or PlayerManager.inventory.size() == 0:
		return
	var item_index = slot_number - 1
	if item_index >= 0 and item_index < PlayerManager.inventory.size():
		var selected_item = PlayerManager.inventory[item_index]
		_open_item_interaction_popup(selected_item)
	else:
		add_log_message("Hotkey [%d]: Slot vuoto" % slot_number)

func _on_action_cancel():
	if inventory_panel and inventory_panel.is_inventory_active:
		inventory_panel._on_inventory_toggle() # Chiama la funzione del pannello
	else:
		print("GameUI: ↩️ Azione cancel (nessuna azione definita)")

func _on_action_confirm():
	if inventory_panel and inventory_panel.is_inventory_active:
		_open_selected_item_popup()
	else:
		print("GameUI: ✅ Azione confirm (nessuna azione definita)")

# ═══ AGGIORNAMENTO UI - MASTER FUNCTION ═══

func update_all_ui():
	print("GameUI: 🔄 Aggiornamento completo di tutti i pannelli UI")
	if survival_panel and survival_panel.has_method("update_panel"): survival_panel.update_panel()
	if stats_panel and stats_panel.has_method("update_panel"): stats_panel.update_panel()
	if inventory_panel and inventory_panel.has_method("update_panel"): inventory_panel.update_panel()
	if equipment_panel and equipment_panel.has_method("update_panel"): equipment_panel.update_panel()
	if info_panel and info_panel.has_method("update_panel"): info_panel.update_panel()
	if commands_panel and commands_panel.has_method("update_panel"):
		var is_inventory_active = inventory_panel.is_inventory_active if inventory_panel else false
		commands_panel.update_panel(is_inventory_active)
	print("GameUI: ✅ Aggiornamento completo UI terminato")

# ═══ API PUBBLICHE PER PANNELLI ═══

func add_log_message(message: String):
	if log_panel and log_panel.has_method("add_log_message"):
		log_panel.add_log_message(message)

func _on_player_moved(new_position: Vector2i, terrain_type: String):
	if info_panel and info_panel.has_method("update_position"):
		info_panel.update_position(new_position, terrain_type)

# ═══ GESTIONE POPUP ═══

func _open_selected_item_popup():
	if not inventory_panel or not inventory_panel.is_inventory_active:
		return
	var selected_item = PlayerManager.inventory[inventory_panel.selected_inventory_index]
	_open_item_interaction_popup(selected_item)

func _open_item_interaction_popup(item: Dictionary):
	if not item or not item.has("id"): return
	var popup = ItemInteractionPopup.instantiate()
	add_child(popup)
	popup.popup_closed.connect(_on_item_popup_closed.bind(popup))
	popup.show_item_details(item)

func _on_item_popup_closed(popup_instance):
	if popup_instance and is_instance_valid(popup_instance):
		popup_instance.queue_free()

func _on_level_up_request():
	if not PlayerManager: return
	_open_level_up_popup()

func _open_level_up_popup():
	var popup = LevelUpPopup.instantiate()
	add_child(popup)
	popup.popup_closed.connect(_on_level_up_popup_closed.bind(popup))
	popup.show_level_up_popup()

func _on_level_up_popup_closed(popup_instance):
	if popup_instance and is_instance_valid(popup_instance):
		popup_instance.queue_free()

func show_character_creation_popup(char_data: Dictionary):
	if is_character_creation_popup_active: return
	character_creation_popup_instance = CharacterCreationPopup.instantiate()
	add_child(character_creation_popup_instance)
	character_creation_popup_instance.popup_closed.connect(_on_character_creation_popup_closed)
	character_creation_popup_instance.character_accepted.connect(_on_character_accepted)
	character_creation_popup_instance.show_character_creation(char_data)
	is_character_creation_popup_active = true

func _on_character_creation_popup_closed():
	if character_creation_popup_instance and is_instance_valid(character_creation_popup_instance):
		character_creation_popup_instance.queue_free()
		character_creation_popup_instance = null
	is_character_creation_popup_active = false

func _on_character_accepted():
	if PlayerManager:
		PlayerManager.finalize_character_creation()
		PlayerManager._add_starting_items()
		update_all_ui()

# ═══ SISTEMA EVENTI UI (FASE 4) ═══

func _initialize_event_system():
	if EventManager:
		EventManager.event_triggered.connect(_on_event_triggered)
		EventManager.event_choice_resolved.connect(_on_event_choice_resolved)

func _on_event_triggered(event_data: Dictionary):
	if is_event_popup_active: return
	if not event_popup_instance:
		_create_event_popup()
	if event_popup_instance:
		event_popup_instance.show_event(event_data)
		is_event_popup_active = true

func _on_event_choice_resolved(_result_text: String, narrative_log: String, skill_check_details: Dictionary):
	add_log_message(narrative_log)
	if not skill_check_details.is_empty():
		var stat_name = skill_check_details.get("stat_used", "sconosciuta").capitalize()
		var roll = skill_check_details.get("roll", 0)
		var modifier = skill_check_details.get("modifier", 0)
		var total = skill_check_details.get("total", 0)
		var difficulty = skill_check_details.get("difficulty", 0)
		var success = skill_check_details.get("success", false)
		var success_str = "[color=green]SUCCESSO[/color]" if success else "[color=red]FALLIMENTO[/color]"
		var modifier_str = "+%d" % modifier if modifier >= 0 else str(modifier)
		var details_log = "Test di %s: %d (%s) = %d vs %d - %s" % [stat_name, roll, modifier_str, total, difficulty, success_str]
		add_log_message("[color=gray]%s[/color]" % details_log)
	update_all_ui()

func _create_event_popup():
	event_popup_instance = EventPopupScene.instantiate()
	add_child(event_popup_instance)
	event_popup_instance.choice_selected.connect(_on_popup_choice_selected)
	event_popup_instance.popup_closed.connect(_on_popup_closed)

func _on_popup_choice_selected(choice_index: int):
	if EventManager and EventManager.current_event_id != "":
		EventManager.process_event_choice(EventManager.current_event_id, int(choice_index))

func _on_popup_closed():
	is_event_popup_active = false

func is_event_system_active() -> bool:
	return is_event_popup_active

# ═══ UTILITY ═══

func connect_viewport_to_display():
	if world_viewport and map_display:
		map_display.texture = world_viewport.get_texture()

func debug_world_viewport():
	# Funzione di debug per il viewport
	pass

func _force_status_update():
	# Funzione per forzare l'aggiornamento dello status
	pass
