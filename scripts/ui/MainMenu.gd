extends Control

## MainMenu - Menu principale del gioco The Safe Place
##
## Gestisce la navigazione del menu principale con supporto keyboard e mouse
## Fornisce accesso a Nuovo Gioco, Carica Gioco, Esci

# ========================================
# RIFERIMENTI NODI
# ========================================

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# ========================================
# VARIABILI STATO
# ========================================

var selected_index: int = 0
var menu_options = ["new_game", "load_game", "quit"]

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready():
	print("🎮 MainMenu: Inizializzazione menu principale...")
	setup_button_focus()
	setup_input_handling()
	update_button_selection()
	print("✅ MainMenu: Menu principale pronto")

## Configura il focus iniziale dei pulsanti
func setup_button_focus():
	new_game_button.grab_focus()
	selected_index = 0

## Configura la gestione input per navigazione keyboard
func setup_input_handling():
	# Rimuovi input handling precedente se presente
	set_process_input(true)

# ========================================
# GESTIONE INPUT
# ========================================

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_N:
				_on_new_game_pressed()
			KEY_C:
				_on_load_game_pressed()
			KEY_ESCAPE:
				_on_quit_pressed()
			KEY_UP:
				navigate_menu(-1)
			KEY_DOWN:
				navigate_menu(1)
			KEY_ENTER, KEY_SPACE:
				activate_selected_option()

## Naviga il menu su/giù
func navigate_menu(direction: int):
	selected_index = clamp(selected_index + direction, 0, menu_options.size() - 1)
	update_button_selection()

## Attiva l'opzione selezionata
func activate_selected_option():
	match selected_index:
		0:
			_on_new_game_pressed()
		1:
			_on_load_game_pressed()
		2:
			_on_quit_pressed()

## Aggiorna la selezione visuale dei pulsanti
func update_button_selection():
	# Rimuovi selezione precedente
	new_game_button.remove_theme_color_override("font_color")
	load_game_button.remove_theme_color_override("font_color")
	quit_button.remove_theme_color_override("font_color")

	# Applica selezione corrente
	var selected_color = Color(1, 1, 0)  # Giallo per selezione
	match selected_index:
		0:
			new_game_button.add_theme_color_override("font_color", selected_color)
			new_game_button.grab_focus()
		1:
			load_game_button.add_theme_color_override("font_color", selected_color)
			load_game_button.grab_focus()
		2:
			quit_button.add_theme_color_override("font_color", selected_color)
			quit_button.grab_focus()

# ========================================
# AZIONI MENU
# ========================================

## Avvia un nuovo gioco
func _on_new_game_pressed():
	print("🎮 MainMenu: Avvio nuovo gioco...")
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")

## Carica un salvataggio esistente
func _on_load_game_pressed():
	print("🎮 MainMenu: Caricamento gioco...")
	# Per ora, avvia semplicemente il gioco (implementazione futura del load)
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")

## Esce dal gioco
func _on_quit_pressed():
	print("🎮 MainMenu: Uscita dal gioco...")
	get_tree().quit()

# ========================================
# UTILITY
# ========================================

## Ottiene informazioni sui salvataggi disponibili
func get_available_saves() -> Array:
	if SaveLoadManager:
		return SaveLoadManager.available_saves
	return []

## Verifica se ci sono salvataggi disponibili
func has_saves_available() -> bool:
	return get_available_saves().size() > 0