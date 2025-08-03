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

func _ready():
	print("[EventPopup] Inizializzazione EventPopup...")
	
	# Nascondi popup all'avvio
	visible = false
	is_popup_active = false
	
	# Connetti segnale chiusura
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	print("[EventPopup] EventPopup inizializzato con successo")

# Mostra popup con dati evento
func show_event(event_data: Dictionary):
	print("[EventPopup] Mostrando evento: ", event_data.get("id", "unknown"))
	
	current_event_data = event_data
	is_popup_active = true
	
	# Aggiorna contenuto popup
	_update_popup_content()
	
	# Mostra popup con animazione
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

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

# Aggiunge un bottone scelta
func _add_choice_button(choice_data: Dictionary, choice_index: int):
	if not choices_container:
		return
	
	var choice_button = Button.new()
	choice_button.text = choice_data.get("text", "Scelta sconosciuta")
	choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Aggiungi info skill check se presente
	var skill_check = choice_data.get("skillCheck")
	if skill_check:
		var stat_name = skill_check.get("stat", "unknown")
		var difficulty = skill_check.get("difficulty", 0)
		choice_button.text += " [" + stat_name.capitalize() + " DC" + str(difficulty) + "]"
	
	# Connetti segnale
	choice_button.pressed.connect(_on_choice_selected.bind(choice_index))
	
	# Aggiungi al container
	choices_container.add_child(choice_button)

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
	print("[EventPopup] Scelta selezionata: ", choice_index)
	
	# Emetti segnale
	choice_selected.emit(choice_index)
	
	# Chiudi popup
	_close_popup()

# Gestisce pressione bottone chiusura
func _on_close_button_pressed():
	print("[EventPopup] Popup chiuso dall'utente")
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

# Gestisce input ESC per chiudere
func _input(event):
	if not is_popup_active:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_close_popup()
			get_viewport().set_input_as_handled()