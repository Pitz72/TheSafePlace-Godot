extends Control

# Segnali
signal popup_closed
signal shelter_action_requested(action_index: int)

# Riferimenti nodi
@onready var shelter_title: Label = $BackgroundPanel/VBoxContainer/ShelterTitle
@onready var shelter_description: RichTextLabel = $BackgroundPanel/VBoxContainer/ShelterDescription
@onready var action1_button: Button = $BackgroundPanel/VBoxContainer/ActionsContainer/Action1
@onready var action2_button: Button = $BackgroundPanel/VBoxContainer/ActionsContainer/Action2
@onready var action3_button: Button = $BackgroundPanel/VBoxContainer/ActionsContainer/Action3
@onready var action4_button: Button = $BackgroundPanel/VBoxContainer/ActionsContainer/Action4

# Stato
var is_day_popup: bool = true

func _ready():
	# Connetti ai segnali di WorldSystemManager per il crafting
	if WorldSystemManager:
		if not WorldSystemManager.crafting_completed.is_connected(_on_crafting_completed):
			WorldSystemManager.crafting_completed.connect(_on_crafting_completed)
		if not WorldSystemManager.crafting_failed.is_connected(_on_crafting_failed):
			WorldSystemManager.crafting_failed.connect(_on_crafting_failed)

	# Connetti segnali dei pulsanti
	action1_button.connect("pressed", Callable(self, "_on_action_pressed").bind(1))
	action2_button.connect("pressed", Callable(self, "_on_action_pressed").bind(2))
	action3_button.connect("pressed", Callable(self, "_on_action_pressed").bind(3))
	action4_button.connect("pressed", Callable(self, "_on_action_pressed").bind(4))

	# Setup input
	set_process_input(true)

func _input(event):
	if not visible:
		return

	# Gestione input numerico per azioni rapide
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1:
				_on_action_pressed(1)
			KEY_2:
				_on_action_pressed(2)
			KEY_3:
				_on_action_pressed(3)
			KEY_4:
				_on_action_pressed(4)
			KEY_ESCAPE:
				close_popup()

func show_day_shelter():
	"""Mostra popup rifugio diurno con tutte le opzioni"""
	print("🏠 ShelterPopup.show_day_shelter() chiamato")
	is_day_popup = true
	shelter_title.text = "🏠 RIFUGIO - Azioni Disponibili"
	shelter_description.text = "Sei al sicuro in questo rifugio abbandonato. Puoi riposare, cercare risorse o utilizzare il banco da lavoro."

	# Mostra tutti i pulsanti
	action1_button.show()
	action2_button.show()
	action3_button.show()
	action4_button.show()

	# Aggiorna stato banco da lavoro
	_update_workbench_status()

	show()
	print("🏠 ShelterPopup.show() chiamato - visibile: %s" % visible)
	print("🏠 ShelterPopup posizione: %s, dimensione: %s" % [position, size])

func _update_workbench_status():
	"""Aggiorna lo stato del pulsante banco da lavoro"""
	if WorldSystemManager and WorldSystemManager.has_workbench():
		action3_button.text = "[3] Banco da Lavoro (Disponibile)"
		action3_button.disabled = false
	else:
		action3_button.text = "[3] Banco da Lavoro (Non disponibile)"
		action3_button.disabled = true

func _on_action_pressed(action_id: int):
	"""Gestisce la pressione di un pulsante azione"""
	match action_id:
		1:
			# Ripara rifugio
			if WorldSystemManager:
				WorldSystemManager.start_crafting("repair_shelter")
		2:
			# Migliora rifugio
			if WorldSystemManager:
				WorldSystemManager.start_crafting("upgrade_shelter")
		3:
			# Costruisci trappola
			if WorldSystemManager:
				WorldSystemManager.start_crafting("build_trap")
	
	hide_popup()

func close_popup():
	"""Chiude il popup"""
	hide()
	popup_closed.emit()

# Metodo per compatibilità con il sistema esistente
func show_night_shelter():
	"""Versione notturna - non dovrebbe essere chiamata secondo le nuove regole"""
	push_warning("ShelterPopup: show_night_shelter() chiamato - usa show_day_shelter() per giorno")
	show_day_shelter()
