extends Control
class_name RestNightPopup

## RestNightPopup - Sistema popup per rifugio notturno
## Permette al giocatore di scegliere cosa consumare prima di riposare
## Gestisce automaticamente l'avanzamento del tempo fino alle 6:00 AM

# Segnali
signal popup_closed()

# Riferimenti UI
@onready var background_panel: Panel = $BackgroundPanel
@onready var shelter_title: Label = $BackgroundPanel/VBoxContainer/ShelterTitle
@onready var shelter_description: RichTextLabel = $BackgroundPanel/VBoxContainer/ShelterDescription
@onready var choices_container: VBoxContainer = $BackgroundPanel/VBoxContainer/ChoicesContainer
@onready var info_label: Label = $BackgroundPanel/VBoxContainer/InfoLabel

@onready var choice1_button: Button = $BackgroundPanel/VBoxContainer/ChoicesContainer/Choice1
@onready var choice2_button: Button = $BackgroundPanel/VBoxContainer/ChoicesContainer/Choice2
@onready var choice3_button: Button = $BackgroundPanel/VBoxContainer/ChoicesContainer/Choice3
@onready var choice4_button: Button = $BackgroundPanel/VBoxContainer/ChoicesContainer/Choice4

# Stato popup
var is_popup_active: bool = false
var selected_choice_index: int = 0
var choice_buttons: Array[Button] = []

func _ready():
	print("🌙 RestNightPopup: Inizializzazione...")
	
	# Nascondi popup all'avvio
	visible = false
	is_popup_active = false
	
	# Popola array bottoni per navigazione
	choice_buttons = [choice1_button, choice2_button, choice3_button, choice4_button]
	
	# Connetti segnali bottoni
	for i in range(choice_buttons.size()):
		if choice_buttons[i]:
			choice_buttons[i].pressed.connect(_on_choice_selected.bind(i + 1))
	
	print("✅ RestNightPopup: Pronto")

# Mostra il popup rifugio notturno
func show_night_shelter():
	print("🌙 Mostrando popup rifugio notturno")
	
	is_popup_active = true
	selected_choice_index = 0
	
	# Aggiorna contenuto dinamico se necessario
	_update_popup_content()
	
	# Mostra popup con animazione
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Imposta focus sulla prima scelta
	_update_choice_selection()

# Aggiorna contenuto del popup (dinamico se necessario)
func _update_popup_content():
	# Per ora il contenuto è statico, ma potremmo aggiungere
	# informazioni dinamiche sui consumi disponibili
	pass

# Aggiorna selezione visuale
func _update_choice_selection():
	for i in range(choice_buttons.size()):
		if choice_buttons[i]:
			if i == selected_choice_index:
				choice_buttons[i].grab_focus()
				choice_buttons[i].modulate = Color(1.2, 1.2, 1.0)  # Evidenziato
			else:
				choice_buttons[i].modulate = Color.WHITE  # Normale

# Gestisce selezione di una scelta
func _on_choice_selected(choice_index: int):
	print("🌙 Scelta rifugio selezionata: %d" % choice_index)
	
	match choice_index:
		1:  # Mangia e Bevi
			_consume_food_and_water()
		2:  # Solo Mangia
			_consume_food_only()
		3:  # Solo Bevi
			_consume_water_only()
		4:  # Non consumare nulla
			_consume_nothing()
	
	# Dopo qualsiasi scelta, fai passare la notte
	_advance_to_morning()
	
	# Chiudi popup
	_close_popup()

# Consuma cibo e acqua
func _consume_food_and_water():
	print("🍽️ Consumando cibo e acqua...")
	
	# Tenta di consumare oggetti dall'inventario e ripristinare risorse
	var food_consumed = _consume_food_items()
	var water_consumed = _consume_water_items()
	
	if food_consumed and water_consumed:
		PlayerManager.narrative_log_generated.emit("[color=#00ff00]Consumi una razione di cibo e bevi acqua. Ti senti sazio e idratato.[/color]")
	elif food_consumed:
		PlayerManager.narrative_log_generated.emit("[color=#ffaa00]Consumi una razione di cibo ma non hai acqua. Hai ancora sete.[/color]")
	elif water_consumed:
		PlayerManager.narrative_log_generated.emit("[color=#ffaa00]Bevi acqua ma non hai cibo. Hai ancora fame.[/color]")
	else:
		PlayerManager.narrative_log_generated.emit("[color=#ff6666]Non hai né cibo né acqua. Vai a dormire affamato e assetato.[/color]")

# Consuma solo cibo
func _consume_food_only():
	print("🍞 Consumando solo cibo...")
	
	if _consume_food_items():
		PlayerManager.narrative_log_generated.emit("[color=#00ff00]Consumi una razione di cibo. La fame è placata.[/color]")
	else:
		PlayerManager.narrative_log_generated.emit("[color=#ff6666]Non hai cibo disponibile. Vai a dormire affamato.[/color]")

# Consuma solo acqua
func _consume_water_only():
	print("💧 Consumando solo acqua...")
	
	if _consume_water_items():
		PlayerManager.narrative_log_generated.emit("[color=#00ff00]Bevi acqua fresca. La sete è placata.[/color]")
	else:
		PlayerManager.narrative_log_generated.emit("[color=#ff6666]Non hai acqua disponibile. Vai a dormire assetato.[/color]")

# Tenta di consumare oggetti di cibo dall'inventario
# @return: bool true se ha consumato con successo
func _consume_food_items() -> bool:
	# Lista degli ID di oggetti considerati "cibo"
	var food_items = ["ration_pack", "MRE_pack_military", "preserved_food"]
	
	for food_id in food_items:
		if PlayerManager.has_item(food_id):
			# Usa l'oggetto (questo applica gli effetti automaticamente)
			if PlayerManager.use_item(food_id, 1):
				print("🍽️ Consumato: %s" % food_id)
				return true
	
	# Se non ha oggetti di cibo, ma ha ancora food stat > 0, non consumare nulla
	# (il giocatore può scegliere di non consumare le sue riserve)
	print("⚠️ Nessun oggetto di cibo trovato nell'inventario")
	return false

# Tenta di consumare oggetti di acqua dall'inventario
# @return: bool true se ha consumato con successo
func _consume_water_items() -> bool:
	# Lista degli ID di oggetti considerati "acqua"
	var water_items = ["water_purified", "purified_water_bottle_large", "water_bottle"]
	
	for water_id in water_items:
		if PlayerManager.has_item(water_id):
			# Usa l'oggetto (questo applica gli effetti automaticamente)
			if PlayerManager.use_item(water_id, 1):
				print("💧 Consumato: %s" % water_id)
				return true
	
	# Se non ha oggetti di acqua, ma ha ancora water stat > 0, non consumare nulla
	print("⚠️ Nessun oggetto di acqua trovato nell'inventario")
	return false

# Non consuma nulla
func _consume_nothing():
	print("😴 Non consumando nulla...")
	PlayerManager.narrative_log_generated.emit("[color=#888888]Decidi di conservare le tue provviste e vai direttamente a dormire.[/color]")

# Avanza il tempo fino al mattino (6:00 AM)
func _advance_to_morning():
	print("🌅 Avanzando tempo fino al mattino...")
	
	PlayerManager.narrative_log_generated.emit("[color=#4444ff]Ti sistemi per la notte nel rifugio. Le pareti ti proteggono dai pericoli esterni.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=#888888]Dormi profondamente fino all'alba...[/color]")
	
	# Avanza tempo fino alle 6:00
	TimeManager.advance_time_until_hour(6)
	
	PlayerManager.narrative_log_generated.emit("[color=#ffdd00]Ti svegli riposato. È mattina e puoi continuare il viaggio.[/color]")

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
				# ESC: chiudi senza consumare (equivale a scelta 4)
				_on_choice_selected(4)
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
			KEY_1:
				_on_choice_selected(1)
				get_viewport().set_input_as_handled()
			KEY_2:
				_on_choice_selected(2)
				get_viewport().set_input_as_handled()
			KEY_3:
				_on_choice_selected(3)
				get_viewport().set_input_as_handled()
			KEY_4:
				_on_choice_selected(4)
				get_viewport().set_input_as_handled()

# Naviga tra le scelte con tasti freccia
func _navigate_choice(delta: int):
	selected_choice_index = (selected_choice_index + delta) % choice_buttons.size()
	if selected_choice_index < 0:
		selected_choice_index = choice_buttons.size() - 1
	
	_update_choice_selection()

# Attiva la scelta selezionata
func _activate_selected_choice():
	_on_choice_selected(selected_choice_index + 1)