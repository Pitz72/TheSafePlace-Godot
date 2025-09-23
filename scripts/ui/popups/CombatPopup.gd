# CombatPopup.gd
# Sistema popup per la gestione dei combattimenti
# Interfaccia keyboard-only ispirata ai terminali anni 80

extends Control

# Segnali per comunicazione con GameUI
signal popup_closed()

# Riferimenti UI
@onready var background_panel: Panel = $BackgroundPanel
@onready var enemy_name_label: Label = $BackgroundPanel/VBoxContainer/EnemyInfo/EnemyName
@onready var enemy_hp_label: Label = $BackgroundPanel/VBoxContainer/EnemyInfo/EnemyHP
@onready var enemy_stats_label: Label = $BackgroundPanel/VBoxContainer/EnemyInfo/EnemyStats
@onready var actions_container: VBoxContainer = $BackgroundPanel/VBoxContainer/ActionsContainer
@onready var combat_log: RichTextLabel = $BackgroundPanel/VBoxContainer/CombatLog
@onready var turn_indicator: Label = $BackgroundPanel/VBoxContainer/TurnIndicator

# Stato popup
var is_popup_active: bool = false
var action_buttons: Array[Button] = []
var selected_action_index: int = 0
var current_enemy_data: Dictionary = {}
var available_actions: Array[CombatManager.CombatAction] = []

func _ready():
	# Nascondi popup all'avvio
	visible = false
	is_popup_active = false

	# Connetti segnali CombatManager
	CombatManager.combat_started.connect(_on_combat_started)
	CombatManager.combat_ended.connect(_on_combat_ended)
	CombatManager.turn_changed.connect(_on_turn_changed)
	CombatManager.combat_log_updated.connect(_on_combat_log_updated)
	CombatManager.damage_dealt.connect(_on_damage_dealt)

# Mostra popup combattimento
func show_combat_popup(enemy_data: Dictionary):
	current_enemy_data = enemy_data
	is_popup_active = true
	selected_action_index = 0

	# Aggiorna contenuto
	_update_enemy_info()
	_update_available_actions()
	_update_turn_indicator()

	# Mostra popup con animazione
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# Inizializza selezione
	_update_action_selection()

# Aggiorna informazioni nemico
func _update_enemy_info():
	if enemy_name_label:
		enemy_name_label.text = current_enemy_data.get("name", "Nemico Sconosciuto")

	if enemy_hp_label:
		# Ottieni HP aggiornato direttamente dal CombatManager
		var combat_state = CombatManager.get_combat_state()
		var enemy_data = combat_state.get("enemy", {})
		var current_hp = enemy_data.get("hp", 0)
		var max_hp = enemy_data.get("max_hp", 0)

		# Colora HP in rosso se critico
		if current_hp <= max_hp * 0.25:
			enemy_hp_label.text = "[color=red]HP: %d/%d (CRITICO!)[/color]" % [current_hp, max_hp]
		elif current_hp <= max_hp * 0.5:
			enemy_hp_label.text = "[color=orange]HP: %d/%d (Ferito)[/color]" % [current_hp, max_hp]
		else:
			enemy_hp_label.text = "HP: %d/%d" % [current_hp, max_hp]

		# Aggiorna statistiche nemico
		if enemy_stats_label:
			var damage = enemy_data.get("damage", 0)
			var defense = enemy_data.get("defense", 0)
			var accuracy = enemy_data.get("accuracy", 0)
			enemy_stats_label.text = "⚔️ DMG: %d | 🛡️ DEF: %d | 🎯 ACC: %d" % [damage, defense, accuracy]

# Aggiorna azioni disponibili
func _update_available_actions():
	# Pulisci azioni precedenti
	_clear_actions()

	# Ottieni azioni disponibili dal CombatManager
	available_actions = CombatManager.get_available_actions()

	# Crea bottoni per ogni azione
	for i in range(available_actions.size()):
		var action = available_actions[i]
		_add_action_button(action, i)

# Pulisce le azioni precedenti
func _clear_actions():
	if not actions_container:
		return

	for child in actions_container.get_children():
		child.queue_free()

	action_buttons.clear()
	selected_action_index = 0

# Aggiunge un bottone azione
func _add_action_button(action: CombatManager.CombatAction, action_index: int):
	if not actions_container:
		return

	var action_button = Button.new()
	action_button.text = _get_action_text(action)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.custom_minimum_size.y = 35
	action_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Connetti segnale
	action_button.pressed.connect(_on_action_selected.bind(action_index))

	# Aggiungi al container e all'array
	actions_container.add_child(action_button)
	action_buttons.append(action_button)

# Ottiene il testo per un'azione
func _get_action_text(action: CombatManager.CombatAction) -> String:
	match action:
		CombatManager.CombatAction.ATTACK:
			return "⚔️  Attacca"
		CombatManager.CombatAction.DEFEND:
			return "🛡️  Difendi"
		CombatManager.CombatAction.USE_ITEM:
			return "🎒 Usa Oggetto"
		CombatManager.CombatAction.FLEE:
			return "🏃 Fuggi"
		CombatManager.CombatAction.SPECIAL:
			return "✨ Azione Speciale"
		_:
			return "Azione Sconosciuta"

# Aggiorna indicatore turno
func _update_turn_indicator():
	if not turn_indicator:
		return

	var combat_state = CombatManager.get_combat_state()
	var is_player_turn = combat_state.get("is_player_turn", true)
	var enemy_data = combat_state.get("enemy", {})
	var enemy_hp = enemy_data.get("hp", 0)

	# Se nemico sconfitto, mostra vittoria
	if enemy_hp <= 0:
		turn_indicator.text = "🎉 NEMICO SCONFITTO!"
		turn_indicator.modulate = Color(0.2, 0.8, 0.2)  # Verde brillante
	elif is_player_turn:
		turn_indicator.text = "🔴 TURNO GIOCATORE"
		turn_indicator.modulate = Color(0.2, 0.8, 0.2)  # Verde
	else:
		turn_indicator.text = "🔵 TURNO NEMICO"
		turn_indicator.modulate = Color(0.8, 0.2, 0.2)  # Rosso

# Gestisce selezione azione
func _on_action_selected(action_index: int):
	if action_index >= available_actions.size():
		return

	var selected_action = available_actions[action_index]

	# Per USE_ITEM, potrebbe servire selezione oggetto
	if selected_action == CombatManager.CombatAction.USE_ITEM:
		_show_item_selection()
	else:
		# Esegui azione direttamente
		_execute_action(selected_action)

# Mostra selezione oggetto per USE_ITEM
func _show_item_selection():
	# Per ora, semplificato - usa primo consumabile disponibile
	var player_inventory = PlayerManager.inventory
	for item in player_inventory:
		var item_data = DataManager.get_item_data(item.id)
		if item_data.get("category") == "CONSUMABLE":
			_execute_action(CombatManager.CombatAction.USE_ITEM, item.id)
			return

	# Nessun consumabile disponibile
	CombatManager._log_combat_event("Nessun oggetto utilizzabile disponibile!")

# Esegue un'azione
func _execute_action(action: CombatManager.CombatAction, target: String = ""):
	var success = CombatManager.perform_player_action(action, target)

	if not success:
		# Azione fallita, potrebbe essere necessario feedback
		pass

# Chiude il popup
func _close_popup():
	if not is_popup_active:
		return

	is_popup_active = false

	# Animazione chiusura
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_hide_popup)

# Nasconde il popup
func _hide_popup():
	visible = false
	current_enemy_data.clear()
	popup_closed.emit()

# Verifica se popup è attivo
func is_active() -> bool:
	return is_popup_active

# ====================
# GESTIONE SEGNALI COMBATMANAGER
# ====================

func _on_combat_started(enemy_data: Dictionary):
	show_combat_popup(enemy_data)

func _on_combat_ended(_result: CombatManager.CombatResult, _rewards: Dictionary):
	# Aggiorna UI finale se necessario
	_update_enemy_info()

	# Chiudi popup dopo un delay per mostrare il risultato
	await get_tree().create_timer(2.0).timeout
	_close_popup()

func _on_turn_changed(new_state: CombatManager.CombatState):
	_update_turn_indicator()

	# Aggiorna azioni disponibili quando cambia turno
	if new_state == CombatManager.CombatState.PLAYER_TURN:
		_update_available_actions()
		_update_action_selection()

func _on_combat_log_updated(message: String):
	if combat_log:
		combat_log.append_text("\n" + message)
		# Scroll automatico alla fine
		combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func _on_damage_dealt(_target: String, _amount: int, _is_critical: bool):
	# Aggiorna HP display quando c'è danno
	if _target == "enemy":
		_update_enemy_info()

# ====================
# NAVIGAZIONE KEYBOARD-ONLY
# ====================

func _input(event):
	if not is_popup_active or not event.is_pressed():
		return

	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				# ESC chiude solo se non in combattimento attivo
				if CombatManager.current_combat_state == CombatManager.CombatState.IDLE:
					_close_popup()
				get_viewport().set_input_as_handled()

			KEY_UP, KEY_W:
				_navigate_action(-1)
				get_viewport().set_input_as_handled()

			KEY_DOWN, KEY_S:
				_navigate_action(1)
				get_viewport().set_input_as_handled()

			KEY_ENTER, KEY_SPACE:
				_activate_selected_action()
				get_viewport().set_input_as_handled()

			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var action_num = event.keycode - KEY_1
				if action_num < action_buttons.size():
					_on_action_selected(action_num)
				get_viewport().set_input_as_handled()

# Naviga tra le azioni
func _navigate_action(direction: int):
	if action_buttons.is_empty():
		return

	selected_action_index += direction

	# Wrap around
	if selected_action_index < 0:
		selected_action_index = action_buttons.size() - 1
	elif selected_action_index >= action_buttons.size():
		selected_action_index = 0

	_update_action_selection()

# Aggiorna la selezione visiva
func _update_action_selection():
	for i in range(action_buttons.size()):
		var button = action_buttons[i]
		if i == selected_action_index:
			button.modulate = Color(1.2, 1.2, 1.0)  # Evidenzia selezione
			button.grab_focus()
		else:
			button.modulate = Color.WHITE

# Attiva l'azione selezionata
func _activate_selected_action():
	if selected_action_index < action_buttons.size():
		_on_action_selected(selected_action_index)