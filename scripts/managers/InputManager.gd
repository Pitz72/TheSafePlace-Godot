extends Node

## InputManager Singleton - The Safe Place v0.1.6
## 
## Gestisce centralmente tutti gli input del gioco con sistema di stati.
## Architettura: Stato corrente determina quali segnali emettere per input ricevuti.
## 
## Stati supportati: MAP (movimento mondo), INVENTORY (navigazione inventario), 
## DIALOGUE (dialoghi NPC), COMBAT (sistema combattimento)
## 
## Progettato come Singleton (Autoload) per gestione input globale unificata.

# ========================================
# ENUM STATI INPUT
# ========================================

## Stati possibili del sistema di input
enum InputState {
	MAP,        # Movimento sulla mappa mondiale
	INVENTORY,  # Navigazione inventario attiva
	DIALOGUE,   # Sistema dialoghi con NPC
	COMBAT,     # Sistema combattimento turn-based
	POPUP       # Popup interazione oggetti (blocca tutti input di gioco)
}

# ========================================
# SEGNALI PUBBLICI
# ========================================

## Emesso per movimento sulla mappa (WASD/Frecce)
## @param direction: Vector2i con direzione (-1,0,1 per x/y)
signal map_move(direction: Vector2i)

## Emesso per navigazione inventario (WASD/Frecce)
## @param direction: Vector2i con direzione navigazione
signal inventory_navigate(direction: Vector2i)

## Emesso per attivazione/disattivazione inventario (I)
signal inventory_toggle()

## Emesso per uso oggetto inventario (1-9)
## @param slot_number: int numero slot (1-9)
signal inventory_use_item(slot_number: int)

## Emesso per azione generica (SPACE/ENTER)
signal action_confirm()

## Emesso per cancellazione/indietro (ESC)
signal action_cancel()

## Emesso per azioni combat specifiche
## @param action: String tipo azione ("attack", "defend", "flee")
signal combat_action(action: String)

## Emesso per cambio stato input
## @param old_state: InputState stato precedente
## @param new_state: InputState nuovo stato
signal state_changed(old_state: InputState, new_state: InputState)

## Emesso per livellamento personaggio (L) - M3.T1
signal level_up_request()

## Emesso per azioni rifugio (1-4 quando in rifugio)
## @param action_index: int numero azione (1-4)
signal shelter_action_requested(action_index: int)

## Emesso per richiesta interfaccia quest
signal quest_interface_requested

## Emesso per richiesta stato emotivo
signal emotional_state_requested



# ========================================
# VARIABILI STATO
# ========================================

## Stato corrente del sistema di input
var current_state: InputState = InputState.MAP

## Flag per debug input (stampa azioni in console)
var debug_input: bool = false

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	pass
	
	# Debug disattivato - sistema funzionante
	debug_input = false
	# Debug rimosso per ridurre log
	pass
	
	# Debug rimosso per ridurre log
	pass

# ========================================
# API PUBBLICA - GESTIONE STATI
# ========================================

## Cambia lo stato corrente del sistema di input
## @param new_state: InputState nuovo stato da impostare
func set_state(new_state: InputState) -> void:
	if new_state == current_state:
		return  # Nessun cambiamento necessario
	
	var old_state = current_state
	current_state = new_state
	
	if debug_input:
		# Debug rimosso per ridurre log
		pass
	
	# Emetti segnale di cambio stato
	state_changed.emit(old_state, new_state)

## Restituisce lo stato corrente
## @return: InputState stato attuale
func get_current_state() -> InputState:
	return current_state

## Abilita/disabilita debug input
## @param enabled: bool se true stampa debug in console
func set_debug(enabled: bool) -> void:
	debug_input = enabled
	# Debug rimosso per ridurre log
	pass

# ========================================
# GESTIONE INPUT CENTRALIZZATA
# ========================================

func _input(event: InputEvent) -> void:
	# Processa solo eventi pressed (non released)
	if not event.is_pressed():
		return
	
	# Gestione input globali (sempre attivi)
	if _handle_global_input(event):
		return
	
	# Gestione input specifici per stato
	match current_state:
		InputState.MAP:
			_handle_map_input(event)
		InputState.INVENTORY:
			_handle_inventory_input(event)
		InputState.DIALOGUE:
			_handle_dialogue_input(event)
		InputState.COMBAT:
			_handle_combat_input(event)
		InputState.POPUP:
			# Stato POPUP: blocca tutti input di gioco, il popup gestisce i suoi input internamente
			pass

## Gestisce input globali (sempre attivi indipendentemente dallo stato)
## @param event: InputEvent evento da processare
## @return: bool true se evento è stato gestito
func _handle_global_input(event: InputEvent) -> bool:
	# Toggle inventario (I) - sempre disponibile
	if event.is_action_pressed("ui_inventory") or Input.is_key_pressed(KEY_I):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		inventory_toggle.emit()
		return true
	
	# Azione cancellazione (ESC) - sempre disponibile
	if event.is_action_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		action_cancel.emit()
		return true
	
	# GESTIONE HOTKEY NUMERICI 1-9: Inventario VS Azioni Rifugio
	for i in range(1, 10):
		var key_code = KEY_1 + (i - 1)  # KEY_1, KEY_2, ..., KEY_9
		if Input.is_key_pressed(key_code):
			if debug_input:
				# Debug rimosso per ridurre log
				pass
			
			# CONTROLLO MODALITÀ RIFUGIO
			var main_game = get_node("/root/MainGame")
			if main_game and main_game.has_method("get") and main_game.get("is_in_shelter") == true:
				# In rifugio: emetti azione rifugio (solo per 1-4)
				if i <= 4:
					shelter_action_requested.emit(i)
					return true
			else:
				# Modalità normale: usa oggetto inventario
				inventory_use_item.emit(i)
				return true
	
	# M3.T1: Comando livellamento personaggio (L) - SEMPRE attivo
	if Input.is_key_pressed(KEY_L):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		level_up_request.emit()
		return true

	# Comando interfaccia quest (Q) - SEMPRE attivo
	if Input.is_key_pressed(KEY_Q):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		quest_interface_requested.emit()
		return true

	# Comando stato emotivo (E) - SEMPRE attivo
	if Input.is_key_pressed(KEY_E):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		emotional_state_requested.emit()
		return true

	# M3.T3: Debug system removed - production ready

	# M3.T4.2: Gestione input di debug (F9)
	_handle_debug_input(event)

	return false

## Gestisce input specifici per stato MAP
## @param event: InputEvent evento da processare
func _handle_map_input(event: InputEvent) -> void:
	var direction = Vector2i.ZERO
	
	# Movimento WASD + Frecce
	if event.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y = -1
	elif event.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y = 1
	elif event.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x = -1
	elif event.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x = 1
	
	# Emetti segnale movimento se c'è una direzione
	if direction != Vector2i.ZERO:
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		map_move.emit(direction)
		return
	
	# Azione conferma (SPACE/ENTER)
	if event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		action_confirm.emit()

## Gestisce input specifici per stato INVENTORY
## @param event: InputEvent evento da processare
func _handle_inventory_input(event: InputEvent) -> void:
	var direction = Vector2i.ZERO
	
	# Navigazione inventario WASD + Frecce
	if event.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y = -1
	elif event.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y = 1
	elif event.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x = -1
	elif event.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x = 1
	
	# Emetti segnale navigazione se c'è una direzione
	if direction != Vector2i.ZERO:
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		inventory_navigate.emit(direction)
		return
	
	# Azione conferma (SPACE/ENTER)
	if event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		action_confirm.emit()

## Gestisce input specifici per stato DIALOGUE
## @param event: InputEvent evento da processare
func _handle_dialogue_input(event: InputEvent) -> void:
	# Per ora solo azioni di conferma/cancellazione
	# TODO: Implementare quando sistema dialoghi sarà sviluppato
	
	if event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		action_confirm.emit()

## Gestisce input specifici per stato COMBAT
## @param event: InputEvent evento da processare
func _handle_combat_input(event: InputEvent) -> void:
	# Azioni combattimento base
	# TODO: Espandere quando sistema combattimento sarà implementato
	
	# A = Attack, D = Defend, F = Flee
	if Input.is_key_pressed(KEY_A):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		combat_action.emit("attack")
	elif Input.is_key_pressed(KEY_D):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		combat_action.emit("defend")
	elif Input.is_key_pressed(KEY_F):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		combat_action.emit("flee")
	elif event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		if debug_input:
			# Debug rimosso per ridurre log
			pass
		action_confirm.emit()

# ========================================
# GESTIONE INPUT DEBUG (M3.T4.2)
# ========================================

## Gestisce input specifici per il debug, come i tasti funzione.
## Viene chiamato da _handle_global_input per assicurare che sia sempre attivo.
func _handle_debug_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_f9"):
		# Esegui un test di skill check e stampa il risultato in console
		var result = SkillCheckManager.perform_check("forza", 12)
		print("--- SKILL CHECK TEST (Forza vs 12) ---")
		for key in result:
			print(key, ": ", result[key])
		print("------------------------------------")

# ========================================
# UTILITIES E DEBUG
# ========================================

## Restituisce il nome dello stato corrente come stringa
## @return: String nome stato corrente
func get_state_name() -> String:
	return InputState.keys()[current_state]

## Stampa informazioni di debug dello stato corrente
func print_debug_info() -> void:
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	pass
