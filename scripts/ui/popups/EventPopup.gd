# EventPopup.gd
# Sistema popup per la gestione degli eventi del gioco
# Gestisce visualizzazione eventi, scelte multiple e skill check

extends Control
class_name EventPopup

# Segnali per comunicazione con EventManager
signal choice_selected(choice_index: int)
signal popup_closed()

# Riferimenti UI
@onready var background_panel: Panel = $BackgroundPanel
@onready var event_title: Label = $BackgroundPanel/VBoxContainer/EventTitle
@onready var event_description: RichTextLabel = $BackgroundPanel/VBoxContainer/EventDescription
@onready var choices_container: VBoxContainer = $BackgroundPanel/VBoxContainer/ChoicesContainer
@onready var skill_check_info: Label = $BackgroundPanel/VBoxContainer/SkillCheckInfo
@onready var close_button: Button = $BackgroundPanel/VBoxContainer/CloseButton

# Stato popup
var current_event_data: Dictionary = {}
var is_popup_active: bool = false
var choice_buttons: Array[Button] = []
var selected_choice_index: int = 0

func _ready():
	# Debug rimosso per ridurre log
	pass
	
	# Nascondi popup all'avvio
	visible = false
	is_popup_active = false
	
	# Connetti segnale chiusura
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Debug rimosso per ridurre log
	pass

# Mostra popup con dati evento
func show_event(event_data: Dictionary):
	# Debug rimosso per ridurre log
	pass
	
	current_event_data = event_data
	is_popup_active = true
	selected_choice_index = 0
	
	# Aggiorna contenuto popup
	_update_popup_content()
	
	# Mostra popup con animazione
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Imposta focus sulla prima scelta
	_update_choice_selection()

# Aggiorna contenuto del popup
func _update_popup_content():
	if not current_event_data:
		return
	
	# Titolo evento
	if event_title:
		event_title.text = current_event_data.get("title", "Evento Sconosciuto")
	
	# Descrizione evento
	if event_description:
		event_description.text = current_event_data.get("description", "Nessuna descrizione disponibile.")
	
	# Pulisci scelte precedenti
	_clear_choices()
	
	# Aggiungi nuove scelte
	var choices = current_event_data.get("choices", [])
	for i in range(choices.size()):
		_add_choice_button(choices[i], i)
	
	# Mostra info skill check se presente
	_update_skill_check_info()

# Pulisce le scelte precedenti
func _clear_choices():
	if not choices_container:
		return
		
	for child in choices_container.get_children():
		child.queue_free()
	
	choice_buttons.clear()
	selected_choice_index = 0

# Aggiunge un bottone scelta
func _add_choice_button(choice_data: Dictionary, choice_index: int):
	if not choices_container:
		return
	
	var choice_button = Button.new()
	choice_button.text = choice_data.get("text", "Scelta sconosciuta")
	choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_button.custom_minimum_size.y = 40
	choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Aggiungi info skill check se presente
	var skill_check = choice_data.get("skillCheck")
	if skill_check:
		var stat_name = skill_check.get("stat", "unknown")
		var difficulty = skill_check.get("difficulty", 0)
		choice_button.text += "\n[" + stat_name.capitalize() + " DC" + str(difficulty) + "]"
	
	# Connetti segnale
	choice_button.pressed.connect(_on_choice_selected.bind(choice_index))
	
	# Aggiungi al container e all'array
	choices_container.add_child(choice_button)
	choice_buttons.append(choice_button)

# Aggiorna informazioni skill check
func _update_skill_check_info():
	if not skill_check_info:
		return
	
	var has_skill_checks = false
	var choices = current_event_data.get("choices", [])
	
	for choice in choices:
		if choice.has("skillCheck"):
			has_skill_checks = true
			break
	
	if has_skill_checks:
		skill_check_info.text = "💡 Alcune scelte richiedono test di abilità. Il successo dipende dalle tue statistiche!"
		skill_check_info.visible = true
	else:
		skill_check_info.visible = false

# Gestisce selezione scelta
func _on_choice_selected(choice_index: int):
	# Debug rimosso per ridurre log
	pass
	
	# Emetti segnale
	choice_selected.emit(choice_index)
	
	# Chiudi popup
	_close_popup()

# Gestisce pressione bottone chiusura
func _on_close_button_pressed():
	# Debug rimosso per ridurre log
	pass
	_close_popup()

# Chiude il popup con animazione
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
	current_event_data.clear()
	popup_closed.emit()

# Verifica se popup è attivo
func is_active() -> bool:
	return is_popup_active

# Gestisce input da tastiera
func _input(event):
	if not is_popup_active or not event.is_pressed():
		return
		
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				_close_popup()
				get_viewport().set_input_as_handled()
			KEY_UP, KEY_W:
				_navigate_choice(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN, KEY_S:
				_navigate_choice(1)
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_SPACE:
				_activate_selected_choice()
				get_viewport().set_input_as_handled()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var choice_num = event.keycode - KEY_1
				if choice_num < choice_buttons.size():
					_on_choice_selected(choice_num)
				get_viewport().set_input_as_handled()

# Naviga tra le scelte
func _navigate_choice(direction: int):
	if choice_buttons.is_empty():
		return
	
	selected_choice_index += direction
	
	# Wrap around
	if selected_choice_index < 0:
		selected_choice_index = choice_buttons.size() - 1
	elif selected_choice_index >= choice_buttons.size():
		selected_choice_index = 0
	
	_update_choice_selection()

# Aggiorna la selezione visiva
func _update_choice_selection():
	for i in range(choice_buttons.size()):
		var button = choice_buttons[i]
		if i == selected_choice_index:
			button.modulate = Color(1.2, 1.2, 1.0)  # Evidenzia
			button.grab_focus()
		else:
			button.modulate = Color.WHITE

# Attiva la scelta selezionata
func _activate_selected_choice():
	if selected_choice_index < choice_buttons.size():
		_on_choice_selected(selected_choice_index)